# frozen_string_literal: true
# メール確認リンクを受け取ってから、待機タブへログイン状態を引き渡すまでを担うコントローラー。
# ユーザーはメール内リンクを新規タブで開き、
#   1. confirm_by_token でメール確認済みに切り替える
#   2. 新規タブ（＝このリクエストのセッション）でログイン成立
#   3. 待機タブに「引換券（handoff_token）」を ActionCable で通知
#      → 待機タブの Stimulus が POST /auth/handoff で自タブのログインを成立させる
# の3段階を行う。
class Users::ConfirmationsController < Devise::ConfirmationsController
  # remember_me クッキーの操作（forget_me 等）を有効化するために include
  include Devise::Controllers::Rememberable

  # GET /users/confirmation?confirmation_token=xxxx
  # メールリンクからの認証本体
  def show
    # Devise 標準のトークン検証。成功時は resource が確認済みユーザー、失敗時は errors が入る
    self.resource = resource_class.confirm_by_token(params[:confirmation_token])
    yield resource if block_given?    # Devise 内部フックとの互換のため残す

    # --- 失敗ケース ---
    return handle_confirmation_failure unless resource.errors.empty?

    # --- 成功ケース ---
    sign_in_confirmed_user
    broadcast_handoff_to_waiter

    flash[:page] = { title: "確認", message: "メールアドレスの確認が完了しました。", type: "success" }
    respond_with_navigational(resource) do
      # 303 See Other を明示し、POST 由来のリダイレクトも安定して GET 化させる
      redirect_to after_confirmation_path_for(resource_name, resource), status: :see_other
    end
  end

  protected

  # メール確認を踏んだタブの遷移先：結果通知（このタブはすぐ閉じる前提）
  def after_confirmation_path_for(_resource_name, _resource)
    page_mail_check_path
  end

  private

  # 確認失敗時の分岐処理
  # - 既に確認済み：メールリンクの二重アクセス対策。正常系と同じ画面へ導いて冪等化する
  # - それ以外（トークン不正・期限切れ）：通知画面へリダイレクト
  def handle_confirmation_failure
    # 既に確認済みのトークンで再アクセスされたケース。
    # Gmail/Outlook 等のリンク先プリフェッチやセキュリティスキャナが先にリンクを叩くと、
    # 1回目で確認が成立し、本人の2回目クリックがこの分岐に入る（confirm_by_token は
    # 該当ユーザーを見つけるが「確認済み」エラーを返すため、resource は永続化済み＆confirmed?=true）。
    # ここでエラー画面を出すと利用者には「失敗」に見えるため、正常系（show）と同じく
    # 待機タブへハンドオフを送り、確認完了画面へ導く。何度叩いても同じ結果になる（冪等）。
    if resource.confirmed? && resource.persisted?
      sign_in_confirmed_user
      broadcast_handoff_to_waiter
      flash[:page] = { title: "確認", message: "メールアドレスは既に確認済みです。", type: "success" }
      respond_with_navigational(resource) do
        redirect_to after_confirmation_path_for(resource_name, resource), status: :see_other
      end
      return
    end

    # トークンが不正・期限切れ（該当ユーザーが見つからない）の場合のみ、本当のエラーとして通知画面へ
    flash[:page] = { title: "通知", message: "リンク無効または期限切れです。", type: "alert" }
    respond_with_navigational(resource.errors, status: :unprocessable_entity) do
      redirect_to page_mail_check_path
    end
  end

  # このタブ（新規タブ）でユーザーをサインインさせる
  # 既にログイン中・非アクティブユーザーは二重ログインを避けるためスキップ
  def sign_in_confirmed_user
    return if user_signed_in? || !resource.active_for_authentication?

    sign_in(:user, resource)
    # Timeoutable が「前回アクセスが古い」と誤判定するのを本リクエストだけ回避
    request.env['devise.skip_timeout'] = true
  end

  # 待機タブに向けてハンドオフトークンを通知する
  # - subscribe 済みの待機タブがあればブロードキャストが届く
  # - subscribe 前だった（レース）場合は pending_handoff に保留保存し、
  #   次に subscribe した時に AccountConfirmationChannel 側で transmit される
  def broadcast_handoff_to_waiter
    payload = { uid: resource.id, jti: SecureRandom.hex(16), exp: 5.minutes.from_now.to_i }
    token = Rails.application.message_verifier(:confirm_handoff)
                .generate(payload, purpose: :confirm_handoff)

    # まず保留保存（両タイミングを吸収するためのバッファ）
    WaiterRegistry.set_pending_handoff(resource.id, token, ttl: 5.minutes)

    # 最新 jti が分かればそのストリームへ配信
    jti = WaiterRegistry.latest_jti_for(resource.id)
    if jti.present?
      ActionCable.server.broadcast(
        "confirmation_wait:#{jti}",
        { status: "confirmed",
          message: "メールアドレスの確認が完了しました。",
          handoff_token: token }
      )
    else
      # 稀ケース：待機タブがまだ subscribe していない。pending_handoff で吸収される想定
      Rails.logger.info "[Confirmations#show] waiter 未検出 user_id=#{resource.id}"
    end
  end
end

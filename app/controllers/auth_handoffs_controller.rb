# frozen_string_literal: true
# 「引換券」トークンを受け取り、このタブのセッションでログインさせる
# （別のタブでメールを確認したあと、待機していたタブから呼ばれる）
class AuthHandoffsController < ApplicationController
  # この endpoint は署名付き handoff_token（署名・jti リプレイ防止・exp）で本人性を担保しているため、
  # セッションの CSRF トークンには依存しない。
  # Devise は認証時に CSRF トークンを破棄する（clean_up_csrf_token_on_authentication=true）。
  # そのため別タブのメール確認でサインインが走ると、待機タブが保持する CSRF トークンが無効化され、
  # POST /auth/handoff が 422（InvalidAuthenticityToken）になり遷移が止まる。
  # ここはトークン認証なので CSRF 検証を外して回避する（偽造には正しい handoff_token が必要で再利用も不可）。
  skip_forgery_protection

  def create
    # JSON でも form-encoded でも受け取れるようにする
    token_param = params[:token].presence || params.dig(:auth_handoff, :token)
    unless token_param.present?
      render json: { ok: false, error: "missing token" }, status: :bad_request and return
    end

    data = Rails.application.message_verifier(:confirm_handoff)
                .verify(token_param, purpose: :confirm_handoff)

    # キーが文字列でもシンボルでも取り出せるようにする
    uid = data["uid"] || data[:uid]
    jti = data["jti"] || data[:jti]
    exp = data["exp"] || data[:exp]
    exp_i = exp.to_i if exp

    if uid.blank? || jti.blank? || !(exp_i && exp_i > 0)
      render json: { ok: false, error: "invalid token payload" }, status: :unauthorized and return
    end

    # 期限切れと、同じトークンの使い回し（リプレイ）を断る
    raise "expired" if Time.at(exp_i) <= Time.current

    if UsedJtiStore.used?(jti)
      render json: { ok: false, error: "replayed" }, status: :unauthorized and return
    end
    UsedJtiStore.mark!(jti, ttl: 10.minutes)

    user = User.find(uid)
    bypass_sign_in(user)          # このタブのセッションでログインする
    flash.discard(:page)  # flash[:page] を次の画面へ持ち越さない
    render json: { ok: true, user_id: user.id }
  rescue ActiveSupport::MessageVerifier::InvalidSignature, RuntimeError => e
    Rails.logger.warn "[AuthHandoffs#create] token verify failed: #{e.class}: #{e.message}"
    render json: { ok: false }, status: :unauthorized
  end

end

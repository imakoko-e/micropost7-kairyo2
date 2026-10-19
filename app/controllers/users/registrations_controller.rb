# frozen_string_literal: true
# ユーザー登録（サインアップ・確認待ち）と、アカウントの変更・削除
class Users::RegistrationsController < Devise::RegistrationsController
  # サインアップと確認待ちの画面のほかは、ログイン必須
  before_action :authenticate_user!, except: [:new, :create, :confirm_wait]

  # URL の :id が自分のときだけ、編集・更新・削除できる
  before_action :correct_user,   only: [:edit, :update, :destroy]

  # サインアップで姓・名も受け取る
  before_action :configure_sign_up_params, only: [:create]

  # ユーザー情報の変更
  # GET /resource/edit
  def edit
    super
  end

  # PUT /resource
  def update
    super
  end

  # ユーザーの登録削除
  # DELETE /resource
  def destroy
    User.find(params[:id]).destroy
    flash[:success] = "ユーザーを削除しました。"
    redirect_to root_url, status: :see_other
  end

  # 「確認待ち画面」を表示する
  # user_id は URL の :id ではなく、署名付きトークン（params[:sig]）で受け取る（id の推測で他人の画面を開かせない）
  def confirm_wait
    # 署名付きトークンを検証し、uid を取り出す
    # 期限切れ・改ざん・sig 未指定はまとめて「無効なアクセス」として弾く
    uid = verify_confirm_wait_sig(params[:sig])
    unless uid
      redirect_to root_path, alert: "リンクが無効または期限切れです。"
      return
    end

    @user = User.find_by(id: uid)

    # ユーザーが見つからない、または既に確認済みなら非公開
    # 理由：本画面は @user.email を描画するため、id を推測してのアクセスを遮断したい
    if @user.nil? || @user.confirmed?
      redirect_to root_path, alert: "無効なアクセスです。"
      return
    end

    # このタブ専用の一意な jti（JSON Web Token ID）を生成
    # 16バイトを hex 化した推測困難な文字列
    jti = SecureRandom.hex(16)

    # このユーザーの「最新 jti」として保存（30分で自然消滅）
    # Redis がなければ Rails.cache に自動フォールバックする
    WaiterRegistry.set_latest_jti_for(@user.id, jti, ttl: 30.minutes)

    # waiter_sig は「サーバが署名した待機情報」
    # クライアントから提出 → サーバで検証することで、改ざんと期限切れを同時に防ぐ
    @waiter_sig = Rails.application.message_verifier(:waiter)
                       .generate({ uid: @user.id, jti: jti, exp: 30.minutes.from_now.to_i },
                                 purpose: :waiter)
  end


  # メールアドレスの変更フォーム表示
  def edit_email
    @user = current_user
  end

  # メールアドレスの変更更新処理（current_password 必須）
  def update_email
    @user = current_user
    # Deviseの update_with_password は current_password を含むパラメータを要求
    if @user.update_with_password(email_update_params)
      # reconfirmable なので、新しいアドレスの確認が済むまで email は変わらない（unconfirmed_email に入る）
      flash[:success] = "確認のメールを新しいメールアドレスに送りました。メールのリンクを開くと、変更が完了します。"
      redirect_to profile_path
    else
      flash.now[:danger] = "更新に失敗しました。入力内容をご確認ください。"
      render :edit_email, status: :unprocessable_entity
    end
  end

  # パスワードの変更フォーム表示
  def edit_password
    @user = current_user
  end

  # パスワードの変更更新処理（current_password 必須）
  def update_password
    @user = current_user
    if @user.update_with_password(password_update_params)
      # パスワードを変えるとセッションが無効になるので、ログインし直させる（Devise の update と同じ）
      bypass_sign_in(@user)
      flash[:success] = "パスワードを更新しました。"
      redirect_to profile_path
    else
      flash.now[:danger] = "更新に失敗しました。入力内容をご確認ください。"
      render :edit_password, status: :unprocessable_entity
    end
  end

  protected

  # 正しいユーザー（URL の :id が current_user と一致するか）を確認するメソッド
  # 注意：Devise の authenticate_scope! が before_action で @user = current_user を自動設定するため、
  #      以前の `@user == current_user` 比較は常に真となり、他人の :id での destroy が通る脆弱性になっていた。
  #      そこで params[:id] と current_user.id を直接比較する形に修正している。
  def correct_user
    devise_parameter_sanitizer.permit(:account_update, keys: [:id, :name, :email])
    redirect_to(root_url) unless current_user && current_user.id.to_s == params[:id].to_s
  end

  # メールの確認がまだのアカウントで、サインアップした直後に移る先（確認待ち画面）
  # uid は URL に直接載せず、署名付きトークンにして渡す
  def after_inactive_sign_up_path_for(resource)
    sig = Rails.application.message_verifier(:confirm_wait_access)
                           .generate({ uid: resource.id, exp: 30.minutes.from_now.to_i },
                                     purpose: :confirm_wait_access)
    wait_for_confirmation_path(sig: sig)
  end

  private

  # サインアップで許可する追加属性（姓・名）
  def configure_sign_up_params
    devise_parameter_sanitizer.permit(:sign_up, keys: [:last_name, :first_name])
  end

  # メール変更で許可する属性（current_password が必須）
  def email_update_params
    params.require(:user).permit(:email, :current_password)
  end

  # パスワード変更で許可する属性（current_password が必須）
  def password_update_params
    params.require(:user).permit(:password, :password_confirmation, :current_password)
  end

  # confirm_wait 画面アクセス用の署名付きトークンを検証し、uid を返す
  # 返り値：
  #   - 成功時：uid（Integer）
  #   - sig 未指定・改ざん・期限切れ：nil
  def verify_confirm_wait_sig(sig)
    return nil if sig.blank?

    data = Rails.application.message_verifier(:confirm_wait_access)
                            .verify(sig, purpose: :confirm_wait_access)
    uid = data["uid"] || data[:uid]
    exp = (data["exp"] || data[:exp]).to_i

    # 必須値・有効期限チェック
    return nil if uid.blank? || exp <= 0 || Time.at(exp) <= Time.current

    uid
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    nil
  end

end

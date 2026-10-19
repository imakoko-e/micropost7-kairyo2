# frozen_string_literal: true

# Google ログイン（OmniAuth）から戻ってきたときの処理
class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  # google_oauth2 アクションのときだけは、CSRFチェックをスキップ
  skip_before_action :verify_authenticity_token, only: :google_oauth2

  def google_oauth2
    @user = User.from_google_omniauth(request.env['omniauth.auth'])

    if @user.persisted?
      sign_in_and_redirect @user, event: :authentication
      flash[:notice] = "Googleログインに成功しました"
    else
      # extra まで入れるとセッションのストアがあふれるおそれがあるので、外して保存する
      session["devise.google_data"] = request.env["omniauth.auth"].except(:extra)
      redirect_to new_user_registration_url, alert: "Googleログインに失敗しました"
    end
  end

  def failure
    redirect_to root_path, alert: 'Googleアカウントでの認証に失敗しました。'
  end
end

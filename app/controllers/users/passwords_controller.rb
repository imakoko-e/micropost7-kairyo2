# frozen_string_literal: true

# パスワードの再設定。メールを送った後の行き先だけを変える
class Users::PasswordsController < Devise::PasswordsController

  protected

  # 再設定のメールを送った後は、トップへ
  def after_sending_reset_password_instructions_path_for(resource_name)
    root_url
  end

end

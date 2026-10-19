# 開発環境だけ
return unless Rails.env.development?

# 受信箱を空にする（clear）と CSRF の検証で InvalidAuthenticityToken になるため、検証を外す

Rails.application.config.to_prepare do
  LetterOpenerWeb::LettersController.skip_before_action :verify_authenticity_token
end
# セッションの保存先。本番は Redis、開発・テストは Cookie

redis_url = ENV['REDIS_URL']    # docker-compose.yml／ REDIS_URL: redis://redis:6379/1

if Rails.env.production? || redis_url.present?
  # 本番、または REDIS_URL を明示したときだけ Redis を使う
  if Rails.env.production? && redis_url.blank?
    raise "ENV['REDIS_URL'] is required in production"
  end

  Rails.application.config.session_store :redis_session_store,
    servers: [ {
       url: ENV["REDIS_URL"],     # 例: redis://redis:6379/1
       name: "_session",          # 接続名（任意）
       namespace: "session",      # 名前空間を明示して衝突回避
       serializer: :json          # Marshal ではなく JSON に統一（将来互換性も高い）
     } ],

    key: '_micropost7_session',     # セッション Cookie の名前
    secure: Rails.env.production?,          # 本番環境(true)では HTTPSのときだけ送信 = HTTPS接続時のみ Cookieを送信。
    same_site: Rails.env.production? ? :lax : :lax,        # メールのリンクから来たときも Cookie が送られるように :lax（:none にしない）
    expire_after: 14.days                 # セッション期限（お好みで調整）
    # domain は指定しない（Cookie はいまのホストだけに送る）
else
  # 開発・テストは Cookie セッションで Redis 依存を外す
  Rails.application.config.session_store :cookie_store,
    key: '_micropost7_session',
    secure:       false,
    same_site:    :lax,
    expire_after: 14.days
end
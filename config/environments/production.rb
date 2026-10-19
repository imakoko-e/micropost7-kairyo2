require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.
  # ここで指定された設定は、config/application.rbの設定よりも優先される。

  # Code is not reloaded between requests.
  # リクエスト間でコードがリロードされることはない。
  config.cache_classes = true

  # Eager load code on boot.
  # This eager loads most of Rails and your application in memory, allowing both threaded web servers and those relying on copy on write to perform better.
  # これにより、スレッド化されたウェブサーバや、コピーオンライトに依存するウェブサーバのパフォーマンスが向上します。
  # Rake tasks automatically ignore this option for performance.
  # Rakeタスクはパフォーマンスのためにこのオプションを自動的に無視します。
  config.eager_load = true

  # Full error reports are disabled and caching is turned on.
  # フルエラーレポートは無効化され、キャッシュはオンになっている。
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Ensures that a master key has been made available in either ENV["RAILS_MASTER_KEY"] or in config/master.key. This key is used to decrypt credentials (and other encrypted files).
  # ENV[「RAILS_MASTER_KEY」]またはconfig/master.keyでマスターキーが使用可能になっていることを確認する。この鍵は認証情報（およびその他の暗号化ファイル）の復号化に使用される。
  # 本番は必ず master.key（または相当の資格情報）を要求し、鍵の取り違いを防ぐ
  config.require_master_key = true

  # Disable serving static files from the `/public` folder by default since Apache or NGINX already handles this.
  # Apache または NGINX がすでにこれを処理しているため、デフォルトでは `/public` フォルダーからの静的ファイルの提供を無効にします。
  config.public_file_server.enabled = ENV["RAILS_SERVE_STATIC_FILES"].present?

  # Compress CSS using a preprocessor.
  # プリプロセッサを使ってCSSを圧縮する。
  # config.assets.css_compressor = :sass

  # Do not fallback to assets pipeline if a precompiled asset is missed.
  # コンパイル済みアセットが見つからない場合、アセットパイプラインにフォールバックしない。
  # 本番環境では、CSSやJavaScriptをアクセス時に作るのではなく、事前コンパイルするため false
  # Docker運用では、通常Dockerイメージを作る段階で実行する
  config.assets.compile = false

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # アセットサーバーからの画像、スタイルシート、JavaScriptの提供を有効にします。
  # config.asset_host = "http://assets.example.com"

  # Specifies the header that your server uses for sending files.
  # サーバーがファイル送信に使用するヘッダーを指定します。
  # config.action_dispatch.x_sendfile_header = "X-Sendfile" # for Apache
  # config.action_dispatch.x_sendfile_header = "X-Accel-Redirect" # for NGINX

  # Store uploaded files on the local file system (see config/storage.yml for options).
  # アップロードされたファイルをローカルファイルシステムに保存する（オプションはconfig/storage.ymlを参照）。
  # config.active_storage.service = :local
  config.active_storage.service = :production

  # Mount Action Cable outside main process or domain.
  # アクション ケーブルをメイン プロセスまたはドメインの外部にマウントします。
  # config.action_cable.mount_path = nil
  # mount_path を /cable に設定すると、Rails が /cable で ActionCable を受け付けるようになります
  config.action_cable.mount_path = '/cable'

  # WebSocket（Action Cable）用 URL
  # config.action_cable.url = "wss://example.com/cable"
  config.action_cable.url = "wss://#{ENV.fetch('CANONICAL_HOST', 'example.com')}/cable"

  # ブラウザ ⇔ サーバー間のリクエスト元を制限
  # config.action_cable.allowed_request_origins = [ "http://example.com", /http:\/\/example.*/ ]
  config.action_cable.allowed_request_origins = [
    "https://#{ENV.fetch('CANONICAL_HOST', 'example.com')}",
    "https://www.#{ENV.fetch('CANONICAL_HOST', 'example.com')}"       # www 版も許可したい場合
  ]

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  # アプリへのすべてのアクセスをSSL経由で強制し、Strict-Transport-Securityを使用し、安全なクッキーを使用する。
  config.force_ssl = true

  # Include generic and useful information about system operation, but avoid logging too much information to avoid inadvertent exposure of personally identifiable information (PII).
  # システム操作に関する一般的で有用な情報を含めるが、個人を特定できる情報（PII）の不用意な露出を避けるため、多くの情報を記録することは避ける。
  config.log_level = :info
  # debug は情報を出しすぎるため、本番では避けます。

  # Prepend all log lines with the following tags.
  # すべてのログ行の先頭に次のタグを付ける。
  config.log_tags = [ :request_id ]

  # Use a different cache store in production.
  # 本番環境では別のキャッシュストアを使用する。
  # config.cache_store = :mem_cache_store

  # Use a real queuing backend for Active Job (and separate queues per environment).
  # Active Jobには本物のキューイングバックエンドを使いましょう（そして環境ごとにキューを分けましょう）。
  # config.active_job.queue_adapter     = :resque
  # config.active_job.queue_name_prefix = "micropost7_production"

  # メール送信を有効化
  config.action_mailer.perform_deliveries = true

  # Action Mailerのビューでキャッシュをサポートするかどうかを指定 false
  config.action_mailer.perform_caching = false

  # Ignore bad email addresses and do not raise email delivery errors.
  # Set this to true and configure the email server for immediate delivery to raise delivery errors.
  # 不正なメール アドレスを無視し、メール配信エラーを発生させません。
  # これを true に設定し、メール サーバーを即時配信用に構成して、配信エラーを発生させます。
  # config.action_mailer.raise_delivery_errors = false
  # メール送信でエラーを例外として通知する
  config.action_mailer.raise_delivery_errors = true
  # SMTP を使ったメール送信設定

  # メール周りの詳細ログが STDOUT／production.log に出力される
  config.action_mailer.logger = Rails.logger

  # デフォルトのURLオプション（Devise のメール内リンクなどに必要）
  # Devise が生成するメール内リンク用のホスト設定
  # host は、「ユーザーがメール本文中のリンクをクリックしたときに飛ぶ先のアプリケーションのドメイン名」を設定
  # SMTP（メールを送るサーバ）のドメインとは別物
  config.action_mailer.default_url_options = {
    host: ENV.fetch("CANONICAL_HOST", "example.com"), protocol: "https"
  }

  # ActionMailer のデフォルト From も合わせて設定
  config.action_mailer.default_options = { from: ENV.fetch("MAIL_FROM", "no-reply@example.com") }

  # SMTP 設定（メール送信設定）
  config.action_mailer.delivery_method = :smtp

  config.action_mailer.smtp_settings = {
    address:              ENV.fetch("SMTP_ADDRESS", "smtp.example.com"), # SMTP サーバーのホスト
    port:                 587,                        # SMTP ポート STARTTLS 対応ポート
    domain:               ENV.fetch("SMTP_DOMAIN", "example.com"),     # 送信元ドメイン
    user_name:            ENV['SMTP_USERNAME'],       # SMTP 認証用ユーザー名（メールアカウント）
    password:             ENV['SMTP_PASSWORD'],       # SMTP 認証用パスワード／そのパスワード
    authentication:       :login,                     # 認証方式（:plain, :login, :cram_md5）
    enable_starttls_auto: true                        # TLS を自動有効化
  }

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to the I18n.default_locale when a translation cannot be found).
  # I18n のロケール フォールバックを有効にします (翻訳が見つからない場合は、ロケールの検索が I18n.default_locale にフォールバックします)。
  config.i18n.fallbacks = true

  # Don't log any deprecations.
  # 非推奨のログは取らないこと。
  config.active_support.report_deprecations = false

  # Use default logging formatter so that PID and timestamp are not suppressed.
  # PIDとタイムスタンプが抑制されないように、デフォルトのロギングフォーマッタを使用する。
  config.log_formatter = ::Logger::Formatter.new

  # Use a different logger for distributed setups.
  # 分散セットアップには別のロガーを使用してください。
  # require "syslog/logger"
  # config.logger = ActiveSupport::TaggedLogging.new(Syslog::Logger.new "app-name")

  if ENV["RAILS_LOG_TO_STDOUT"].present?
    logger           = ActiveSupport::Logger.new(STDOUT)
    logger.formatter = config.log_formatter
    config.logger    = ActiveSupport::TaggedLogging.new(logger)
  end

  # Do not dump schema after migrations.
  # 移行後にスキーマをダンプしない。
  config.active_record.dump_schema_after_migration = false
end

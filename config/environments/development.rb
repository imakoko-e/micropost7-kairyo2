require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded any time
  # it changes. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports.
  config.consider_all_requests_local = true

  # Enable server timing
  config.server_timing = true

  # Enable/disable caching. By default caching is disabled.
  # Run rails dev:cache to toggle caching.

  if Rails.root.join("tmp/caching-dev.txt").exist?
    config.action_controller.perform_caching = true
    config.action_controller.enable_fragment_cache_logging = true

    if ENV['REDIS_URL'].present?
      # REDIS_URL を明示した場合だけ Redis キャッシュを使用
      config.cache_store = :redis_cache_store, {
        url: ENV['REDIS_URL'],
        namespace: 'cache',
        error_handler: -> (method:, returning:, exception:) {
          Rails.logger.warn "Redis cache error: #{exception.class} #{exception.message}"
        }
      }
    else
      # ふつうはメモリでOK（Redis不要）
      config.cache_store = :memory_store
    end
    config.public_file_server.headers = {
      "Cache-Control" => "public, max-age=#{2.days.to_i}"
    }
  else
    config.action_controller.perform_caching = false
    config.cache_store = :null_store
  end


  # ファイルの保存先
  # アップロードされたファイルをローカル ファイル システムに保存します
  #  (オプションについては config/storage.yml を参照してください)。
  # IN_DOCKER があれば storage.yml の development（/app/storage）、無ければ local
  if ENV["IN_DOCKER"].present?
    config.active_storage.service = :development
  else
    config.active_storage.service = :local
  end

  # Don't care if the mailer can't send.
  # メーラーが送信できなくても気にしないでください。
  config.action_mailer.raise_delivery_errors = false
  # メールの中のリンクの行き先
  config.action_mailer.default_url_options = { host: 'localhost', port: 3000, protocol: 'http' }

  # Action Mailerのビューでキャッシュをサポートするかどうかを指定 false
  config.action_mailer.perform_caching = false

  # メールは送らずに letter_opener_web（/letter_opener）で見る
  config.action_mailer.delivery_method = :letter_opener_web
  config.action_mailer.perform_deliveries = true

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise exceptions for disallowed deprecations.
  config.active_support.disallowed_deprecation = :raise

  # Tell Active Support which deprecation messages to disallow.
  config.active_support.disallowed_deprecation_warnings = []

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Highlight code that triggered database queries in logs.
  config.active_record.verbose_query_logs = true

  # Suppress logger output for asset requests.
  config.assets.quiet = true

  # Raises error for missing translations.
  # config.i18n.raise_on_missing_translations = true

  # Annotate rendered view with file names.
  # config.action_view.annotate_rendered_view_with_filenames = true

  # Uncomment if you wish to allow Action Cable access from any origin.
  # 任意のオリジンからの Action Cable アクセスを許可する場合は、コメントを解除します。
  config.action_cable.disable_request_forgery_protection = true

  # 接続を許可するオリジンと、接続先の URL（rails s は 3000番で待ち受けるので、ポートも書く）
  config.action_cable.allowed_request_origins = [ 'http://localhost:3000' ]
  config.action_cable.url = "ws://localhost:3000/cable"

  # ログを標準出力に出す（docker compose logs で見る）
  config.logger = Logger.new(STDOUT)
  config.log_level = :debug

end

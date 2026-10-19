require_relative "boot"

require "rails/all"

Bundler.require(*Rails.groups)

module Micropost7
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.2

    # 画像処理にMiniMagickを利用する設定
    config.active_storage.variant_processor = :mini_magick

    # アプリのデフォルトタイムゾーンを設定し、Active Recordで認識できるようにする
    config.time_zone = 'Tokyo'

    # データベースから日付・時刻を取り出した際のタイムゾーンをTime.local（:localを指定した場合）と
    # Time.utc（:utcを指定した場合）のどちらにするかを指定。デフォルト値は:utc
    config.active_record.default_timezone = :local

    config.i18n.default_locale = :ja

    # lib/ の下（カナの清音にする KanaUtils など）を読み込む。eager_load_paths なら開発でも本番でも読み込まれる
    config.eager_load_paths << Rails.root.join('lib')

    # rails g でテストを作るときは RSpec にし、view・helper・routing のテストは作らない
    config.generators do |g|
      g.test_framework :rspec,
                       view_specs: false,
                       helper_specs: false,
                       routing_specs: false
    end
  end
end

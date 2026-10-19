source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.3.7"

gem 'rails', '~> 7.2', '>= 7.2.2.1'

# 画像処理用のgem
gem 'image_processing',           '~> 1.14'
# image_processing が使う。5 系は依存関係でエラーになるため 4 系にとどめる
gem 'mini_magick',                '>= 4.9.5','< 5'

# Active Storageバリデーション用のgem
gem 'active_storage_validations', '~> 2.0', '>= 2.0.2'

# 架空のユーザー名を作成するgem
gem 'faker',                      '~> 3.5', '>= 3.5.1'
# ランダムな日本語の名前と住所を生成するジェネレーター
gem 'gimei',                      '~> 1.5', '>= 1.5.1'

# ページネーション（見た目は Tailwind CSS で .pagination を定義している）
gem 'will_paginate',   '~> 4.0', '>= 4.0.1'

gem 'tailwindcss-rails', '~> 4.4'

# Asset Pipelineに必要 sha256でフィンガープリント追加してキャッシュバスターする
gem 'sprockets-rails', '~> 3.5', '>= 3.5.2'

# Rails7で導入、javascript関連のWebpackerの代替
gem "importmap-rails",  '~> 2.1'
# Hotwire構成要素/Turboの利用(Turbo Drive、Turbo Frames、Turbo Streams)
# （すべてのリンクのクリックとフォーム送信を Ajax リクエストに変換）
gem 'turbo-rails', '~> 2.0', '>= 2.0.17'
# Hotwire構成要素/Stimulusの利用
gem "stimulus-rails",   '~> 1.3', '>= 1.3.4'
# JSON形式のデータを簡単に作成する事が出来るgem
gem 'jbuilder', '~> 2.13'

gem "bcrypt",           '~> 3.1', '>= 3.1.20'
# Ruby用のWebサーバー
gem "puma",             '~> 6.6'
# Ruby / Railsのアプリを高速化する為のgem
gem "bootsnap", '~> 1.18', '>= 1.18.4'

gem "redis", "~> 4.0"           # Action Cable（本番）で使う
# サーバ側セッションにするためのセッションストア
gem 'redis-session-store', '~> 0.11.6'

# Railsアプリを国際化、またはローカライズするための共通ロケール
# データと翻訳のセット（8 系は依存関係でエラーになるため 7 系）
gem 'rails-i18n',       '~> 7.0', '>= 7.0.10'

# ログイン等の認証機能をdeviseで実装する
gem 'devise',       '~> 4.9', '>= 4.9.4'
# deviseエラーメッセージの日本語化
gem 'devise-i18n', '~> 1.13'
gem 'devise-i18n-views',  '~> 0.3.7'
# devise OmniAuthによるGoogleログインGemの導入
gem 'omniauth-google-oauth2',         '~> 1.2', '>= 1.2.1'
gem 'omniauth-rails_csrf_protection', '~> 1.0', '>= 1.0.2'    # セキュリティ対策用
# devise.rb の config.responder（Hotwire/Turbo 向けのステータス）の設定のために入れた
gem 'responders', '~> 3.1', '>= 3.1.1'

group :development, :test do   #本番環境では使わないようにする
  gem 'debug', '~> 1.10'

  # ruby-debug を RubyMine などの IDE に統合するインターフェース。
  gem 'ruby-debug-ide', '~> 0.7.5'        #  RubyMineに必要

  gem 'debase',                   '~> 0.2.9'              #  RubyMineに必要
  gem 'debase-ruby_core_source',  '~> 3.4', '>= 3.4.1'

  gem 'rspec-rails', '~> 8.0', '>= 8.0.3'
  gem 'factory_bot_rails', '~> 6.5', '>= 6.5.1'
end

group :development do
  gem "web-console", "4.2.1"
  gem 'pry-rails',    '~> 0.3.11'         # railsでpryを使用する
  gem 'pry-stack_explorer', '~> 0.6.1'
  gem 'pry-byebug', '~> 3.11'
  # ローカル開発環境で送信したメールを確認するgem
  gem 'letter_opener_web', '~> 3.0'
  # html.erbファイルをVisual Studio CodeでAuto Formatする
  gem 'htmlbeautifier', '~> 1.4', '>= 1.4.3'
end

group :test do
  gem 'sqlite3', '~> 2.6'
  # Webアプリケーションのための統合テストツール。ユーザーがウェブサイトとどのようにやりとりするかをシミュレート
  # ユーザーがブラウザで行う操作を抽象化し、テストコード上での実行を可能にする
  gem "capybara",                 '~> 3.40'
  # Seleniumは主にウェブアプリケーションのテストを目的
  # JavaScriptをテストするドライバー（webdrivers 5.3.0 が selenium-webdriver ~> 4.0, < 4.11 に依存）
  gem "selenium-webdriver",       '~> 4.0', '< 4.11'
  gem "webdrivers",               '= 5.3.0'
  # RSpec 関係
  gem 'launchy',          '~> 3.1', '>= 3.1.1'        # システムスペックをデバッグするgem
  gem 'shoulda-matchers', '~> 7.0', '>= 7.0.1'
  gem 'vcr',              '~> 6.4'
  gem 'webmock',          '~> 3.26', '>= 3.26.1'

end

group :development, :production do
  #Railsが PostgreSQLデータベースと通信できるようにする
  gem "pg", '~> 1.5', '>= 1.5.9'
end

group :production do      #本番環境
end

# Windows ではタイムゾーン情報用の tzinfo-data gem を含める必要があります
# gem "tzinfo-data", platforms: [:mingw, :mswin, :x64_mingw, :jruby]

# Redis の初期化（1回だけ）。セッションと、メール確認の引き継ぎ（handoff）で使う

# 開発環境では REDIS_URL 無しなら初期化しない
if ENV['REDIS_URL'].present?
  # Redis への接続設定。ENV が無ければ docker-compose の "redis" サービス前提で繋ぐ
  REDIS_URL = ENV.fetch("REDIS_URL", "redis://redis:6379/1")

  require "redis"
  $redis = Redis.new(url: REDIS_URL)  # かんたん接続。必要なら ConnectionPool に置き換え可能

  Rails.logger.info "[redis] connected to #{REDIS_URL}"
else
  $redis = nil
end
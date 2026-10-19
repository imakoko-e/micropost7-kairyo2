# app/services/waiter_registry.rb
# セッション・ハンドオフ方式の部品
#
# 役割：
#   1. ユーザーID → 「最新の待機用 jti」を短時間だけ保存／取得
#   2. メール確認が待機タブの subscribe より先に走った場合の保険として、
#      ハンドオフトークンを uid ごとに短期保存／取り出し（take, 単発使用）
#
# バックエンド：REDIS_URL があれば Redis、無ければ Rails.cache（dev の NullStore は MemoryStore に自動置換）
class WaiterRegistry
  # 「最新 jti」の保存キー
  KEY_FMT = "waiter:latest:%{uid}"
  # 保留ハンドオフトークンの保存キー
  PENDING_FMT = "waiter:pending:%{uid}"

  class << self
    # 待機ページを開いたタイミングで、そのタブ専用の jti を登録する
    def set_latest_jti_for(uid, jti, ttl: 30.minutes)
      write_backend(KEY_FMT % { uid: uid }, jti, ttl: ttl)
    end

    # メール確認成功時に、どの jti のストリームへ通知すべきかを取り出す
    def latest_jti_for(uid)
      read_backend(KEY_FMT % { uid: uid })
    end

    # ハンドオフトークンを保留保存する（subscribe より先に show が走った場合の保険）
    def set_pending_handoff(uid, token, ttl: 5.minutes)
      write_backend(PENDING_FMT % { uid: uid }, token, ttl: ttl)
    end

    # 保留中のハンドオフトークンを取り出して削除する（1回限り）
    # subscribe 時に取り出し、既に確認済みなら即時クライアントへ transmit する用途
    def take_pending_handoff(uid)
      key = PENDING_FMT % { uid: uid }
      value = read_backend(key)
      delete_backend(key) if value
      value
    end

    # バックエンドが使える状態か（運用確認用）
    # cache メソッドが NullStore の場合に MemoryStore へ自動フォールバックするため、
    # Rails.cache 自体が NullStore でもここは true を返す。
    def available?
      redis_available? || !cache.is_a?(ActiveSupport::Cache::NullStore)
    end

    private

    # 書き込み：Redis 優先、フォールバックで Rails.cache
    def write_backend(key, value, ttl:)
      if redis_available?
        redis.set(key, value, ex: ttl.to_i)
      else
        cache.write(key, value, expires_in: ttl)
      end
    rescue => e
      Rails.logger.warn "[WaiterRegistry] write failed: #{e.class} #{e.message}"
      nil
    end

    # 読み出し：Redis 優先、フォールバックで Rails.cache
    def read_backend(key)
      if redis_available?
        redis.get(key)
      else
        cache.read(key)
      end
    rescue => e
      Rails.logger.warn "[WaiterRegistry] read failed: #{e.class} #{e.message}"
      nil
    end

    # 削除：Redis 優先、フォールバックで Rails.cache
    def delete_backend(key)
      if redis_available?
        redis.del(key)
      else
        cache.delete(key)
      end
    rescue => e
      Rails.logger.warn "[WaiterRegistry] delete failed: #{e.class} #{e.message}"
      nil
    end

    # --- backends ---
    def redis_available?
      ENV['REDIS_URL'].present?
    end

    def redis
      @redis ||= Redis.new(url: ENV['REDIS_URL'])
    end

    # dev で Rails.cache が NullStore の場合は、プロセス内の MemoryStore を使用
    def cache
      if Rails.cache.is_a?(ActiveSupport::Cache::NullStore)
        @local_cache ||= ActiveSupport::Cache::MemoryStore.new
      else
        Rails.cache
      end
    end
  end
end

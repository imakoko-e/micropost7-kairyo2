# frozen_string_literal: true
# app/services/used_jti_store.rb
# セッション・ハンドオフ方式の部品。使い捨てトークン（JTI）を「使用済み」として短い間だけ記録し、
# 同じトークンの使い回し（リプレイ）を防ぐ。
# REDIS_URL があれば Redis、無ければ Rails.cache（開発の NullStore はメモリに置き換える）
class UsedJtiStore
  KEY_FMT = "used_jti:%{jti}"

  class << self
    # jti が既に使われたか？
    def used?(jti)
      key = KEY_FMT % { jti: jti }
      if redis_available?
        # Redis >= 4 は exists? が Boolean を返します
        redis.exists?(key)
      else
        cache.exist?(key)
      end
    rescue => e
      Rails.logger.warn "[UsedJtiStore] used? failed: #{e.class} #{e.message}"
      false
    end

    # jti を「使用済み」にマーク（期限付き）
    def mark!(jti, ttl: 10.minutes)
      key = KEY_FMT % { jti: jti }
      if redis_available?
        redis.set(key, 1, ex: ttl.to_i)
      else
        cache.write(key, true, expires_in: ttl)
      end
      true
    rescue => e
      Rails.logger.warn "[UsedJtiStore] mark! failed: #{e.class} #{e.message}"
      false
    end

    def available?
      redis_available? || !Rails.cache.is_a?(ActiveSupport::Cache::NullStore)
    end

    private

    def redis_available?
      ENV['REDIS_URL'].present?
    end

    def redis
      @redis ||= Redis.new(url: ENV['REDIS_URL'])
    end

    def cache
      # 開発でキャッシュが無効（NullStore）なら、プロセス内のメモリを使う
      if Rails.cache.is_a?(ActiveSupport::Cache::NullStore)
        @local_cache ||= ActiveSupport::Cache::MemoryStore.new
      else
        Rails.cache
      end
    end

  end
end

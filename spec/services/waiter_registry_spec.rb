# WaiterRegistry の挙動確認
# テスト環境は ENV['REDIS_URL'] が無いため、Rails.cache 側のバックエンドで動作する
require 'rails_helper'

RSpec.describe WaiterRegistry do
  # Rails.cache は dev/test で NullStore の場合があるため、内部で MemoryStore に差し替わる設計。
  # 各テストで副作用が残らないよう、内部の local_cache を毎回リセットする。
  before do
    described_class.instance_variable_set(:@local_cache, nil)
  end

  describe '.set_latest_jti_for / .latest_jti_for' do
    let(:uid) { 123 }
    let(:jti) { 'abc123' }

    it '保存した jti を取り出せること' do
      described_class.set_latest_jti_for(uid, jti)
      expect(described_class.latest_jti_for(uid)).to eq(jti)
    end

    it '後から書き込んだ jti で上書きされること' do
      described_class.set_latest_jti_for(uid, 'old')
      described_class.set_latest_jti_for(uid, 'new')
      expect(described_class.latest_jti_for(uid)).to eq('new')
    end

    it '未保存の uid に対しては nil を返すこと' do
      expect(described_class.latest_jti_for(999)).to be_nil
    end
  end

  describe '.set_pending_handoff / .take_pending_handoff' do
    let(:uid)   { 42 }
    let(:token) { 'handoff-token-xxx' }

    it '保留トークンを保存 → 取り出しができること' do
      described_class.set_pending_handoff(uid, token)
      expect(described_class.take_pending_handoff(uid)).to eq(token)
    end

    it '1回 take すると削除され、2回目以降は nil になること（単発使用）' do
      described_class.set_pending_handoff(uid, token)
      described_class.take_pending_handoff(uid)
      expect(described_class.take_pending_handoff(uid)).to be_nil
    end

    it '未保存の uid に対しては nil を返すこと' do
      expect(described_class.take_pending_handoff(999)).to be_nil
    end

    it '異なる uid 同士では独立していること' do
      described_class.set_pending_handoff(1, 'token-1')
      described_class.set_pending_handoff(2, 'token-2')

      expect(described_class.take_pending_handoff(1)).to eq('token-1')
      expect(described_class.take_pending_handoff(2)).to eq('token-2')
    end
  end

  describe '.available?' do
    it 'テスト環境でも利用可能なバックエンド（Rails.cache or Redis）が存在すること' do
      expect(described_class.available?).to eq(true)
    end
  end
end

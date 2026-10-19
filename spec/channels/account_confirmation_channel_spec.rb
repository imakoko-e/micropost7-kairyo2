# ActionCable チャンネルの挙動を検証
# - waiter_sig の検証
# - subscribe 時の pending_handoff 即時配信（レース対策）
require 'rails_helper'

RSpec.describe AccountConfirmationChannel, type: :channel do
  let(:user) { create(:user, :unconfirmed) }
  let(:jti)  { SecureRandom.hex(16) }

  # 有効な waiter_sig を生成するヘルパー
  def valid_waiter_sig(uid:, jti:, exp: 30.minutes.from_now)
    Rails.application.message_verifier(:waiter)
                     .generate({ uid: uid, jti: jti, exp: exp.to_i }, purpose: :waiter)
  end

  before do
    # 接続を張る（current_user はこのチャンネルでは使わないため nil でよい）
    stub_connection current_user: nil
    # WaiterRegistry 内部キャッシュをリセット
    WaiterRegistry.instance_variable_set(:@local_cache, nil)
  end

  describe '#subscribed' do
    context '有効な waiter_sig のとき' do
      it 'jti 単位のストリームに参加すること' do
        subscribe(waiter_sig: valid_waiter_sig(uid: user.id, jti: jti))

        expect(subscription).to be_confirmed
        expect(subscription).to have_stream_from("confirmation_wait:#{jti}")
      end
    end

    context 'waiter_sig が未指定のとき' do
      it '購読が拒否されること' do
        subscribe(waiter_sig: nil)
        expect(subscription).to be_rejected
      end
    end

    context 'waiter_sig が改ざんされたとき' do
      it '購読が拒否されること' do
        subscribe(waiter_sig: 'tampered-sig')
        expect(subscription).to be_rejected
      end
    end

    context 'waiter_sig の期限が切れているとき' do
      it '購読が拒否されること' do
        expired = valid_waiter_sig(uid: user.id, jti: jti, exp: 1.minute.ago)
        subscribe(waiter_sig: expired)
        expect(subscription).to be_rejected
      end
    end

    context 'subscribe より先にメール確認が走っていた（pending_handoff あり）とき' do
      it '保留トークンを即時 transmit すること' do
        WaiterRegistry.set_pending_handoff(user.id, 'pending-token-xxx')

        subscribe(waiter_sig: valid_waiter_sig(uid: user.id, jti: jti))

        expect(subscription).to be_confirmed
        # transmit の内容を検査
        expect(transmissions.last).to include(
          'status'        => 'confirmed',
          'handoff_token' => 'pending-token-xxx'
        )
      end

      it '取り出し後は pending_handoff が削除されていること（単発使用）' do
        WaiterRegistry.set_pending_handoff(user.id, 'pending-token-xxx')

        subscribe(waiter_sig: valid_waiter_sig(uid: user.id, jti: jti))

        expect(WaiterRegistry.take_pending_handoff(user.id)).to be_nil
      end
    end

    context 'pending_handoff が無いとき' do
      it 'transmit は呼ばれないこと' do
        subscribe(waiter_sig: valid_waiter_sig(uid: user.id, jti: jti))

        expect(subscription).to be_confirmed
        expect(transmissions).to be_empty
      end
    end
  end
end

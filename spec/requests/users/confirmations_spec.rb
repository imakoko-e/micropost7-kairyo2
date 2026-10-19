# メール確認リンクの挙動（成功/失敗、ハンドオフ通知）を検証
require 'rails_helper'

RSpec.describe 'Users::Confirmations', type: :request do
  # 有効な confirmation_token を持つ未確認ユーザーを作る
  let(:unconfirmed_user) do
    user = build(:user, :unconfirmed)
    user.skip_confirmation_notification!
    # Devise が生成する raw なトークンを得るために send_confirmation_instructions を通す
    raw_token = user.instance_eval do
      @raw_confirmation_token, hashed = Devise.token_generator.generate(self.class, :confirmation_token)
      self.confirmation_token = hashed
      self.confirmation_sent_at = Time.current
      save!(validate: false)
      @raw_confirmation_token
    end
    [user, raw_token]
  end

  describe 'GET /users/confirmation?confirmation_token=...' do
    context '有効なトークンのとき' do
      it '確認済みになり、通知画面へリダイレクトされること' do
        user, raw_token = unconfirmed_user
        get user_confirmation_path(confirmation_token: raw_token)

        expect(response).to redirect_to(page_mail_check_path)
        expect(user.reload.confirmed?).to eq(true)
      end

      it '保留ハンドオフトークンが WaiterRegistry に保存されること' do
        user, raw_token = unconfirmed_user

        expect(WaiterRegistry).to receive(:set_pending_handoff)
          .with(user.id, kind_of(String), hash_including(:ttl))

        get user_confirmation_path(confirmation_token: raw_token)
      end

      it '最新 jti が存在するときは ActionCable.server.broadcast が呼ばれること' do
        user, raw_token = unconfirmed_user
        WaiterRegistry.set_latest_jti_for(user.id, 'test-jti')

        expect(ActionCable.server).to receive(:broadcast)
          .with("confirmation_wait:test-jti", hash_including(status: 'confirmed', handoff_token: kind_of(String)))

        get user_confirmation_path(confirmation_token: raw_token)
      end

      it '最新 jti が無いときは broadcast は呼ばれない（pending_handoff で吸収する）' do
        _, raw_token = unconfirmed_user
        # latest_jti_for が nil を返すよう明示
        allow(WaiterRegistry).to receive(:latest_jti_for).and_return(nil)
        allow(WaiterRegistry).to receive(:set_pending_handoff)

        expect(ActionCable.server).not_to receive(:broadcast)

        get user_confirmation_path(confirmation_token: raw_token)
      end
    end

    context '無効なトークンのとき' do
      it '通知画面へリダイレクトされること（422 経由）' do
        get user_confirmation_path(confirmation_token: 'invalid-token')
        expect(response).to redirect_to(page_mail_check_path)
      end
    end

    context '既に確認済みユーザーのトークンで再アクセスされたとき（リンク二重アクセス対策）' do
      # メールリンクのプリフェッチ／スキャナで二重に叩かれるケース。
      # エラー画面ではなく、正常系と同じく確認完了画面へ導き、待機タブへもハンドオフを送る（冪等化）。
      it '通知画面へリダイレクト（303）され、エラー画面にはならないこと' do
        # confirmed ユーザーの生トークンを作って再送 → already_confirmed を誘発
        user = create(:user)      # デフォルトで confirmed_at あり
        raw_token, hashed = Devise.token_generator.generate(User, :confirmation_token)
        user.update_columns(confirmation_token: hashed, confirmation_sent_at: Time.current)

        get user_confirmation_path(confirmation_token: raw_token)

        expect(response).to redirect_to(page_mail_check_path)
        expect(response).to have_http_status(:see_other)
      end

      it '待機タブへ向けてハンドオフ（pending_handoff）が再送されること' do
        user = create(:user)
        raw_token, hashed = Devise.token_generator.generate(User, :confirmation_token)
        user.update_columns(confirmation_token: hashed, confirmation_sent_at: Time.current)

        expect(WaiterRegistry).to receive(:set_pending_handoff)
          .with(user.id, kind_of(String), hash_including(:ttl))

        get user_confirmation_path(confirmation_token: raw_token)
      end
    end
  end
end

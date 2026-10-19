# ハンドオフトークンによる自動ログイン成立の検証
require 'rails_helper'

RSpec.describe 'AuthHandoffs', type: :request do
  let(:user) { create(:user) }

  # 有効なハンドオフトークンを生成するヘルパー
  def handoff_token_for(user, jti: SecureRandom.hex(16), exp: 5.minutes.from_now)
    payload = { uid: user.id, jti: jti, exp: exp.to_i }
    Rails.application.message_verifier(:confirm_handoff)
                     .generate(payload, purpose: :confirm_handoff)
  end

  describe 'POST /auth/handoff' do
    context '有効なトークンのとき' do
      it 'ログイン成立し、ok: true を返すこと' do
        token = handoff_token_for(user)

        post auth_handoff_path, params: { token: token }, as: :json

        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        expect(body['ok']).to eq(true)
        expect(body['user_id']).to eq(user.id)
      end

      it '使い捨て jti として UsedJtiStore にマークされること（リプレイ防止）' do
        jti = SecureRandom.hex(16)
        token = handoff_token_for(user, jti: jti)

        expect {
          post auth_handoff_path, params: { token: token }, as: :json
        }.to change { UsedJtiStore.used?(jti) }.from(false).to(true)
      end
    end

    context 'token が未指定のとき' do
      it '400 Bad Request を返すこと' do
        post auth_handoff_path, params: {}, as: :json
        expect(response).to have_http_status(:bad_request)
        expect(JSON.parse(response.body)['ok']).to eq(false)
      end
    end

    context 'token が改ざんされたとき' do
      it '401 Unauthorized を返すこと' do
        post auth_handoff_path, params: { token: 'tampered-token' }, as: :json
        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)['ok']).to eq(false)
      end
    end

    context 'token の期限が切れているとき' do
      it '401 Unauthorized を返すこと' do
        expired_token = handoff_token_for(user, exp: 1.minute.ago)

        post auth_handoff_path, params: { token: expired_token }, as: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context '同じ jti で再度リクエストされたとき（リプレイ攻撃）' do
      it '2回目は 401 Unauthorized で拒否されること' do
        jti = SecureRandom.hex(16)
        token = handoff_token_for(user, jti: jti)

        # 1回目：成功
        post auth_handoff_path, params: { token: token }, as: :json
        expect(response).to have_http_status(:ok)

        # 2回目：同一トークンでリプレイ → 拒否
        post auth_handoff_path, params: { token: token }, as: :json
        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)['error']).to eq('replayed')
      end
    end
  end
end

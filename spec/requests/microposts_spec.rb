require 'rails_helper'
# 投稿作成 + 未ログイン保護
RSpec.describe 'Microposts', type: :request do
  let(:user) { create(:user) }

  describe 'POST /microposts' do
    context 'ログインしているとき' do
      before do
        sign_in user
      end

      it '有効な投稿は作成できること' do
        expect do
          post microposts_path, params: {
            micropost: { content: 'request spec からの投稿です' }
          }
        end.to change(Micropost, :count).by(1)
      end

      it '無効な投稿は作成できないこと' do
        expect do
          post microposts_path, params: {
            micropost: { content: '' }
          }
        end.not_to change(Micropost, :count)
      end
    end

    context 'ログインしていないとき' do
      it '投稿を作成できず、ログイン画面へリダイレクトされること' do
        expect do
          post microposts_path, params: {
            micropost: { content: '未ログインでは作成できない投稿' }
          }
        end.not_to change(Micropost, :count)

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
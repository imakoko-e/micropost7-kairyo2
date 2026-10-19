require 'rails_helper'
# 投稿削除 + 未ログイン保護
RSpec.describe 'Microposts', type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }

  describe 'DELETE /microposts/:id' do
    context '自分の投稿のとき' do
      let!(:micropost) { create(:micropost, user: user) }

      before do
        sign_in user
      end

      it '削除できること' do
        expect do
          delete micropost_path(micropost)
        end.to change(Micropost, :count).by(-1)
      end
    end

    context '他人の投稿のとき' do
      let!(:micropost) { create(:micropost, user: other_user) }

      before do
        sign_in user
      end

      it '削除できないこと' do
        expect do
          delete micropost_path(micropost)
        end.not_to change(Micropost, :count)
      end
    end

    context 'ログインしていないとき' do
      let!(:micropost) { create(:micropost, user: user) }

      it '削除できず、ログイン画面へリダイレクトされること' do
        expect do
          delete micropost_path(micropost)
        end.not_to change(Micropost, :count)

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
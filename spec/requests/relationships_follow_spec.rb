require 'rails_helper'
# フォロー / 解除 + 未ログイン保護
RSpec.describe 'Relationships', type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }

  describe 'POST /relationships' do
    context 'ログインしているとき' do
      before do
        sign_in user
      end

      it '他ユーザーをフォローできること' do
        expect do
          post relationships_path, params: { followed_id: other_user.id }
        end.to change(Relationship, :count).by(1)
      end
    end

    context 'ログインしていないとき' do
      it 'フォローできず、ログイン画面へリダイレクトされること' do
        expect do
          post relationships_path, params: { followed_id: other_user.id }
        end.not_to change(Relationship, :count)

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'DELETE /relationships/:id' do
    context 'ログインしているとき' do
      let!(:relationship) { create(:relationship, follower: user, followed: other_user) }

      before do
        sign_in user
      end

      it 'フォロー解除できること' do
        expect do
          delete relationship_path(relationship)
        end.to change(Relationship, :count).by(-1)
      end
    end

    context 'ログインしていないとき' do
      let!(:relationship) { create(:relationship, follower: user, followed: other_user) }

      it 'フォロー解除できず、ログイン画面へリダイレクトされること' do
        expect do
          delete relationship_path(relationship)
        end.not_to change(Relationship, :count)

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
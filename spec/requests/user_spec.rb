# ユーザー編集権限 / 一覧 / 詳細
require 'rails_helper'

RSpec.describe 'Users', type: :request do
  describe 'GET /users' do
    context '未ログインのとき' do
      it 'ログイン画面へリダイレクトされること' do
        get users_path      # 未ログインで /users にアクセス
        expect(response).to redirect_to(new_user_session_path)    # ログイン画面へ飛ばされる
      end
    end

    context 'ログイン済みのとき' do
      let(:user) { create(:user) }

      before do
        sign_in user
      end

      it 'ユーザー一覧ページが表示できること' do
        get users_path    # ログイン済みで /users にアクセス
        expect(response).to have_http_status(:ok)   # 200 OK が返る（正常に表示される）
      end
    end
  end

  describe 'GET /users/:id' do
    let(:user) { create(:user) }

    context '未ログインのとき' do
      it 'ログイン画面へリダイレクトされること' do
        get user_path(user)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'ログイン済みのとき' do
      before do
        sign_in user
      end

      it 'ユーザー詳細ページが表示できること' do
        get user_path(user)
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe 'GET /profile' do
    let(:user) { create(:user) }

    context '未ログインのとき' do
      it 'ログイン画面へリダイレクトされること' do
        get profile_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'ログイン済みのとき' do
      before do
        sign_in user
      end

      it 'プロフィールページが表示されること' do
        get profile_path
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe 'GET /profile/edit' do
    let(:user) { create(:user) }

    context '未ログインのとき' do
      it 'ログイン画面へリダイレクトされること' do
        get edit_profile_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context '本人がログインしているとき' do
      before do
        sign_in user
      end

      it '自分の編集画面へアクセスできること' do
        get edit_profile_path
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe 'PATCH /profile' do
    let(:user) { create(:user) }

    let(:valid_params) do
      {
        user: {
          last_name: '更新後姓',
          first_name: '更新後名',
          email: 'updated_user@example.com'
        }
      }
    end

    context '未ログインのとき' do
      it '更新できず、ログイン画面へリダイレクトされること' do
        patch profile_path, params: valid_params
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context '本人がログインしているとき' do
      before do
        sign_in user
      end

      it '自分の情報を更新できること' do
        patch profile_path, params: valid_params
        # DB の値を読み直す（読み直さないと、メモリ上の古い値のまま）
        user.reload

        expect(user.last_name).to eq('更新後姓')
        expect(user.first_name).to eq('更新後名')
      end

      it '無効なパラメーター（name が51文字超）では更新されず、編集画面が再表示されること' do
        # last_name 30文字 + first_name 30文字 → compose_name で name が60文字になりバリデーション失敗
        patch profile_path, params: {
          user: { last_name: 'あ' * 30, first_name: 'い' * 30 }
        }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'GET /users/:id/following' do
    let(:user) { create(:user) }

    context '未ログインのとき' do
      it 'ログイン画面へリダイレクトされること' do
        get following_user_path(user)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'ログイン済みのとき' do
      before do
        sign_in user
      end

      it 'フォロー中ユーザー一覧ページが表示されること' do
        get following_user_path(user)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'GET /users/:id/followers' do
    let(:user) { create(:user) }

    context '未ログインのとき' do
      it 'ログイン画面へリダイレクトされること' do
        get followers_user_path(user)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'ログイン済みのとき' do
      before do
        sign_in user
      end

      it 'フォロワー一覧ページが表示されること' do
        get followers_user_path(user)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
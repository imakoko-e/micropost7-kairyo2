# プロフィール確認画面フローのリクエストスペック
# 対象アクション: confirm（新規）、edit のセッション復元、update のリダイレクト先変更
require 'rails_helper'

RSpec.describe 'Profiles', type: :request do
  # POST /profile/confirm（入力確認画面への遷移）
  describe 'POST /profile/confirm' do

    context '未ログインのとき' do
      it 'ログイン画面へリダイレクトされること' do
        post confirm_profile_path, params: { user: { last_name: 'テスト', first_name: '太郎' } }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'ログイン済みのとき' do
      let(:user) { create(:user) }

      before { sign_in user }

      context '有効なパラメーターのとき' do
        let(:valid_params) do
          {
            user: {
              last_name:       '山田',
              first_name:      '花子',
              last_name_kana:  'ヤマダ',
              first_name_kana: 'ハナコ',
              gender:          2,
              hobbies:         '読書',
              special_skills:  '料理'
            }
          }
        end

        it '確認画面が表示されること（200 OK）' do
          post confirm_profile_path, params: valid_params
          expect(response).to have_http_status(:ok)
        end

        it '入力値がセッションに保存されること' do
          post confirm_profile_path, params: valid_params
          expect(session[:profile_params]).to include(
            'last_name'  => '山田',
            'first_name' => '花子'
          )
        end
      end

      context '無効なパラメーター（last_name + first_name の合計が50文字超）のとき' do
        # compose_name により name = last_name + " " + first_name が生成される。
        # 30文字 + 30文字 = 60文字 → validates :name, length: { maximum: 50 } に引っかかる
        let(:invalid_params) do
          { user: { last_name: 'あ' * 30, first_name: 'い' * 30 } }
        end

        it '編集画面が再表示されること（422 Unprocessable Entity）' do
          post confirm_profile_path, params: invalid_params
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it 'セッションに入力値が保存されないこと' do
          post confirm_profile_path, params: invalid_params
          expect(session[:profile_params]).to be_nil
        end
      end
    end
  end
  # GET /profile/edit（「変更に戻る」押下後のセッション復元）
  describe 'GET /profile/edit（セッション復元）' do
    let(:user) { create(:user) }

    before { sign_in user }

    context 'セッションに入力値が保存されているとき' do
      before do
        # confirm アクションを経由してセッションに値を保存する
        post confirm_profile_path, params: {
          user: { last_name: '復元姓', first_name: '復元名' }
        }
      end

      it 'セッションが消費（削除）されること' do
        # edit アクションは session.delete(:profile_params) でセッションを消費する
        get edit_profile_path
        expect(session[:profile_params]).to be_nil
      end

      it '編集画面が正常に表示されること' do
        get edit_profile_path
        expect(response).to have_http_status(:ok)
      end
    end
  end
  # PATCH /profile（更新後のリダイレクト先）
  describe 'PATCH /profile' do
    let(:user) { create(:user) }

    before { sign_in user }

    context '有効なパラメーターのとき' do
      let(:valid_params) do
        { user: { last_name: '更新後姓', first_name: '更新後名' } }
      end

      it '更新後にホーム画面へリダイレクトされること' do
        patch profile_path, params: valid_params
        expect(response).to redirect_to(root_path)
      end

      it 'DBのデータが更新されること' do
        patch profile_path, params: valid_params
        user.reload
        expect(user.last_name).to eq('更新後姓')
        expect(user.first_name).to eq('更新後名')
      end

      it 'セッションの入力値がクリアされること' do
        # 事前に confirm でセッションに値を入れる
        post confirm_profile_path, params: valid_params
        expect(session[:profile_params]).to be_present

        # update 後にセッションがクリアされること
        patch profile_path, params: valid_params
        expect(session[:profile_params]).to be_nil
      end
    end

    context '無効なパラメーターのとき' do
      it '編集画面が再表示されること（422 Unprocessable Entity）' do
        patch profile_path, params: {
          user: { last_name: 'あ' * 30, first_name: 'い' * 30 }
        }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

end

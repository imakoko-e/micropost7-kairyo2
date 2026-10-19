# destroy 認可・confirm_wait の署名付き URL の検証
require 'rails_helper'

RSpec.describe 'Users::Registrations', type: :request do
  # DELETE /users/:id（ユーザー削除の認可）
  # 背景：以前は認可チェックが抜けており、ログイン中の誰でも他人を削除できる脆弱性があった
  describe 'DELETE /users/:id' do
    let(:owner)  { create(:user) }
    let(:victim) { create(:user) }

    context '未ログインのとき' do
      it 'ログイン画面へリダイレクトされ、ユーザーは削除されないこと' do
        delete destroy_user_path(victim)
        expect(response).to redirect_to(new_user_session_path)
        expect(User.exists?(victim.id)).to eq(true)
      end
    end

    context '他人の ID で削除を試みたとき' do
      before { sign_in owner }

      it 'ルートへリダイレクトされ、他人は削除されないこと' do
        delete destroy_user_path(victim)
        expect(response).to redirect_to(root_url)
        expect(User.exists?(victim.id)).to eq(true)
      end
    end

    context '自分自身を削除するとき' do
      before { sign_in owner }

      it '削除が成功し、ルートへリダイレクトされること' do
        delete destroy_user_path(owner)
        expect(response).to redirect_to(root_url)
        expect(User.exists?(owner.id)).to eq(false)
      end
    end
  end
  # GET /users/confirm_wait?sig=...（署名付きトークンによる閲覧制御）
  # 背景：従来は /users/confirm_wait/:id の形式で id を推測されるとメールが漏れた
  describe 'GET /users/confirm_wait' do
    # 有効な sig を生成するヘルパー
    def valid_sig_for(user, exp: 30.minutes.from_now)
      Rails.application.message_verifier(:confirm_wait_access)
        .generate({ uid: user.id, exp: exp.to_i }, purpose: :confirm_wait_access)
    end

    let(:unconfirmed) { create(:user, :unconfirmed) }

    context '有効な sig のとき' do
      it '待機画面が表示されること（200 OK）' do
        get wait_for_confirmation_path(sig: valid_sig_for(unconfirmed))
        expect(response).to have_http_status(:ok)
      end
    end

    context 'sig が未指定のとき' do
      it 'ルートへリダイレクトされること' do
        get wait_for_confirmation_path
        expect(response).to redirect_to(root_path)
      end
    end

    context 'sig が改ざんされたとき' do
      it 'ルートへリダイレクトされること' do
        get wait_for_confirmation_path(sig: 'tampered-token')
        expect(response).to redirect_to(root_path)
      end
    end

    context 'sig の期限が切れているとき' do
      it 'ルートへリダイレクトされること' do
        expired_sig = valid_sig_for(unconfirmed, exp: 1.minute.ago)
        get wait_for_confirmation_path(sig: expired_sig)
        expect(response).to redirect_to(root_path)
      end
    end

    context 'sig に含まれる uid のユーザーが既に確認済みのとき' do
      it 'ルートへリダイレクトされること（情報漏えい防止）' do
        confirmed_user = create(:user)
        get wait_for_confirmation_path(sig: valid_sig_for(confirmed_user))
        expect(response).to redirect_to(root_path)
      end
    end

    context 'sig に含まれる uid のユーザーが存在しないとき' do
      it 'ルートへリダイレクトされること' do
        # 存在しない id で sig を作る
        fake_sig = Rails.application.message_verifier(:confirm_wait_access)
          .generate({ uid: 99_999_999, exp: 30.minutes.from_now.to_i }, purpose: :confirm_wait_access)

        get wait_for_confirmation_path(sig: fake_sig)
        expect(response).to redirect_to(root_path)
      end
    end
  end
  # POST /users（サインアップ後のリダイレクト先）
  describe 'POST /users（サインアップ）' do
    let(:valid_params) do
      {
        user: {
          last_name:             '山田',
          first_name:            '太郎',
          email:                 Faker::Internet.unique.email,
          password:              'password123',
          password_confirmation: 'password123'
        }
      }
    end

    it '未認証ユーザーが作成されること' do
      expect {
        post user_registration_path, params: valid_params
      }.to change(User, :count).by(1)
      expect(User.last.confirmed?).to eq(false)
    end

    it 'サインアップ直後は署名付き URL の確認待機画面にリダイレクトされること' do
      post user_registration_path, params: valid_params
      expect(response).to have_http_status(:redirect)
      # :id 直接は含まれない・sig クエリが含まれる
      expect(response.location).to match(%r{/users/confirm_wait\?sig=.+})
      expect(response.location).not_to match(%r{/users/confirm_wait/\d+})
    end
  end

  # PATCH /account/email・/account/password（メールアドレスとパスワードの変更）
  # 背景：成功の後の移り先が、無くしたルート（account_info_path）のままで NameError になっていた
  describe 'PATCH /account/email' do
    let(:user) { create(:user) }
    before { sign_in user }

    it '確認のメールを送り、プロフィールの画面へ移ること（再確認が済むまでメールアドレスは変わらない）' do
      old_email = user.email
      expect {
        patch account_email_path, params: { user: { email: "new-#{user.email}", current_password: "password123" } }
      }.to change { ActionMailer::Base.deliveries.size }.by(1)
      expect(response).to redirect_to(profile_path)
      expect(user.reload.unconfirmed_email).to eq("new-#{old_email}")
      expect(user.email).to eq(old_email)
    end

    it '現在のパスワードが違うときは、変更せずにフォームを表示し直すこと' do
      patch account_email_path, params: { user: { email: "new-#{user.email}", current_password: "wrong" } }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(user.reload.unconfirmed_email).to be_nil
    end
  end

  describe 'PATCH /account/password' do
    let(:user) { create(:user) }
    before { sign_in user }

    it 'パスワードを変え、ログインしたままプロフィールの画面へ移ること' do
      patch account_password_path, params: { user: { password: "newpass456", password_confirmation: "newpass456", current_password: "password123" } }
      expect(response).to redirect_to(profile_path)
      expect(user.reload.valid_password?("newpass456")).to eq(true)

      # パスワードを変えるとセッションが無効になるので、ログインし直していないと次の画面でログインを求められる
      get profile_path
      expect(response).to have_http_status(:ok)
    end

    it '現在のパスワードが違うときは、変更せずにフォームを表示し直すこと' do
      patch account_password_path, params: { user: { password: "newpass456", password_confirmation: "newpass456", current_password: "wrong" } }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(user.reload.valid_password?("password123")).to eq(true)
    end
  end
end

require 'rails_helper'
# ログイン成功 / 失敗
RSpec.describe 'ユーザーログイン', type: :system do
  before do
    driven_by(:rack_test)     # ブラウザを起動しない（JavaScript は動かないが速い）
    # JavaScript が要るテストなら :selenium_chrome_headless にする
  end

  let(:user) { create(:user, password: 'password123', password_confirmation: 'password123') }

  it 'メールとパスワードでログインできること' do
    visit new_user_session_path
    fill_in 'user[email]', with: user.email
    fill_in 'user[password]', with: 'password123'
    click_button 'ログイン'
    expect(page).to have_current_path(root_path)
  end

  it '誤った情報ではログインできないこと' do
    visit new_user_session_path
    fill_in 'user[email]', with: user.email
    fill_in 'user[password]', with: 'wrongpassword'   # わざと間違える
    click_button 'ログイン'

    expect(page).to have_current_path(new_user_session_path)
  end
end
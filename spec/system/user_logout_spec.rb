
require 'rails_helper'
# ログアウト
RSpec.describe 'ユーザーログアウト', type: :system do
  let(:user) { create(:user, password: 'password123', password_confirmation: 'password123') }

  before do
    driven_by(:rack_test)

    visit new_user_session_path
    fill_in 'user[email]', with: user.email
    fill_in 'user[password]', with: 'password123'
    click_button 'ログイン'
  end

  it 'ログアウトできること' do
    visit root_path
    click_link 'ログアウト'

    expect(page).to have_current_path(root_path)
  end
end
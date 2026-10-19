require 'rails_helper'
# フォロー / 解除
RSpec.describe 'フォロー機能', type: :system do
  let(:user) { create(:user, password: 'password123', password_confirmation: 'password123') }
  let(:other_user) { create(:user) }

  before do
    driven_by(:rack_test)

    visit new_user_session_path
    fill_in 'user[email]', with: user.email
    fill_in 'user[password]', with: 'password123'
    click_button 'ログイン'
  end

  it '他ユーザーをフォローできること' do
    visit user_path(other_user)
    click_button 'フォローする'

    expect(page).to have_button('フォローを解除する')
  end

  it 'フォロー解除できること' do
    user.follow(other_user)

    visit user_path(other_user)
    click_button 'フォローを解除する'

    expect(page).to have_button('フォローする')
  end
end
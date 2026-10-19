require 'rails_helper'
# 投稿作成 / 失敗
RSpec.describe '投稿機能', type: :system do
  let(:user) { create(:user, password: 'password123', password_confirmation: 'password123') }

  before do
    driven_by(:rack_test)

    visit new_user_session_path
    fill_in 'user[email]', with: user.email
    fill_in 'user[password]', with: 'password123'
    click_button 'ログイン'
  end

  it '投稿を作成できること' do
    visit root_path
    fill_in 'micropost[content]', with: 'システムスペックから投稿'
    click_button '投稿する'

    expect(page).to have_content('システムスペックから投稿')
  end

  it '空の投稿は作成できないこと' do
    visit root_path
    fill_in 'micropost[content]', with: ''
    click_button '投稿する'

    expect(page).not_to have_content('システムスペックから投稿')
  end

  # custom/image_upload.js は #micropost_image を探して、5MB を超える画像を送る前に止める
  it '画像の欄が、大きさを確かめる JavaScript の探す id になっていること' do
    visit root_path
    expect(page).to have_css('input[type="file"]#micropost_image')
  end
end

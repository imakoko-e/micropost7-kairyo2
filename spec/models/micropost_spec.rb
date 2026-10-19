require 'rails_helper'

RSpec.describe Micropost, type: :model do
  describe 'ファクトリ → テストデータが正しく作れるか？' do
    it '有効なファクトリを持つこと' do
      expect(build(:micropost)).to be_valid
    end
  end

  describe 'バリデーション → 保存前のチェックが機能しているか？' do
    it 'user_idがなければ無効であること' do
      micropost = build(:micropost, user_id: nil)
      expect(micropost.valid?).to eq false
    end

    it 'contentがなければ無効であること' do
      micropost = build(:micropost, content: nil)
      expect(micropost.valid?).to eq false
    end

    it 'contentが140文字以内であれば有効であること' do
      micropost = build(:micropost, content: "a" * 140)
      expect(micropost.valid?).to eq true
    end

    it 'contentが141文字以上であれば無効であること' do
      micropost = build(:micropost, content: "a" * 141)
      expect(micropost.valid?).to eq false
    end

  end

  describe '関連付け → ユーザーとの紐付けが正しいか？' do
    it 'ユーザーに属していること' do
      micropost = create(:micropost)
      expect(micropost.user).to be_a(User)     # .user でUserオブジェクトが取れる
      expect(micropost.user_id).to be_present   # user_id が入っている
    end
  end

  describe '画像バリデーション → 不正ファイルを弾けるか？' do
    it 'jpeg/gif/png 以外の形式は無効であること' do
      micropost = build(:micropost)
      micropost.image.attach(
        io:           StringIO.new("dummy content"),
        filename:     'test.txt',
        content_type: 'text/plain'
      )
      expect(micropost).not_to be_valid
      expect(micropost.errors[:image]).to be_present
    end

    it '5MB 以上の画像は無効であること' do
      micropost = build(:micropost)
      micropost.image.attach(
        io:           StringIO.new("a" * 6.megabytes),
        filename:     'big.jpg',
        content_type: 'image/jpeg'
      )
      expect(micropost).not_to be_valid
      expect(micropost.errors[:image]).to be_present
    end

    it '5MB 未満の jpeg 画像は有効であること' do
      micropost = build(:micropost)
      micropost.image.attach(
        io:           StringIO.new("a" * 100),
        filename:     'small.jpg',
        content_type: 'image/jpeg'
      )
      expect(micropost).to be_valid
    end
  end

  describe '並び順 → 新しい投稿が先に表示されるか？' do
    let(:user) { create(:user) }
    let!(:old_post) { create(:micropost, user: user, created_at: 1.day.ago) }
    let!(:new_post) { create(:micropost, user: user, created_at: Time.current) }

    it '新しい投稿が先に来ること（降順）' do
      expect(Micropost.first).to eq(new_post)
    end
  end
end
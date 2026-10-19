require 'rails_helper'

RSpec.describe Relationship, type: :model do
  describe 'バリデーション' do
    it 'follower_id が nil の場合、無効であること' do
      # テスト用の Relationship を作成（follower_id を nil にする）
      relationship = build(:relationship, follower_id: nil)
      # バリデーションが通らない（= 無効）ことを確認
      expect(relationship.valid?).to eq false
    end

    it 'followed_id が nil の場合、無効であること' do
      relationship = build(:relationship, followed_id: nil)
      expect(relationship.valid?).to eq false
    end
  end

  describe '関連付け' do
    it 'follower は User クラスに belongs_to で関連付けられていること' do

      relationship = create(:relationship)
      expect(relationship.follower).to be_a(User)
    end

    it 'followed は User クラスに belongs_to で関連付けられていること' do

      relationship = create(:relationship)
      expect(relationship.followed).to be_a(User)
    end

  end
end
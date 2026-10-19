require 'rails_helper'

RSpec.describe User, type: :model do
  # まず、ファクトリで有効なユーザーが作れることを確かめる
  describe 'ファクトリ' do
    it '有効なファクトリを持つこと' do
      user = build(:user)
      expect(user).to be_valid
    end
  end
  describe 'バリデーション' do
    it 'nameが空なら無効であること' do
      user = build(:user, last_name: nil, first_name: nil)
      # compose_name コールバックにより last_name + first_name → name になるので両方 nil にして name が空になる状態を作る
      expect(user.valid?).to eq false
    end
    it 'nameが50文字なら有効であること' do
      user = build(:user, last_name: 'あ' * 25, first_name: 'い' * 24)
      expect(user).to be_valid
    end

    it 'nameが51文字なら無効であること' do
      user = build(:user, last_name: 'あ' * 25, first_name: 'い' * 25)
      expect(user).not_to be_valid
      expect(user.errors[:name]).to include("は50文字以内で入力してください")
    end
  end
  describe '関連付け' do
    # ユーザーは複数のマイクロポストを持つこと
    it 'マイクロポストを複数持てること' do
      user = create(:user)
      # このユーザーに紐づくマイクロポストを2つ作成
      create(:micropost, user: user)
      create(:micropost, user: user)

      # user.microposts で投稿一覧が取得でき、2件あること
      expect(user.microposts.count).to eq(2)
    end

    it 'ユーザー削除時にマイクロポストも削除されること' do
      user = create(:user)
      create(:micropost, user: user)

      # ユーザーを削除すると、Micropost のレコード数が1つ減ること
      expect { user.destroy }.to change(Micropost, :count).by(-1)
    end
    # フォロー関係（active_relationships）
    it 'active_relationships を複数持てること' do
      user       = create(:user)
      other_user = create(:user)

      # user が other_user をフォローする → Relationship レコードが作られる
      user.follow(other_user)

      # user の active_relationships（自分がフォローしている関係）が1件あること
      expect(user.active_relationships.count).to eq(1)
      # Relationship テーブルのレコードであること
      expect(user.active_relationships.first).to be_a(Relationship)
    end

    it 'ユーザー削除時に active_relationships も削除されること' do
      user       = create(:user)
      other_user = create(:user)
      user.follow(other_user)

      expect { user.destroy }.to change(Relationship, :count).by(-1)
    end
    # 被フォロー関係（passive_relationships）
    it 'passive_relationships を複数持てること' do
      user       = create(:user)
      other_user = create(:user)

      # other_user が user をフォロー → user 側に passive_relationship ができる
      other_user.follow(user)

      expect(user.passive_relationships.count).to eq(1)
      expect(user.passive_relationships.first).to be_a(Relationship)
    end

    it 'ユーザー削除時に passive_relationships も削除されること' do
      user       = create(:user)
      other_user = create(:user)
      other_user.follow(user)

      expect { user.destroy }.to change(Relationship, :count).by(-1)
    end
    # following（フォロー中のユーザー一覧）
    it 'following でフォロー中のユーザーを取得できること' do
      user  = create(:user)
      alice = create(:user)
      bob   = create(:user)

      user.follow(alice)
      user.follow(bob)

      # user.following に alice と bob が含まれること
      expect(user.following).to include(alice, bob)
      # following の各要素は User オブジェクトであること
      expect(user.following.first).to be_a(User)
    end
    # followers（フォロワー一覧）
    it 'followers でフォロワーを取得できること' do
      user  = create(:user)
      alice = create(:user)
      bob   = create(:user)

      alice.follow(user)
      bob.follow(user)

      # user.followers に alice と bob が含まれること
      expect(user.followers).to include(alice, bob)
      expect(user.followers.first).to be_a(User)
    end
  end
  describe '#downcase_email' do
    it 'メールアドレスが小文字で保存されること' do
      user = create(:user, email: 'TEST@Example.COM')
      expect(user.reload.email).to eq('test@example.com')
    end
  end

  describe '#compose_name' do
    it '姓と名が結合されて name に設定されること' do
      user = build(:user, last_name: '山田', first_name: '太郎')
      user.valid?
      expect(user.name).to eq('山田 太郎')
    end
  end

  describe '#compose_name_kana' do
    it '姓カナと名カナが結合されて name_kana に設定されること' do
      user = build(:user, last_name_kana: 'ヤマダ', first_name_kana: 'タロウ')
      user.valid?
      expect(user.name_kana).to eq('ヤマダ タロウ')
    end

    it '姓カナまたは名カナが空の場合、name_kana は更新されないこと' do
      user = build(:user, last_name_kana: nil, first_name_kana: 'タロウ')
      user.valid?
      # 片方しかない場合は compose_name_kana が動作しないため blank のまま
      expect(user.name_kana).to be_blank
    end
  end

  describe '#compose_birthday' do
    it '年月日がそろっている場合、birthday に Date が設定されること' do
      user = build(:user, year_of_birth: 1990, month_of_birth: 4, day_of_birth: 1)
      user.valid?
      expect(user.birthday).to eq(Date.new(1990, 4, 1))
    end

    it '不正な日付（2月30日など）の場合、birthday が nil になること' do
      user = build(:user, year_of_birth: 2000, month_of_birth: 2, day_of_birth: 30)
      user.valid?
      expect(user.birthday).to be_nil
    end

    it '年月日のいずれかが空の場合、birthday は更新されないこと' do
      user = build(:user, year_of_birth: 1990, month_of_birth: nil, day_of_birth: 1)
      user.valid?
      expect(user.birthday).to be_nil
    end
  end

  describe '#compose_address' do
    it '都道府県・市区町村・町名・番地がそろっている場合、address に設定されること' do
      user = build(:user,
        prefecture:   '東京都',
        city:         '渋谷区',
        street_name:  '道玄坂',
        house_number: '1-1')
      user.valid?
      expect(user.address).to include('東京都', '渋谷区', '道玄坂', '1-1')
    end

    it '必須項目のいずれかが空の場合、address は更新されないこと' do
      user = build(:user, prefecture: '東京都', city: nil, street_name: '道玄坂', house_number: '1-1')
      user.valid?
      expect(user.address).to be_nil
    end
  end
  describe '#follow / #unfollow / #following?' do
    let(:user)       { create(:user) }
    let(:other_user) { create(:user) }

    it 'ユーザーをフォローできること' do
      user.follow(other_user)
      expect(user).to be_following(other_user)
    end

    it 'ユーザーをフォロー解除できること' do
      user.follow(other_user)
      user.unfollow(other_user)
      expect(user).not_to be_following(other_user)
    end

    # follow メソッドに unless self == other_user があるため、自己フォローは無効
    it '自分自身をフォローできないこと' do
      user.follow(user)
      expect(user).not_to be_following(user)
    end

    it 'フォローしているユーザーに対して following? が true を返すこと' do
      user.follow(other_user)
      expect(user.following?(other_user)).to eq true
    end

    it 'フォローしていないユーザーに対して following? が false を返すこと' do
      expect(user.following?(other_user)).to eq false
    end
  end

  describe '#feed' do
    let(:user)           { create(:user) }
    let(:followed_user)  { create(:user) }
    let(:unfollowed_user) { create(:user) }

    before do
      user.follow(followed_user)
      create(:micropost, user: user)
      create(:micropost, user: followed_user)
      create(:micropost, user: unfollowed_user)
    end

    it 'フォロー中ユーザーの投稿を含むこと' do
      followed_user.microposts.each do |post|
        expect(user.feed).to include(post)
      end
    end

    it '自分自身の投稿を含むこと' do
      user.microposts.each do |post|
        expect(user.feed).to include(post)
      end
    end

    it 'フォローしていないユーザーの投稿を含まないこと' do
      unfollowed_user.microposts.each do |post|
        expect(user.feed).not_to include(post)
      end
    end
  end
end
class User < ApplicationRecord
  # Devise の機能。メールの確認・ログイン履歴・自動ログアウト・ロック・Google ログインを使う
  devise :database_authenticatable, :registerable,
       :recoverable, :rememberable, :validatable,
       :confirmable, :trackable,
       :timeoutable, :lockable,
       :omniauthable, omniauth_providers: [:google_oauth2]

  # ユーザーを消すと、投稿も一緒に消す
  has_many :microposts, dependent: :destroy

  # 自分がフォローしている関係（能動的関係）
  has_many :active_relationships,
              class_name:  "Relationship",
              foreign_key: "follower_id",
              dependent:   :destroy
  # following の元（source）は followed_id の集まり
  has_many :following, through: :active_relationships, source: :followed

  # 自分がフォローされている関係（受動的関係）
  has_many :passive_relationships,
              class_name:  "Relationship",
              foreign_key: "followed_id",
              dependent:   :destroy
  has_many :followers, through: :passive_relationships, source: :follower

  before_save   :downcase_email
  # 姓・名などの入力欄から、保存する項目（氏名・生年月日・住所）を組み立ててから検証する
  before_validation :compose_name
  before_validation :compose_name_kana
  before_validation :compose_birthday
  before_validation :compose_address

  # email の形式は Devise の validatable が確かめる
  validates :name, presence: true, length: { maximum: 50 }

  # 自分とフォローしている人の投稿（フィード）
  # 投稿者と画像を先に読み込み、一覧で N+1 のクエリが起きないようにする
  def feed
    following_ids = "SELECT followed_id FROM relationships WHERE follower_id = :user_id"
    Micropost.where("user_id IN (#{following_ids})
                    OR user_id = :user_id", user_id: id)
            .includes(:user, image_attachment: :blob)
  end

  # ユーザーをフォローする（自分自身はフォローしない）
  def follow(other_user)
    following << other_user unless self == other_user
  end

  # フォローを解除する
  def unfollow(other_user)
    following.delete(other_user)
  end

  # other_user をフォローしていれば true
  def following?(other_user)
    following.include?(other_user)
  end

  # Google から受け取った情報でユーザーを探し、無ければ作る
  # （omniauth_callbacks_controller.rb から呼ぶ）
  def self.from_google_omniauth(auth)
    # Google 側でメールアドレスを確認済みのときだけ受け付ける
    return nil unless auth.info.email_verified

    user = find_or_initialize_by(email: auth.info.email)
    user.email = auth.info.email
    user.password = Devise.friendly_token[0,20]
    user.provider = auth.provider
    user.uid = auth.uid
    user.name = auth.info.name              # フルネーム
    user.first_name = auth.info.first_name  # 下の名前
    user.last_name = auth.info.last_name    # 苗字
    user.save!
    # Google で確認済みなので、Devise のメール確認を省く
    user.skip_confirmation! if user.respond_to?(:skip_confirmation!)
    return user
  end

  private

  def downcase_email
    # self を付けないと、ローカル変数への代入になる
    self.email = email.downcase
  end

  # 姓と名から氏名を作る（"姓 名"）
  def compose_name
    if last_name.present? && first_name.present?
      self.name = [last_name, first_name].join(' ')
    end
  end

  # 姓カナと名カナから氏名カナを作る
  def compose_name_kana
    if last_name_kana.present? && first_name_kana.present?
      self.name_kana = [last_name_kana, first_name_kana].join(' ')
    end
  end

  # 年・月・日がそろっていれば、生年月日（Date）を作る
  def compose_birthday
    if year_of_birth.present? && month_of_birth.present? && day_of_birth.present?
      begin
        self.birthday = Date.new(year_of_birth.to_i, month_of_birth.to_i, day_of_birth.to_i)
      rescue ArgumentError
        # 2月30日のような、ありえない日付
        self.birthday = nil
      end
    end
  end

  # 住所の各要素から address を作る（"都道府県市区町村町名番地 建物名 部屋番号"）
  def compose_address
    if prefecture.present? && city.present? && street_name.present? && house_number.present?
      address01 = [prefecture, city, street_name,house_number].join
      self.address = [address01, building_name,apartment_number].compact.join(' ')
    end
  end
end

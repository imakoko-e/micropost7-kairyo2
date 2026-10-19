# 目的: サンプルユーザー作成時に「清音キー」も同時に保存
Faker::Config.locale = :ja

# 建物名のサンプル
J_BUILDINGS = %w[
  サクラハイツ グリーンコーポ 青山マンション
  ライオンズタワー サンシャインビル スカイコート
  パークハウス ヒルズレジデンス ハイツカトレア
  コーポさくら
]
# 趣味のサンプル
J_HOBBIES = %w[
  読書 映画鑑賞 音楽鑑賞 料理 カメラ 園芸 ジョギング
  サイクリング 旅行 キャンプ ハイキング 釣り ゲーム
  プログラミング カフェ巡り 美術館巡り 手芸 イラスト
  筋トレ ヨガ ダンス
  登山 ランニング 卓球 サッカー 野球 バスケットボール
  テニス バドミントン 将棋 囲碁 麻雀 カラオケ
  ボードゲーム コスプレ 写真撮影 鉄道旅行 温泉巡り
  食べ歩き ボランティア 語学学習 DIY
]
# 特技のサンプル
J_SKILLS = %w[
  プレゼンテーション 文章作成 企画立案 データ分析 顧客対応
  リーダーシップ チームビルディング 調整力 問題解決力
  情報収集力 英会話 PC操作 Excel活用 SQL Ruby on Rails
  Docker Linux Git
  JavaScript HTML CSS React Vue.js
  Python Java PHP Swift Kotlin
  ネットワーク設計 セキュリティ テスト設計 UIデザイン
  プロジェクト管理 ファシリテーション 交渉力
]

# --- 管理者ユーザーを1人作成 ---
User.create!(
  email: "admin@rails.org",
  password:              "foobar",
  password_confirmation: "foobar",
  admin:     true,

  last_name: "管理",     # 姓
  first_name: "太郎",    # 名
  name: "管理 太郎",      # 氏名（姓＋名を半角スペースでつなぐ）
  last_name_kana: "カンリ",
  first_name_kana: "タロウ",
  name_kana: "カンリ タロウ",
  name_kana_seion: "カンリ タロウ",
  gender: 1,
  confirmed_at: Time.zone.now
)

# --- 一般ユーザーを49人作成 ---
49.times do |n|
  email = "test-#{n+1}@rails.org"
  password = "password"
  # --- 氏名とカナ ---
  name = Gimei.name
  last_name = name.last.kanji       # 姓
  first_name = name.first.kanji     # 名
  full_name = "#{last_name} #{first_name}"    # 氏名（姓＋名を半角スペースでつなぐ）
  last_name_kana  = name.last.katakana
  first_name_kana = name.first.katakana
  name_kana       = "#{last_name_kana} #{first_name_kana}"

  n_last_name_kana = KanaUtils.seion(last_name_kana) if last_name_kana.present?
  n_first_name_kana = KanaUtils.seion(first_name_kana) if first_name_kana.present?
  name_kana_seion = KanaUtils.seion_concat(n_last_name_kana,n_first_name_kana)      # 清音処理済みのカナの結合

  # --- 性別（0=未設定,1=男性,2=女性 と仮定）---
  gender = name.male? ? 1 : (name.female? ? 2 : 0)    #ネストした三項演算子

  User.create!(
    email: email,
    password:              password,
    password_confirmation: password,

    last_name: last_name,
    first_name: first_name,
    name:  full_name,
    last_name_kana: last_name_kana,
    first_name_kana: first_name_kana,
    name_kana: name_kana,
    name_kana_seion: name_kana_seion,
    gender: gender,
    confirmed_at: Time.zone.now
  )
end
# --- 作成済みユーザーに追加情報を埋める ---
User.find_each do |user|
  # --- 生年月日 ---
  birthday = Faker::Date.birthday(min_age: 18, max_age: 80)

  # 電話（string）
  mobile_phone = "090#{Faker::Number.number(digits: 8)}" # 例: 090-xxxx-xxxx
  fixed_phone  = "03#{Faker::Number.number(digits: 8)}"  # 例: 03-xxxx-xxxx
  phone        = fixed_phone

  # 郵便番号（gimei には無いので 7桁ダミーを文字列で）
  postal_code = "%07d" % Faker::Number.number(digits: 7)

  # 住所（gimei）＋ 建物や部屋番号は Faker で補完
  addr = Gimei.address
  prefecture       = addr.prefecture.kanji # 都道府県
  city             = addr.city.kanji       # 市区町村
  street_name      = addr.town.kanji       # 町名
  house_number = rand(101..9999).to_s       # 番地
  if [true, false].sample     # ランダムにセットする
    # 両方セットする場合
    building_name   = J_BUILDINGS.sample
    apartment_number = "#{Faker::Number.number(digits: 3)}号室"
  else
    # 両方とも空白にする場合
    building_name   = ""
    apartment_number = ""
  end
  address = "#{prefecture} #{city} #{street_name} #{house_number} #{building_name} #{apartment_number}"

  # --- 趣味・特技 ---
  # 1～3個ランダムに選ぶ
  hobbies        = J_HOBBIES.sample(rand(1..3)).join("、")
  special_skills = J_SKILLS.sample(rand(1..3)).join("、")
  # --- 備考 ---
  note = Faker::Lorem.sentence(word_count: 10)

  # 追加情報を更新
  user.update!(
    birthday: birthday,
    year_of_birth: birthday.year,
    month_of_birth: birthday.month,
    day_of_birth: birthday.day,
    phone: phone,
    fixed_phone: fixed_phone,
    mobile_phone: mobile_phone,
    address: address,
    postal_code: postal_code,
    prefecture: prefecture,
    city: city,
    street_name: street_name,
    house_number: house_number,
    building_name: building_name,
    apartment_number: apartment_number,
    hobbies: hobbies,
    special_skills: special_skills,
    note: note
  )
end

# ユーザーの一部を対象にマイクロポストを生成する
users = User.order(:created_at).take(6)
30.times do
  content = Faker::Lorem.sentence(word_count: 8)
  users.each { |user| user.microposts.create!(content: content) }
end

# ユーザーフォローのリレーションシップを作成する
users = User.all
user  = users.first
following = users[2..50]
followers = users[3..40]
following.each { |followed| user.follow(followed) }
followers.each { |follower| follower.follow(user) }

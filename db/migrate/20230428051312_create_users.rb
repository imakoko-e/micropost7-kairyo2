class CreateUsers < ActiveRecord::Migration[7.0]
  def change
    create_table :users do |t|
      t.string :email, null: false, default: ""
      # -----------------------------------------
      # t.string :password_digest
      # :remember_digest
      t.boolean :admin, default: false
      # t.string :activation_digest, :string
      # t.boolean :activated, default: false
      # t.datetime :activated_at
      # t.string :reset_digest
      # t.datetime :reset_sent_at
      # -----------------------------------------
      t.string :name, default: "", null: false          # 氏名
      t.string :last_name, default: "", null: false     # 姓
      t.string :first_name, default: "", null: false    # 名
      t.string :name_kana, default: ""            # 氏名カナ
      t.string :name_kana_seion, default: ""      # 氏名カナ清音
      t.string :last_name_kana, default: ""       # 姓カナ
      t.string :first_name_kana, default: ""      # 名カナ
      t.integer :gender, default: 0, null: false    # 性別
      t.date :birthday            # 生年月日
      t.integer :year_of_birth    # 誕生年
      t.integer :month_of_birth   # 誕生月
      t.integer :day_of_birth     # 誕生日
      t.string :phone             # 電話番号
      t.string :fixed_phone       # 固定電話
      t.string :mobile_phone      # 携帯電話
      t.string :address           # 住所
      t.string :postal_code       # 郵便番号
      t.string :prefecture        # 都道府県
      t.string :city              # 市区町村
      t.string :street_name       # 町名
      t.string :house_number      # 番地
      t.string :building_name     # 建物名
      t.string :apartment_number  # 部屋番号
      t.string :hobbies           # 趣味
      t.string :special_skills    # 特技
      t.text :note                # 備考
      # -----------------------------------------

      # -----------------------------------------
      t.timestamps null: false
    end
    add_index :users, :email, unique: true
    add_index :users, :name_kana_seion
  end
end

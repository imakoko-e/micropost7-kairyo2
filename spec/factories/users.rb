FactoryBot.define do
  factory :user do
    last_name  { "テスト" }
    first_name { "太郎" }
    email      { Faker::Internet.unique.email }
    password   { "password123" }
    password_confirmation { "password123" }

    # Devise confirmable 対応：メール確認済みにする
    confirmed_at { Time.current }

    trait :admin do
      admin { true }
    end

    trait :unconfirmed do
      confirmed_at { nil }
    end

  end
end

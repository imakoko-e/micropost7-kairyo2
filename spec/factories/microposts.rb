FactoryBot.define do
  factory :micropost do
    content { Faker::Lorem.sentence(word_count: 5) }
    user { create(:user) }    # user_id取得のため、保存済みuserとする
  end
end
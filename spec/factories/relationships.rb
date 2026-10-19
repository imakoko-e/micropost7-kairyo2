FactoryBot.define do
  factory :relationship do
    # follower・followed とも :user ファクトリで作る（どちらも belongs_to で User を指す）
    association :follower, factory: :user
    association :followed, factory: :user
  end
end
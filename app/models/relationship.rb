class Relationship < ApplicationRecord
  # follower_id・followed_id の外部キーで、どちらも User を指す
  belongs_to :follower, class_name: "User"
  belongs_to :followed, class_name: "User"

  validates :follower_id, presence: true
  validates :followed_id, presence: true
end

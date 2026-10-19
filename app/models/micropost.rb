class Micropost < ApplicationRecord
  belongs_to :user

  # 画像は1件。表示用に 300×300 以内へ縮めた版（:display）を持つ
  has_one_attached :image do |attachable|
    attachable.variant :display, resize_to_limit: [300, 300]
  end

  # 新しい投稿から順に並べる
  default_scope -> { order(created_at: :desc) }

  validates :user_id, presence: true
  validates :content, presence: true, length: { maximum: 140 }
  # 画像の形式と大きさ（gem active_storage_validations）
  validates :image, content_type: { in: %w[image/jpeg image/gif image/png],
                                    message: "有効な画像形式（ jpeg,gif,png ）ではありません。" },
                    size:         { less_than: 5.megabytes,
                                    message: "5MB未満にしてください。" }
end

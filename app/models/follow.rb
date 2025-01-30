class Follow < ApplicationRecord
  belongs_to :follower, class_name: "User"
  belongs_to :followed, class_name: "User"

  validates :follower_id, presence: true
  validates :followed_id, presence: true
  validate :cannot_follow_self

  private

  def cannot_follow_self
    if follower_id == followed_id
      errors.add(:base, "自分自身をフォローすることはできません")
    end
  end
end

class User < ApplicationRecord
  has_many :journals, dependent: :destroy
  has_one :spotify_token, dependent: :destroy
  has_one_attached :avatar
  has_one :profile
  # Deviseのモジュール
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  # バリデーション
  validates :name, presence: true, length: { maximum: 50 }
end

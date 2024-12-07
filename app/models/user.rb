class User < ApplicationRecord
  # Deviseのモジュール
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  # バリデーション
  validates :name, presence: true, length: { maximum: 50 }
end

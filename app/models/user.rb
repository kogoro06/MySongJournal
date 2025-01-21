class User < ApplicationRecord
  has_many :journals, dependent: :destroy
  has_one :spotify_token, dependent: :destroy
  # Deviseのモジュール
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  # バリデーション
  validates :name, presence: true, length: { maximum: 50 }
  # roleカラムの型を明示的に定義
  attribute :role, :integer, default: 0

  # enumの定義
  enum role: { general: 0, admin: 1 }

  # 管理者かどうかを判定するメソッド
  def admin?
    role == "admin"
  end
end

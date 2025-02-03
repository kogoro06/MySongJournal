class User < ApplicationRecord
  has_many :journals, dependent: :destroy
  has_one :spotify_token, dependent: :destroy
  has_one_attached :avatar
  has_one :profile
  # Deviseのモジュール
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :omniauthable, omniauth_providers: [ :google_oauth2 ]
  # バリデーション
  validates :name, presence: true, length: { maximum: 50 }
  validates :email, presence: true, uniqueness: true
  validates :password, presence: true, length: { minimum: 6 }
  validates :uid, uniqueness: { scope: :provider }, if: -> { uid.present? }
  validates :x_link, format: { with: /\A(https?:\/\/)?(www\.)?twitter\.com\/.*\z|\A(https?:\/\/)?(www\.)?x\.com\/.*\z/i, message: "正しいXのURLを入力してください" }, allow_blank: true

  # favorites の関連
  has_many :favorites, dependent: :destroy
  has_many :liked_journals, through: :favorites, source: :journal

  # フォローしている関連
  has_many :active_follows, class_name: "Follow", foreign_key: "follower_id", dependent: :destroy
  has_many :following, through: :active_follows, source: :followed

  # フォローされている関連
  has_many :passive_follows, class_name: "Follow", foreign_key: "followed_id", dependent: :destroy
  has_many :followers, through: :passive_follows, source: :follower

  # フォロー関連のメソッド
  def follow(other_user)
    following << other_user unless self == other_user
  end

  def unfollow(other_user)
    following.delete(other_user)
  end

  def following?(other_user)
    following.include?(other_user)
  end

  def self.from_omniauth(auth)
    # まず、OAuth認証情報で検索
    user = find_by(provider: auth.provider, uid: auth.uid)

    # 見つからない場合、メールアドレスで検索
    user ||= find_by(email: auth.info.email)

    if user
      # 既存ユーザーの場合、OAuth情報を更新
      user.update(
        uid: auth.uid,
        provider: auth.provider
      ) unless user.provider == auth.provider && user.uid == auth.uid
    else
      # 新規ユーザーを作成
      user = new(
        email: auth.info.email,
        name: auth.info.name || auth.info.email.split("@").first,
        password: Devise.friendly_token[0, 20],
        provider: auth.provider,
        uid: auth.uid
      )
    end

    unless user.save
      Rails.logger.error "User save failed: #{user.errors.full_messages.join(', ')}"
    end

    user
  end
  def self.create_unique_string
    SecureRandom.uuid
  end

  before_save :format_x_link

  def safe_x_link
    return nil if x_link.blank?

    uri = URI.parse(x_link)
    return nil unless [ "http", "https" ].include?(uri.scheme)
    return nil unless [ "twitter.com", "x.com" ].include?(uri.host&.sub(/\Awww\./, ""))

    ERB::Util.html_escape(x_link)
  rescue URI::InvalidURIError
    nil
  end

  private

  def format_x_link
    return if x_link.blank?

    unless x_link.start_with?("http://", "https://")
      self.x_link = "https://#{x_link}"
    end
  end
end

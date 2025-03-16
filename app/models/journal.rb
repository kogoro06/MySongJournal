class Journal < ApplicationRecord
  extend FriendlyId

  # スラグの生成ルールを設定
  friendly_id :slug_candidates, use: [ :slugged, :history ]

  belongs_to :user
  has_many :favorites, dependent: :destroy
  has_many :favorited_users, through: :favorites, source: :user

  # バリデーション
  validates :title, presence: { message: "日記のタイトルを入力してください" }, length: { maximum: 30, message: "タイトルは30文字以内で入力してください" }
  validates :content, presence: { message: "日記の本文を入力してください" }, length: { maximum: 500, message: "内容は500文字以内で入力してください" }
  validates :emotion, presence: { message: "本日の気持ちを選んでください" }
  validates :song_name, presence: { message: "本日の1曲を選んでください" }, length: { maximum: 100, message: "曲名は100文字以内で入力してください" }
  validates :genre, presence: { message: "音楽のジャンルを選んでください" }

  # 列挙型
  enum genre: {
    j_pop: "j-pop",
    k_pop: "k-pop",
    western: "western",
    anime: "anime",
    vocaloid: "vocaloid",
    others: "others"
  }

  enum emotion: [ :喜, :怒, :哀, :楽 ]

  # ジャンルの表示名と値のマッピング
  MAIN_GENRES = {
    "j-pop" => "J-POP",
    "k-pop" => "K-POP",
    "western" => "洋楽",
    "anime" => "アニメ/特撮",
    "vocaloid" => "ボーカロイド",
    "others" => "その他"
  }.freeze

  # スコープ定義
  scope :by_emotion, ->(emotion) { where(emotion: emotion) if emotion.present? }
  scope :by_genre, ->(genre) { where(genre: genre) if genre.present? }

  def favorited_by?(user)
    return false if user.nil?
    @user_favorites ||= favorites.pluck(:user_id)
    @user_favorites.include?(user.id)
  end

  def genre_display_name
    MAIN_GENRES[genre] || MAIN_GENRES["others"]
  end

  private

  def slug_candidates
    [
      # 曲名とアーティスト名と作成時刻を含むスラグ
      "#{song_name}-#{artist_name}-#{time_suffix}",
      # 曲名と作成時刻を含むスラグ
      "#{song_name}-#{time_suffix}",
      # デフォルトのスラグ
      time_suffix
    ].map { |slug| normalize_slug(slug) }
  end

  def normalize_slug(text)
    return nil if text.blank?
    # 日本語を含むテキストを正規化
    text.to_s
        .strip
        .gsub(/\s+/, "-")
        .gsub(/[^\p{Han}\p{Hiragana}\p{Katakana}A-Za-z0-9\-]/, "")
        .gsub(/-+/, "-")
  end

  def time_suffix
    time = (created_at || Time.current).in_time_zone("Asia/Tokyo")
    timestamp = time.strftime("%Y%m%d%H%M%S")
    "mysongjournal-#{timestamp}"
  end

  def should_generate_new_friendly_id?
    slug.blank? || song_name_changed? || artist_name_changed? || saved_change_to_created_at?
  end
end

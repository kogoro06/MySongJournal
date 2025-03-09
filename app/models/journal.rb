class Journal < ApplicationRecord
  extend FriendlyId

  # スラグの生成ルールを設定
  friendly_id :slug_candidates, use: :slugged

  belongs_to :user
  has_many :favorites, dependent: :destroy
  has_many :favorited_users, through: :favorites, source: :user

  # バリデーション
  validates :title, presence: { message: "日記のタイトルを入力してください" }, length: { maximum: 20, message: "タイトルは20文字以内で入力してください" }
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
    favorites.exists?(user_id: user.id)
  end

  def genre_display_name
    MAIN_GENRES[genre] || MAIN_GENRES["others"]
  end

  private

  def slug_candidates
    [
      # 曲名とアーティスト名が両方ある場合
      [ :song_name, :artist_name, :generated_suffix ],
      # 曲名のみの場合
      [ :song_name, :generated_suffix ],
      # どちらもない場合
      [ :generated_suffix ]
    ]
  end

  def normalized_song_name
    return nil if song_name.blank?
    # 日本語はそのまま使用し、空白はハイフンに
    song_name.strip.gsub(/\s+/, "-")
  end

  def normalized_artist_name
    return nil if artist_name.blank?
    # 日本語はそのまま使用し、空白はハイフンに
    artist_name.strip.gsub(/\s+/, "-")
  end

  def generated_suffix
    date_str = created_at&.strftime("%Y%m%d") || Time.current.strftime("%Y%m%d")
    "mysongjournal-#{date_str}"
  end

  def should_generate_new_friendly_id?
    slug.blank? || song_name_changed? || artist_name_changed? || saved_change_to_created_at?
  end
end

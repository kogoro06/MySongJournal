class Journal < ApplicationRecord
  belongs_to :user
  enum emotion: { 喜: 0, 怒: 1, 哀: 2, 楽: 3 }
  validates :title, presence: true, length: { maximum: 50 } # 必須、最大50文字
  validates :content, presence: true, length: { maximum: 500 } # 必須、最大500文字
  validates :emotion, presence: true # 必須
  validates :song_name, presence: true, length: { maximum: 100 }
  validates :artist_name, presence: true, length: { maximum: 100 }
  validates :album_image, presence: true, format: { with: URI.regexp(%w[http https]), message: "must be a valid URL" }
  validates :preview_url, format: { with: URI.regexp(%w[http https]), message: "must be a valid URL" }, allow_blank: true
  has_many :favorites, dependent: :destroy
  has_many :favorited_users, through: :favorites, source: :user

  def favorited_by?(user)
    favorites.exists?(user_id: user.id)
  end

  # 感情での絞り込み
  scope :by_emotion, ->(emotion) { where(emotion: emotion) if emotion.present? }

  # 主要なジャンルの定義
  MAIN_GENRES = {
    'j-pop' => 'J-POP',
    'k-pop' => 'K-POP',
    'western' => '洋楽',
    'anime' => 'アニメ/特撮',
    'idol' => 'アイドル/ボーカロイド',
    'others' => 'その他'
  }.freeze

  # Spotifyのジャンルタグをメインジャンルにマッピング
  GENRE_MAPPING = {
    # J-POP
    'j-pop' => 'j-pop',
    'j-rock' => 'j-pop',
    'japanese indie' => 'j-pop',
    'japanese singer-songwriter' => 'j-pop',
    
    # K-POP
    'k-pop' => 'k-pop',
    'k-rap' => 'k-pop',
    'korean pop' => 'k-pop',
    
    # 洋楽
    'pop' => 'western',
    'rock' => 'western',
    'rap' => 'western',
    'r&b' => 'western',
    'hip hop' => 'western',
    
    # アニメ/特撮
    'anime' => 'anime',
    'game' => 'anime',
    'soundtrack' => 'anime',
    
    # アイドル/ボーカロイド
    'idol' => 'idol',
    'vocaloid' => 'idol',
    'jpop idol' => 'idol'
  }.freeze

  # ジャンルでの絞り込み
  scope :by_genre, ->(genre) { where(genre: genre) if genre.present? }
  
  # Spotifyのジャンルを主要ジャンルに変換
  def categorize_genre(spotify_genres)
    return 'others' if spotify_genres.blank?
    
    spotify_genres.each do |genre|
      GENRE_MAPPING.each do |pattern, main_genre|
        return main_genre if genre.include?(pattern)
      end
    end
    
    'others'
  end

  # 曲情報保存時にジャンルも保存
  def fetch_and_save_genre
    return unless spotify_track_id.present?
    
    begin
      token = SpotifyToken.last
      # アーティスト情報を取得
      track_response = RestClient.get(
        "https://api.spotify.com/v1/tracks/#{spotify_track_id}",
        { 
          Authorization: "Bearer #{token.access_token}",
          accept: 'application/json'
        }
      )
      track = JSON.parse(track_response.body)
      
      artist_response = RestClient.get(
        "https://api.spotify.com/v1/artists/#{track['artists'].first['id']}",
        { 
          Authorization: "Bearer #{token.access_token}",
          accept: 'application/json'
        }
      )
      artist_info = JSON.parse(artist_response.body)
      
      # ジャンルを分類して保存
      main_genre = categorize_genre(artist_info['genres'])
      update(genre: main_genre)
    rescue => e
      Rails.logger.error "Error fetching genre: #{e.message}"
    end
  end

  # 表示用のジャンル名を取得
  def genre_display_name
    MAIN_GENRES[genre] || 'その他'
  end
end

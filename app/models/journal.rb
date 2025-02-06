class Journal < ApplicationRecord
  extend FriendlyId
  friendly_id :slug_candidates, use: :slugged

  belongs_to :user
  has_many :favorites, dependent: :destroy
  has_many :favorited_users, through: :favorites, source: :user

  # バリデーション
  validates :title, presence: true, length: { maximum: 20 } # 必須、最大20文字
  validates :content, presence: true, length: { maximum: 500 } # 必須、最大500文字
  validates :emotion, presence: true # 必須
  validates :song_name, presence: true, length: { maximum: 100 }
  validates :artist_name, presence: true, length: { maximum: 100 }
  validates :album_image, presence: true, format: { with: URI.regexp(%w[http https]), message: "must be a valid URL" }
  validates :genre, presence: true # 必須

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

  # ジャンルの表示名
  def genre_display_name
    MAIN_GENRES[genre] || MAIN_GENRES["others"]
  end

  # 既存のジャンルを新しい体系に移行
  def self.migrate_genres
    find_each do |journal|
      next if journal.genre.blank?

      # 現在のジャンルに基づいて新しいジャンルを設定
      new_genre = case journal.genre.downcase
      when "j-pop", "jpop", "japanese" then "j-pop"
      when "k-pop", "kpop", "korean" then "k-pop"
      when "western", "pop", "rock", "jazz", "classical" then "western"
      when "anime", "tokusatsu", "game" then "anime"
      when "vocaloid" then "vocaloid"
      else "others"
      end

      # 新しいジャンルを設定して保存
      journal.update_column(:genre, new_genre)
    end

    # 移行結果を表示
    puts "\n=== ジャンル移行結果 ==="
    group(:genre).count.each do |genre, count|
      puts "#{MAIN_GENRES[genre]}: #{count}件"
    end
  end

  private

  def slug_candidates
    [
      :title,
      [ :title, :artist_name ],
      [ :title, :artist_name, -> { (created_at || Time.current).strftime("%Y%m%d") } ]
    ]
  end

  def should_generate_new_friendly_id?
    title_changed? || artist_name_changed? || super
  end

  def set_genre_from_spotify
    return if spotify_track_id.blank?
    return if genre.present? # ユーザーが既にジャンルを設定している場合は自動設定をスキップ

    # アーティスト名とタイトルからアニメ/特撮かどうかを判定
    title_based_genre = determine_genre_from_title
    if title_based_genre == "anime"
      self.genre = "anime"
      return
    end

    # アニメ/特撮でない場合はnilのままにして、ユーザーに選択してもらう
    self.genre = nil
  end

  def determine_genre_from_title
    artist_name_lower = artist_name.to_s.downcase
    song_name_lower = song_name.to_s.downcase

    # アニメ/特撮関連の判定
    if artist_name_lower =~ /(?:仮面ライダー|スーパー戦隊|戦隊|ウルトラマン|プリキュア|特撮|アニメ|disney|ディズニー|ジブリ|pixar|ピクサー)/ ||
       song_name_lower =~ /(?:仮面ライダー|スーパー戦隊|戦隊|ウルトラマン|プリキュア|特撮|アニメ|disney|ディズニー)/ ||
       artist_name_lower =~ /(?:山寺宏一|水木一郎|堀江美都子|ささきいさお|串田アキラ|影山ヒロノブ|池田直樹|遠藤正明|宮内タカユキ|高橋秀幸|松本梨香|林原めぐみ|水樹奈々|田村ゆかり|堀江由衣|中川翔子|JAM Project|きただにひろし|米倉千尋|奥井雅美|鮎川麻弥|堀江晶太|岡崎律子|GRANRODEO|angela|fripSide|May\'n|藍井エイル|LiSA|ClariS|小倉唯|沢城みゆき|花澤香菜|戸松遥|相川七瀬.*仮面ライダー|アラン.*メンケン)/
      "anime"
    else
      nil
    end
  end

  def self.get_spotify_access_token
    response = RestClient.post("https://accounts.spotify.com/api/token",
      {
        grant_type: "client_credentials",
        client_id: ENV["SPOTIFY_CLIENT_ID"],
        client_secret: ENV["SPOTIFY_CLIENT_SECRET"]
      },
      {
        content_type: "application/x-www-form-urlencoded"
      }
    )
    JSON.parse(response.body)["access_token"]
  end

  # 既存の日記のジャンルを一括更新
  def self.classify_genres
    find_each do |journal|
      next if journal.spotify_track_id.blank?

      begin
        token = get_spotify_access_token

        track_response = RestClient.get(
          "https://api.spotify.com/v1/tracks/#{journal.spotify_track_id}",
          { Authorization: "Bearer #{token}" }
        )
        track_data = JSON.parse(track_response.body)
        artist_id = track_data["artists"].first["id"]

        artist_response = RestClient.get(
          "https://api.spotify.com/v1/artists/#{artist_id}",
          { Authorization: "Bearer #{token}" }
        )
        artist_data = JSON.parse(artist_response.body)
        genres = artist_data["genres"]

        genre = determine_best_genre_match(genres.map(&:downcase))
        journal.update(genre: genre)
        puts "Updated journal #{journal.id} (#{journal.artist_name} - #{journal.song_name})"
        puts "Genre: #{genre || 'undecided'}"
        puts "Spotify genres: #{genres.join(', ')}"
        puts "---"
      rescue => e
        puts "Error updating journal #{journal.id}: #{e.message}"
      end
    end
  end

  require "rest-client"
  require "json"
end

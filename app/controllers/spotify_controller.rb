class SpotifyController < ApplicationController
  before_action :authenticate_user!
  require "rest-client"
  require "json"
  require "net/http"
# 🎵 検索機能
def search
  @tracks = []
  query_parts = []

  # フォームの値をセッションに保存
  if params[:journal].present?
    session[:journal_form] = {
      title: params[:journal][:title],
      content: params[:journal][:content],
      emotion: params[:journal][:emotion]
    }
    Rails.logger.info "✅ Form data saved in session: #{session[:journal_form]}"
  end

  # 初期検索条件の追加
  if params[:search_conditions].present? && params[:search_values].present?
    params[:search_conditions].zip(params[:search_values]).each do |condition, value|
      if condition.present? && value.present?
        case condition
        when "year"
          # 年代をSpotify APIのクエリに変換（例：1990s → year:1990-1999）
          decade = value.match(/(\d{4})s/)&.[](1)
          if decade
            start_year = decade
            end_year = decade.to_i + 9
            query_parts << "year:#{start_year}-#{end_year}"
          end
        else
          query_parts << (condition == "keyword" ? value : "#{condition}:#{value}")
        end
      end
    end
  else
    flash.now[:alert] = "検索条件を入力してください。"
    return render partial: "spotify/search"
  end

  # 検索クエリの生成
  query_string = query_parts.join(" ")
  Rails.logger.debug "🔍 Spotify API Query: #{query_string}"

  if query_string.blank?
    flash.now[:alert] = "検索条件が無効です。"
    return render partial: "spotify/search"
  end

  # Spotify APIリクエスト
  begin
    results = RSpotify::Track.search(query_string, market: "JP")
    @tracks = results.map do |track|
      {
        song_name: track.name,
        artist_name: fetch_artist_name(track), # 日本語名を取得
        preview_url: track.preview_url,
        album_image: track.album.images.first&.dig("url")
      }
    end
  rescue RestClient::BadRequest => e
    Rails.logger.error "🚨 Spotify API Error: #{e.response}"
    flash.now[:alert] = "Spotify検索中にエラーが発生しました。"
  rescue StandardError => e
    Rails.logger.error "🚨 Unexpected Error: #{e.message}"
    flash.now[:alert] = "予期しないエラーが発生しました。"
  end

  Rails.logger.debug "Response Data to Frontend: #{@tracks}"

  # 結果の表示
  if @tracks.any?
    render "spotify/results", locals: { tracks: @tracks }
  else
    flash.now[:alert] = "検索結果がありませんでした。"
    redirect_to spotify_results_path
  end
end

  def results
    @tracks = []

    # フォームの値をセッションに保存
    if params[:journal].present?
      session[:journal_form] = {
        title: params[:journal][:title],
        content: params[:journal][:content],
        emotion: params[:journal][:emotion]
      }
      Rails.logger.info "✅ Form data saved in session from results: #{session[:journal_form]}"
    end

    if params[:initial_query].present?
      @tracks = search_tracks(
        query: params[:initial_query],
        type: params[:initial_search_type]
      )
    end
  end

  def autocomplete
    token = SpotifyToken.last

    if token.nil? || token.expired?
      fetch_spotify_token
      token = SpotifyToken.last
    end

    if token.nil?
      Rails.logger.error "Spotifyトークンが取得できませんでした"
      render json: { error: "Spotifyトークンが取得できませんでした" }, status: :internal_server_error
      return
    end

    access_token = token.access_token

    url = "https://api.spotify.com/v1/search"
    headers = {
      "Authorization" => "Bearer #{access_token}",
      "Content-Type" => "application/json",
      "Accept-Language" => "ja"
    }
    query_params = URI.encode_www_form({
      q: params[:query],
      type: params[:type] || "track,artist",
      limit: 10
    })
    full_url = "#{url}?#{query_params}"

    begin
      response = RestClient.get(full_url, headers)
      results = JSON.parse(response.body)

      autocomplete_results = []

      # 検索タイプに応じて結果を整形
      if results["tracks"] && results["tracks"]["items"]
        autocomplete_results += results["tracks"]["items"].map do |track|
          {
            id: track["id"],
            name: track["name"],
            type: "track",
            artist: track["artists"].map { |a| a["name"] }.join(", ")
          }
        end
      end

      if results["artists"] && results["artists"]["items"]
        autocomplete_results += results["artists"]["items"].map do |artist|
          {
            id: artist["id"],
            name: artist["name"],
            type: "artist"
          }
        end
      end

      render json: autocomplete_results
    rescue RestClient::Unauthorized => e
      Rails.logger.error "🚨 Unauthorized: #{e.message}"
      # Workerではなく直接fetch_spotify_tokenを呼び出す
      fetch_spotify_token
      token = SpotifyToken.last
      # 再試行
      response = RestClient.get(
        full_url,
        headers.merge("Authorization" => "Bearer #{token.access_token}")
      )
      render json: JSON.parse(response.body)
    rescue => e
      Rails.logger.error "🚨 API Error: #{e.message}"
      render json: { error: "検索中にエラーが発生しました" }, status: :bad_request
    end
  end

  # 🎯 トラック選択機能
  def select_tracks
    return unless params[:selected_track].present?

    begin
      # 選択した曲の情報をセッションに保存
      session[:selected_track] = JSON.parse(params[:selected_track])

      # フォームの入力値をセッションに保存
      session[:journal_form] = {
        title: params[:journal][:title],
        content: params[:journal][:content],
        emotion: params[:journal][:emotion]
      } if params[:journal].present?

      Rails.logger.info "✅ Track and form data saved in session: #{session[:selected_track]}, #{session[:journal_form]}"
      flash[:notice] = "曲を保存しました。"
      redirect_to new_journal_path
    rescue JSON::ParserError => e
      Rails.logger.error "🚨 JSON Parse Error: #{e.message}"
      flash.now[:alert] = "曲の保存に失敗しました。エラー: #{e.message}"
      render :search, status: :unprocessable_entity
    rescue StandardError => e
      Rails.logger.error "🚨 Unexpected Error: #{e.message}"
      flash.now[:alert] = "予期しないエラーが発生しました。"
      render :search, status: :unprocessable_entity
    end
  end

  private

  def fetch_artist_name(track)
    artist = track.artists.first
    return artist&.name if artist.nil?

    # Spotify APIに直接リクエストを送信し、日本語名を取得
    token = SpotifyToken.last
    begin
      response = RestClient.get(
        "https://api.spotify.com/v1/artists/#{artist.id}",
        {
          "Authorization" => "Bearer #{token.access_token}",
          "Content-Type" => "application/json",
          "Accept-Language" => "ja"
        }
      )
      detailed_artist = JSON.parse(response.body)
      Rails.logger.debug "Spotify Artist API Response: #{detailed_artist}"

      # 日本語名があればそれを返し、なければデフォルトの名前を返す
      detailed_artist["name"] || artist.name
    rescue RestClient::Unauthorized => e
      Rails.logger.error "🚨 Unauthorized: #{e.message}"
      SpotifyTokenRefreshWorker.new.perform
      token.reload
      # 再試行
      response = RestClient.get(
        "https://api.spotify.com/v1/artists/#{artist.id}",
        {
          "Authorization" => "Bearer #{token.reload.access_token}",
          "Content-Type" => "application/json",
          "Accept-Language" => "ja"
        }
      )
      detailed_artist = JSON.parse(response.body)
      Rails.logger.debug "Spotify Artist API Response: #{detailed_artist}"

      # 日本語名があればそれを返し、なければデフォルトの名前を返す
      detailed_artist["name"] || artist.name
    rescue RestClient::ExceptionWithResponse => e
      Rails.logger.error "🚨 Spotify Artist API Error: #{e.response}"
      artist.name
    rescue StandardError => e
      Rails.logger.error "🚨 Unexpected Error: #{e.message}"
      artist.name
    end
  end

  def fetch_spotify_token
    uri = URI("https://accounts.spotify.com/api/token")
    request = Net::HTTP::Post.new(uri)
    request.basic_auth(ENV["SPOTIFY_CLIENT_ID"], ENV["SPOTIFY_CLIENT_SECRET"])
    request.set_form_data(
      "grant_type" => "refresh_token",
      "refresh_token" => ENV["SPOTIFY_REFRESH_TOKEN"]
    )

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end

    if response.is_a?(Net::HTTPSuccess)
      data = JSON.parse(response.body)
      # 既存のトークンを削除
      SpotifyToken.destroy_all
      # 新しいトークンを作成
      SpotifyToken.create!(
        user_id: current_user.id,  # current_userのIDを設定
        access_token: data["access_token"],
        refresh_token: ENV["SPOTIFY_REFRESH_TOKEN"],
        expires_at: Time.current + data["expires_in"].seconds
      )
    else
      Rails.logger.error "トークンの取得に失敗しました: #{response.body}"
    end
  end
end

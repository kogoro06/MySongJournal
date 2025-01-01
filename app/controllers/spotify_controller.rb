class SpotifyController < ApplicationController
  require "rest-client"
  require "json"

  # 🎵 検索機能
  def search
    @tracks = []
    query_parts = []

    # ✅ 初期検索条件の追加
    if params[:initial_search_type].present? && params[:initial_query].present?
      query_parts << "#{params[:initial_search_type]}:#{params[:initial_query]}"
    else
      flash.now[:alert] = "検索タイプとキーワードを入力してください。"
      return render partial: "spotify/search", locals: { tracks: [] }
    end

    # ✅ 追加検索条件の追加
    if params[:search_conditions].present? && params[:search_values].present?
      params[:search_conditions].zip(params[:search_values]).each do |condition, value|
        query_parts << "#{condition}:#{value}" if condition.present? && value.present?
      end
    end

    # ✅ 検索クエリの生成
    query_string = query_parts.join(" ")
    Rails.logger.debug "🔍 Spotify API Query: #{query_string}"

    if query_string.blank?
      flash.now[:alert] = "検索条件が無効です。"
      return render partial: "spotify/search", locals: { tracks: [] }
    end

    # ✅ Spotify APIリクエスト
    begin
      results = RSpotify::Track.search(query_string, market: "JP")
      @tracks = results.map do |track|
        {
          song_name: track.name,
          artist_name: fetch_artist_name(track),
          preview_url: track.preview_url,
          album_image: track.album.images.first&.dig("url")
        }
      end
    rescue RestClient::BadRequest => e
      Rails.logger.error "🚨 Spotify API Error: #{e.response}"
      flash.now[:alert] = "Spotify検索中にエラーが発生しました。エラーメッセージ: #{e.response}"
    rescue StandardError => e
      Rails.logger.error "🚨 Unexpected Error: #{e.message}"
      flash.now[:alert] = "予期しないエラーが発生しました。"
    end

    respond_to do |format|
      format.html { render  "spotify/results", locals: { tracks: @tracks } }
      format.turbo_stream { render "spotify/results", locals: { tracks: @tracks } }
    end
  end

  def results
    @tracks = []
    if params[:initial_query].present?
      @tracks = search_tracks(
        query: params[:initial_query],
        type: params[:initial_search_type]
      )
    end
  end

  # 🎯 トラック選択機能
  def select_tracks
    return unless params[:selected_track].present?

    begin
      session[:selected_track] = JSON.parse(params[:selected_track])
      Rails.logger.info "✅ Track saved in session: #{session[:selected_track]}"
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

  # 🎤 アーティスト名を日本語で取得
  def fetch_artist_name(track)
    artist = track.artists.first
    return artist&.name if artist.nil?

    # Spotify APIに直接リクエストを送信し、日本語名を取得
    begin
      response = RestClient.get(
        "https://api.spotify.com/v1/artists/#{artist.id}",
        {
          Authorization: "Bearer #{fetch_access_token}",
          "Accept-Language": "ja"
        }
      )
      detailed_artist = JSON.parse(response.body)
      detailed_artist["name"] || artist.name
    rescue RestClient::ExceptionWithResponse => e
      Rails.logger.error "🚨 Spotify Artist API Error: #{e.response}"
      artist.name
    rescue StandardError => e
      Rails.logger.error "🚨 Unexpected Error: #{e.message}"
      artist.name
    end
  end

  # 🔄 アクセストークンを取得・更新
  def fetch_access_token
    token = ENV["SPOTIFY_ACCESS_TOKEN"]
    return token if token.present?

    # アクセストークンがない場合、リフレッシュトークンで新しいトークンを取得
    begin
      response = RestClient.post(
        "https://accounts.spotify.com/api/token",
        {
          grant_type: "refresh_token",
          refresh_token: ENV["SPOTIFY_REFRESH_TOKEN"]
        },
        {
          Authorization: "Basic #{Base64.strict_encode64("#{ENV['SPOTIFY_CLIENT_ID']}:#{ENV['SPOTIFY_CLIENT_SECRET']}")}"
        }
      )
      new_token = JSON.parse(response.body)["access_token"]
      ENV["SPOTIFY_ACCESS_TOKEN"] = new_token
      Rails.logger.info "✅ Spotify Access Token refreshed"
      new_token
    rescue RestClient::ExceptionWithResponse => e
      Rails.logger.error "🚨 Spotify Token Refresh Error: #{e.response}"
      raise "アクセストークンのリフレッシュに失敗しました。"
    rescue StandardError => e
      Rails.logger.error "🚨 Unexpected Error: #{e.message}"
      raise "予期しないエラーが発生しました。"
    end
  end
end

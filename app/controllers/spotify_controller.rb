class SpotifyController < ApplicationController
  require "rest-client"
  require "json"
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
    query = params[:query]
    type = params[:type] || "track,artist"

    return render json: [] if query.blank?

    begin
      headers = {
        Authorization: "Bearer #{fetch_access_token}",
        "Accept-Language" => "ja"
      }

      response = RestClient.get(
        "https://api.spotify.com/v1/search",
        {
          params: {
            q: query,
            type: type,
            limit: 10
          }
        }.merge(headers)
      )
      results = JSON.parse(response.body)

      autocomplete_results = []

      # 検索タイプに応じて結果を整形
      if type.include?("track") && results["tracks"] && results["tracks"]["items"]
        autocomplete_results += results["tracks"]["items"].map do |track|
          {
            id: track["id"],
            name: track["name"],
            type: "track",
            artist: track["artists"].map { |a| a["name"] }.join(", ")
          }
        end
      end

      if type.include?("artist") && results["artists"] && results["artists"]["items"]
        autocomplete_results += results["artists"]["items"].map do |artist|
          {
            id: artist["id"],
            name: artist["name"],
            type: "artist"
          }
        end
      end

      render json: autocomplete_results
    rescue RestClient::ExceptionWithResponse => e
      Rails.logger.error "🚨 Spotify Autocomplete API Error: #{e.response}"
      render json: { error: "Spotify APIエラー: #{e.response}" }, status: :bad_request
    rescue StandardError => e
      Rails.logger.error "🚨 Unexpected Error: #{e.message}"
      render json: { error: "予期しないエラーが発生しました: #{e.message}" }, status: :internal_server_error
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
    begin
      response = RestClient.get(
        "https://api.spotify.com/v1/artists/#{artist.id}",
        {
          Authorization: "Bearer #{fetch_access_token}",
          "Accept-Language": "ja" # 日本語のレスポンスをリクエスト
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

  # 🔄 アクセストークンを取得・更新
  def fetch_access_token
    token = ENV["SPOTIFY_ACCESS_TOKEN"]

    if token.nil? || token_expired?
      # アクセストークンをリフレッシュ
      refresh_access_token
    else
      token
    end
  end

  def refresh_access_token
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
      ENV["SPOTIFY_ACCESS_TOKEN"] = new_token # 必要に応じて他の保存方法に変更
      new_token
    rescue RestClient::ExceptionWithResponse => e
      Rails.logger.error "🚨 Spotify Token Refresh Error: #{e.response}"
      raise "アクセストークンのリフレッシュに失敗しました"
    end
  end
  def token_expired?
    # アクセストークンの有効期限を適切に確認するロジックを実装する
    # 例: トークンの有効期限を保存して比較する
    false
  end
end

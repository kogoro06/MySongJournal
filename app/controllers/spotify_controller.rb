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

  begin
    # Spotify APIで曲を検索
    results = RSpotify::Track.search(query_string, market: "JP")

    # アーティストIDを収集
    artist_ids = results.map { |track| track.artists.map(&:id) }.flatten.uniq

    # アーティスト情報を一括取得
    token = SpotifyToken.last
    artists_data = batch_fetch_artists(artist_ids, token)

    # 検索結果の整形
    @tracks = results.map do |track|
      artist_id = track.artists.first&.id
      {
        song_name: track.name,
        artist_name: artists_data[artist_id] || track.artists.first&.name,
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
    url = "https://api.spotify.com/v1/search"
    headers = {
      "Authorization" => "Bearer #{token.access_token}",
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
      # トークンの再取得を試みる
      SpotifyTokenRefreshWorker.new.perform
      token.reload
      # 再試行
      response = RestClient.get(full_url, headers.merge("Authorization" => "Bearer #{token.access_token}"))
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

  def batch_fetch_artists(artist_ids, token)
    return {} if artist_ids.empty?

    # アーティストIDを20個ずつのグループに分割（Spotify APIの制限）
    artist_ids.each_slice(20).reduce({}) do |result, ids_group|
      begin
        response = RestClient.get(
          "https://api.spotify.com/v1/artists?ids=#{ids_group.join(',')}",
          {
            "Authorization" => "Bearer #{token.access_token}",
            "Content-Type" => "application/json",
            "Accept-Language" => "ja"
          }
        )

        JSON.parse(response.body)["artists"].each do |artist|
          result[artist["id"]] = artist["name"]
        end
      rescue RestClient::Unauthorized
        token.reload
        SpotifyTokenRefreshWorker.new.perform
        # 再試行
        retry
      rescue StandardError => e
        Rails.logger.error "🚨 Batch Artist Fetch Error: #{e.message}"
      end

      result
    end
  end
end

module Spotify::SpotifySearchable
  extend ActiveSupport::Concern
  include Spotify::SpotifyApiRequestable

  def search
    save_journal_form
    # 検索時のみsessionを設定
    if params[:search_conditions].present? || params[:search_values].present?
      if request.referer&.include?("/edit")
        session[:return_to] = request.referer
      else
        session[:return_to] = new_journal_path
      end
    end

    @tracks = []
    # モーダルからのリクエストかどうかを判定
    is_modal = request.xhr? || params[:modal].present?

    unless valid_search_params?
      return respond_to do |format|
        if is_modal
          format.html { render partial: "spotify/search", layout: false }
          format.js { render partial: "spotify/search", layout: false }
        else
          format.html { redirect_to(request.referer || root_path) }
        end
      end
    end

    @query_string = build_query_string
    if @query_string.blank?
      flash[:alert] = "検索条件が無効です。"
      return respond_to do |format|
        if is_modal
          format.html { render partial: "spotify/search", layout: false }
          format.js { render partial: "spotify/search", layout: false }
        else
          format.html { redirect_to(request.referer || root_path) }
        end
      end
    end

    perform_spotify_search

    respond_to do |format|
      if @tracks.any?
        format.html { render "spotify/results", locals: { query_string: format_query_for_display(@query_string) } }
        format.js { render "spotify/results", locals: { query_string: format_query_for_display(@query_string) } }
      else
        flash[:alert] = "検索結果が見つかりませんでした。"
        if is_modal
          format.html { render partial: "spotify/search", layout: false }
          format.js { render partial: "spotify/search", layout: false }
        else
          format.html { redirect_to(request.referer || root_path) }
        end
      end
    end
  rescue StandardError => e
    Rails.logger.error "🚨 Search Error: #{e.message}"
    flash.now[:alert] = "検索中にエラーが発生しました。"
    render partial: "spotify/search"
  end

  def search_spotify
    save_journal_form if params[:journal].present?

    @query = params[:query]
    if @query.present?
      respond_to do |format|
        format.html
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "search_results",
            partial: "spotify/search_results",
            locals: { tracks: @tracks }
          )
        end
      end
    end
  end

  private

  def valid_search_params?
    params[:search_conditions].present? && params[:search_values].present?
  end

  def build_query_string
    params[:search_conditions].zip(params[:search_values])
      .map { |condition, value| build_query_part(condition, value) }
      .compact.join(" ")
  end

  def build_query_part(condition, value)
    return nil if value.blank?

    case condition
    when "year"
      if (decade = value.match(/(\d{4})s/))
        start_year = decade[1]
        end_year = start_year.to_i + 9
        "year:#{start_year}-#{end_year}"
      end
    else
      condition == "keyword" ? value : "#{condition}:#{value}"
    end
  end

  def perform_spotify_search
    page = (params[:page] || 1).to_i
    offset = (page - 1) * @per_page

    # アーティスト検索の場合は特別な処理
    if params[:search_conditions]&.include?("artist") && params[:search_values].present?
      artist_index = params[:search_conditions].index("artist")
      artist_name = params[:search_values][artist_index]
      enhanced_artist_search(artist_name, page)
    else
      # 通常の検索（アーティスト検索以外）
      results = spotify_get("search", search_params(offset))
      process_search_results(results, page)
    end
  rescue StandardError => e
    handle_search_error(e)
  end

  def search_params(offset)
    {
      params: {
        q: @query_string,
        type: "track",
        market: "JP",
        limit: @per_page,
        offset: offset
      }
    }
  end

  def process_search_results(results, page)
    return [] unless results && results["tracks"]

    # ページネーション情報を追加
    @total_count = results["tracks"]["total"]
    @total_pages = (@total_count.to_f / @per_page).ceil
    @current_page = page
    @offset_value = (page - 1) * @per_page

    @tracks = Kaminari.paginate_array(
      results["tracks"]["items"].map do |track|
        {
          spotify_track_id: track["id"],
          song_name: track["name"],
          artist_name: track["artists"]&.first&.dig("name") || "Unknown Artist",
          album_image: track["album"]["images"]&.first&.dig("url")
        }
      end,
      total_count: @total_count
    ).page(@current_page).per(@per_page)
    @tracks
  end

  def handle_search_error(error)
    Rails.logger.error "🚨 Search Error: #{error.message}"
    flash.now[:alert] = "検索中にエラーが発生しました。"
    render partial: "spotify/search" and return
  end

  def format_query_for_display(query)
    {
      "artist:" => "アーティスト名:",
      "track:" => "曲名:",
      "album:" => "アルバム名:",
      "year:" => "年代:"
    }.each do |eng, jpn|
      query = query.gsub(eng, jpn)
    end
    query
  end

  def save_journal_form
    return unless params[:journal].present?

    session[:journal_form] = {
      title: params[:journal][:title],
      content: params[:journal][:content],
      emotion: params[:journal][:emotion],
      public: params[:journal][:public]
    }
    Rails.logger.info "✅ Form data saved in session: #{session[:journal_form]}"
  rescue => e
    Rails.logger.error "⚠️ Error saving form data: #{e.message}"
  end

  # フィルタリングされたトラック結果を処理するメソッド
  def process_filtered_tracks(filtered_tracks, page)
    # ページネーション情報を設定
    @total_count = filtered_tracks.size
    @total_pages = (@total_count.to_f / @per_page).ceil
    @current_page = page
    @offset_value = (page - 1) * @per_page

    # 現在のページに表示すべきトラックを抽出
    start_index = @offset_value
    end_index = [ @offset_value + @per_page - 1, @total_count - 1 ].min
    current_page_tracks = filtered_tracks[start_index..end_index] || []

    @tracks = Kaminari.paginate_array(
      current_page_tracks.map do |track|
        {
          spotify_track_id: track["id"],
          song_name: track["name"],
          artist_name: track["artists"]&.first&.dig("name") || "Unknown Artist",
          album_image: track["album"]["images"]&.first&.dig("url")
        }
      end,
      total_count: @total_count
    ).page(@current_page).per(@per_page)

    Rails.logger.info "📝 Processed #{@tracks.size} filtered tracks (total: #{@total_count})"
    @tracks
  end

  # すべてのアーティスト向けの拡張検索
  def enhanced_artist_search(artist_name, page)
    all_tracks = []

    # 1. 基本的なアーティスト検索
    results = spotify_get("search", {
      params: {
        q: "artist:\"#{artist_name}\"",
        type: "track",
        market: "JP",
        limit: 50
      }
    })

    if results && results["tracks"] && results["tracks"]["items"].present?
      filtered_tracks = results["tracks"]["items"].select do |track|
        track["artists"].any? { |artist| artist["name"].downcase == artist_name.downcase }
      end
      all_tracks.concat(filtered_tracks)
    end

    # 2. アーティストIDを使った検索
    begin
      artist_results = spotify_get("search", {
        params: {
          q: "artist:\"#{artist_name}\"",
          type: "artist",
          limit: 5
        }
      })

      if artist_results && artist_results["artists"] && artist_results["artists"]["items"].present?
        exact_artist = artist_results["artists"]["items"].find do |artist|
          artist["name"].downcase == artist_name.downcase
        end

        if exact_artist
          top_tracks = spotify_get("artists/#{exact_artist['id']}/top-tracks", {
            params: { market: "JP" }
          })

          if top_tracks && top_tracks["tracks"].present?
            top_tracks["tracks"].each do |track|
              unless all_tracks.any? { |t| t["id"] == track["id"] }
                all_tracks << track
              end
            end
          end
        end
      end
    rescue => e
      Rails.logger.error "トップトラック取得エラー (#{artist_name}): #{e.message}"
    end

    Rails.logger.info "🎸 Found #{all_tracks.size} tracks for artist: #{artist_name}"
    process_filtered_tracks(all_tracks, page)
  end
end

module Spotify::SpotifySearchable
  extend ActiveSupport::Concern
  include Spotify::SpotifyApiRequestable

  def search
    Rails.logger.info "🔍 Search called"
    Rails.logger.info "🎯 Current URL: #{request.url}"
    Rails.logger.info "🔙 Referer: #{request.referer}"
    Rails.logger.info "📝 Search params: #{params.inspect}"

    p "========== Spotify Search Debug =========="
    p "Params: #{params}"
    p "Journal Params: #{params[:journal]}"
    p "Current Session: #{session[:journal_form]}"
    p "========================================"

    save_journal_form

    p "========== After Save Debug =========="
    p "Updated Session: #{session[:journal_form]}"
    p "===================================="

    # 検索時のみsessionを設定
    if params[:search_conditions].present? || params[:search_values].present?
      if request.referer&.include?("/edit")
        session[:return_to] = request.referer
        Rails.logger.info "💾 Saved return path: #{session[:return_to]}"
      else
        session[:return_to] = new_journal_path
        Rails.logger.info "💾 Saved return path: #{session[:return_to]}"
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

    # 検索条件をログに出力
    Rails.logger.info "🎵 Search conditions: #{params[:search_conditions]}"
    Rails.logger.info "🎯 Search values: #{params[:search_values]}"

    perform_spotify_search
    Rails.logger.info "✅ Search completed with #{@tracks&.size || 0} results"

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
    Rails.logger.debug "🔍 Search params: #{params.inspect}"

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

    results = spotify_get("search", search_params(offset))
    process_search_results(results, page)
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
    
    Rails.logger.info "📝 Processed #{@tracks.size} tracks"
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
end

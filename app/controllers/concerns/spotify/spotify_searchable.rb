module Spotify::SpotifySearchable
  extend ActiveSupport::Concern
  include Spotify::SpotifyApiRequestable

  def search
    @tracks = []
    unless valid_search_params?
      flash.now[:alert] = "検索条件を入力してください。"
      return respond_to do |format|
        format.html { render partial: "spotify/search" }
        format.js { render partial: "spotify/search" }
      end
    end
    
    @query_string = build_query_string
    if @query_string.blank?
      flash.now[:alert] = "検索条件が無効です。"
      return respond_to do |format|
        format.html { render partial: "spotify/search" }
        format.js { render partial: "spotify/search" }
      end
    end
  
    perform_spotify_search
  
    respond_to do |format|
      if @tracks.any?
        format.html { render "spotify/results", locals: { query_string: format_query_for_display(@query_string) } }
        format.js { render "spotify/results", locals: { query_string: format_query_for_display(@query_string) } }
      else
        flash.now[:alert] = "検索結果が見つかりませんでした。"
        format.html { render partial: "spotify/search" }
        format.js { render partial: "spotify/search" }
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
    if results["tracks"] && results["tracks"]["items"].any?
      @tracks = results["tracks"]["items"].map do |track|
        {
          spotify_track_id: track["id"],
          song_name: track["name"],
          artist_name: track["artists"].first["name"],
          album_image: track["album"]["images"].first["url"]
        }
      end

      @total_count = results["tracks"]["total"]
      @tracks = Kaminari.paginate_array(@tracks, total_count: @total_count)
                       .page(page).per(@per_page)
    else
      @tracks = []
      flash.now[:alert] = "検索結果が見つかりませんでした。"
    end
  end

  def handle_search_error(error)
    Rails.logger.error "🚨 Search Error: #{error.message}"
    flash.now[:alert] = "検索中にエラーが発生しました。"
    render partial: "spotify/search"
  end

  def format_query_for_display(query)
    {
      'artist:' => 'アーティスト名:',
      'track:' => '曲名:',
      'album:' => 'アルバム名:',
      'year:' => '年代:'
    }.each do |eng, jpn|
      query = query.gsub(eng, jpn)
    end
    query
  end
end
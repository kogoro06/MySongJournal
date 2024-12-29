class SpotifyController < ApplicationController
  def search
    @tracks = []
    query_parts = []

    # ✅ 初期検索条件の追加
    if params[:initial_search_type].present? && params[:initial_query].present?
      query_parts << "#{params[:initial_search_type]}:#{params[:initial_query]}"
    else
      flash.now[:alert] = "検索タイプとキーワードを入力してください。"
      return render partial: "spotify/search_form", locals: { tracks: [] }
    end

    # ✅ 追加検索条件の追加
    if params[:search_conditions].present? && params[:search_values].present?
      params[:search_conditions].zip(params[:search_values]).each do |condition, value|
        query_parts << "#{condition}:#{value}" if condition.present? && value.present?
      end
    end

    # ✅ 検索クエリの生成
    query_string = query_parts.join(' ')
    Rails.logger.debug "🔍 Spotify API Query: #{query_string}"

    if query_string.blank?
      flash.now[:alert] = "検索条件が無効です。"
      return render partial: "spotify/search_form", locals: { tracks: [] }
    end

    # ✅ Spotify APIリクエスト
    begin
      results = RSpotify::Track.search(query_string)
      @tracks = results.map do |track|
        {
          song_name: track.name,
          artist_name: track.artists.first&.name,
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
      format.html { render partial: "spotify/search_form", locals: { tracks: @tracks } }
      format.turbo_stream { render partial: "spotify/search_form", locals: { tracks: @tracks } }
    end
  end

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
end

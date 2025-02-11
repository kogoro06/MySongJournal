module Spotify::SpotifySearchResultsHandler
    extend ActiveSupport::Concern

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
  
    def respond_to_search_results
      respond_to do |format|
        if @tracks.any?
          format.html { render "spotify/results", locals: { query_string: format_query_for_display(@query_string) } }
          format.js { render "spotify/results", locals: { query_string: format_query_for_display(@query_string) } }
        else
          flash[:alert] = "検索結果が見つかりませんでした。"
          handle_no_results(format)
        end
      end
    end
  
    def handle_no_results(format)
      if request.xhr? || params[:modal].present?
        format.html { render partial: "spotify/search", layout: false }
        format.js { render partial: "spotify/search", layout: false }
      else
        format.html { redirect_to(request.referer || root_path) }
      end
    end
  
    def handle_search_error(error)
      Rails.logger.error "🚨 Search Error: #{error.message}"
      flash.now[:alert] = "検索中にエラーが発生しました。"
      render partial: "spotify/search"
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
  end
  
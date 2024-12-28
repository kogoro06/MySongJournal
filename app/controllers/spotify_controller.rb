class SpotifyController < ApplicationController
  # 曲を検索するアクション
  def search
    @tracks = []

    if params[:query].present?
      begin
        if params[:search_type] == "artist"
          results = RSpotify::Track.search("artist:#{params[:query]}")
        elsif params[:search_type] == "track"
          results = RSpotify::Track.search("track:#{params[:query]}")
        end

        @tracks = results.map do |track|
          {
            song_name: track.name,
            artist_name: track.artists.first&.name || "アーティスト不明",
            preview_url: track.preview_url || "プレビューなし",
            album_image: track.album&.images&.first&.fetch("url", "画像なし")
          }
        end
      rescue RestClient::InternalServerError => e
        Rails.logger.error "Spotify API Internal Server Error: #{e.message}"
        flash.now[:alert] = "Spotify APIでエラーが発生しました。時間をおいて再度お試しください。"
        @tracks = []
      rescue StandardError => e
        Rails.logger.error "Unexpected Error: #{e.message}"
        flash.now[:alert] = "予期しないエラーが発生しました。"
        @tracks = []
      end
    end

    # 検索結果をモーダルで表示
    respond_to do |format|
      format.html { render partial: "spotify/search_form" }
      format.turbo_stream { render partial: "spotify/search_form" }
    end
  end
end

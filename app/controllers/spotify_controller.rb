class SpotifyController < ApplicationController
  def search
    @tracks = []

    if params[:query].present?
      results = if params[:search_type] == "artist"
                  RSpotify::Track.search("artist:#{params[:query]}")
                elsif params[:search_type] == "track"
                  RSpotify::Track.search("track:#{params[:query]}")
                end

      @tracks = results.map do |track|
        {
          song_name: track.name,
          artist_name: track.artists.first.name,
          preview_url: track.preview_url,
          album_image: track.album.images.first["url"]
        }
      end
    end

    respond_to do |format|
      format.html { render partial: 'spotify/search_form' }
      format.turbo_stream { render partial: 'spotify/search_form' }
    end
  end

  def select_tracks
    return unless params[:selected_track].present?

    begin
      session[:selected_track] = JSON.parse(params[:selected_track])
      flash[:notice] = "曲を保存しました。"
      redirect_to new_journal_path
    rescue JSON::ParserError => e
      flash.now[:alert] = "曲の保存に失敗しました。エラー: #{e.message}"
      render :search, status: :unprocessable_entity
    end
  end
end

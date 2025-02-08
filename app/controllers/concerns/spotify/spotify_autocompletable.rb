module Spotify::SpotifyAutocompletable
  extend ActiveSupport::Concern
  include Spotify::SpotifyApiRequestable

  def autocomplete
    results = spotify_get("search", autocomplete_params)
    render json: format_results(results)
  rescue StandardError => e
    handle_autocomplete_error(e)
  end

  private

  def autocomplete_params
    {
      params: {
        q: params[:query],
        type: params[:type] || "track,artist",
        limit: 10
      }
    }
  end

  def format_results(results)
    format_tracks(results) + format_artists(results)
  end

  def format_tracks(results)
    return [] unless results["tracks"] && results["tracks"]["items"]
    results["tracks"]["items"].map do |track|
      {
        id: track["id"],
        name: track["name"],
        type: "track",
        artist: track["artists"].map { |a| a["name"] }.join(", ")
      }
    end
  end

  def format_artists(results)
    return [] unless results["artists"] && results["artists"]["items"]
    results["artists"]["items"].map do |artist|
      {
        id: artist["id"],
        name: artist["name"],
        type: "artist"
      }
    end
  end

  def handle_autocomplete_error(error)
    Rails.logger.error " Autocomplete Error: #{error.message}"
    render json: { error: "検索中にエラーが発生しました" }, status: :bad_request
  end
end

class AddSpotifyTrackIdToJournals < ActiveRecord::Migration[7.2]
  def change
    add_column :journals, :spotify_track_id, :string
  end
end

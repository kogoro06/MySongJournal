class CreateSpotifyTokens < ActiveRecord::Migration[7.2]
  def change
    create_table :spotify_tokens do |t|
      t.references :user, null: false, foreign_key: true # ユーザーとの関連
      t.string :access_token
      t.string :refresh_token
      t.datetime :expires_at

      t.timestamps
    end
    add_index :spotify_tokens, :refresh_token, unique: true
  end
end

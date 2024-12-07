class CreateJournals < ActiveRecord::Migration[7.0]
  def change
    create_table :journals do |t|
      t.string :title, null: false
      t.text :content, null: false
      t.integer :emotion, null: false, default: 0
      t.string :artist_name, null: false
      t.string :song_name, null: false
      t.string :preview_url
      t.string :album_image
      t.references :user, foreign_key: true

      t.timestamps
    end
  end
end
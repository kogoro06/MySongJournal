class AddGenreToJournals < ActiveRecord::Migration[7.2]
  def change
    add_column :journals, :genre, :string
  end
end

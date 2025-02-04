class AddSlugToJournals < ActiveRecord::Migration[7.2]
  def change
    add_column :journals, :slug, :string
    add_index :journals, :slug, unique: true
  end
end

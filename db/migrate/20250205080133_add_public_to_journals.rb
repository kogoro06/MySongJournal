class AddPublicToJournals < ActiveRecord::Migration[7.0]
  def change
    add_column :journals, :public, :boolean, default: true, null: false
    add_index :journals, :public
  end
end
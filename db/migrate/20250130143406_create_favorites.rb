class CreateFavorites < ActiveRecord::Migration[7.2]
  def change
    create_table :favorites do |t|
      t.references :user, null: false, foreign_key: true
      t.references :journal, null: false, foreign_key: true

      t.timestamps
    end
    add_index :favorites, [ :user_id, :journal_id ], unique: true
  end
end

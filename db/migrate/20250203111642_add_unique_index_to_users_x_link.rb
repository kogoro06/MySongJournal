class AddUniqueIndexToUsersXLink < ActiveRecord::Migration[7.1]
  def change
    add_index :users, :x_link, unique: true, where: "x_link IS NOT NULL"
  end
end
class AddDetailsToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :bio, :text
    add_column :users, :x_link, :string
  end
end

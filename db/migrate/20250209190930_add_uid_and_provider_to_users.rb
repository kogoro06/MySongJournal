class AddUidAndProviderToUsers < ActiveRecord::Migration[7.0] # Railsのバージョンにより異なる
  def change
    add_column :users, :uid, :string
    add_column :users, :provider, :string
    add_index :users, [ :uid, :provider ], unique: true
  end
end

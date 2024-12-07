class ChangeNameInUsers < ActiveRecord::Migration[7.2]
  def change
    change_column :users, :name, :string, default: "", null: false
  end
end

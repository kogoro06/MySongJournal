class AddUidAndProviderToUsers < ActiveRecord::Migration[7.0]
  def up
    # providerカラムが存在しない場合のみ追加
    unless column_exists?(:users, :provider)
      add_column :users, :provider, :string, default: "", null: false
    end

    # uidカラムが存在しない場合のみ追加
    unless column_exists?(:users, :uid)
      add_column :users, :uid, :string
    end

    # インデックスが存在しない場合のみ追加
    unless index_exists?(:users, [:uid, :provider])
      add_index :users, [:uid, :provider], unique: true
    end
  end

  def down
    # インデックスが存在する場合のみ削除
    if index_exists?(:users, [:uid, :provider])
      remove_index :users, [:uid, :provider]
    end

    # uidカラムが存在する場合のみ削除
    if column_exists?(:users, :uid)
      remove_column :users, :uid
    end

    # providerカラムが存在する場合のみ削除
    if column_exists?(:users, :provider)
      remove_column :users, :provider
    end
  end
end
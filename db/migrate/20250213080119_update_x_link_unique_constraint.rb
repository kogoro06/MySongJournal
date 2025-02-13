class UpdateXLinkUniqueConstraint < ActiveRecord::Migration[7.0]
  def change
    # 既存のインデックスを削除
    remove_index :users, :x_link if index_exists?(:users, :x_link)

    # 空でない値のみユニーク制約を適用
    add_index :users, :x_link, unique: true,
      where: "x_link != '' AND x_link IS NOT NULL"
  end
end

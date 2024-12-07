class UpdateNullNameInUsers < ActiveRecord::Migration[7.2]
  def up
    User.where(name: nil).update_all(name: "")
  end

  def down
    # 必要に応じてrollback処理を記載
    # 例: nameをnilに戻す処理
    User.where(name: "").update_all(name: nil)
  end
end

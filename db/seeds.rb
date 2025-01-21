# 管理者ユーザーの作成
admin_user = User.find_or_create_by!(email: ENV['ADMIN_EMAIL']) do |user|
  user.password = ENV['ADMIN_PASSWORD']
  user.name = 'Administrator'
  user.role = :admin
end
puts "管理者ユーザーを作成しました: #{admin_user.email}"

# 一般ユーザーの作成
general_users = [
  {
    email: 'user1@example.com',
    password: 'password',
    name: 'User 1'
  },
  {
    email: 'user2@example.com',
    password: 'password',
    name: 'User 2'
  }
]

general_users.each do |user_attrs|
  user = User.find_or_create_by!(email: user_attrs[:email]) do |u|
    u.password = user_attrs[:password]
    u.name = user_attrs[:name]
    u.role = :general
  end
  puts "一般ユーザーを作成しました: #{user.email}"
end

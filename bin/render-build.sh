#!/usr/bin/env bash
# exit on error
set -o errexit

# Bundlerのインストールと設定
bundle install

# アセットのプリコンパイル
bundle exec rake assets:precompile
bundle exec rake assets:clean

# データベースのマイグレーションとシードの実行
bundle exec rake db:migrate
bundle exec rake db:seed

# キャッシュのクリア（オプション）
bundle exec rake tmp:clear
bundle exec rake log:clear

class Journal < ApplicationRecord
  belongs_to :user
  enum emotion: { 喜: 0, 怒: 1, 哀: 2, 楽: 3 }
  validates :title, presence: true, length: { maximum: 50 } # 必須、最大50文字
  validates :content, presence: true, length: { maximum: 500 } # 必須、最大500文字
  validates :emotion, presence: true # 必須
  validates :song_name, presence: true, length: { maximum: 100 }
  validates :artist_name, presence: true, length: { maximum: 100 }
  validates :album_image, presence: true, format: { with: URI.regexp(%w[http https]), message: "must be a valid URL" }
  validates :preview_url, format: { with: URI.regexp(%w[http https]), message: "must be a valid URL" }, allow_blank: true
end

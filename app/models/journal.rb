class Journal < ApplicationRecord
  enum emotion: { 喜: 0, 怒: 1, 哀: 2, 楽: 3 }
  validates :title, presence: true, length: { maximum: 50 } # 必須、最大50文字
  validates :content, presence: true, length: { maximum: 500 } # 必須、最大500文字
end

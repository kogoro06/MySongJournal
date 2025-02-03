ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "minitest/mock"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
    def mock_ogp_image
      # テスト用の画像データを生成
      image = MiniMagick::Image.new(Rails.root.join("app/assets/images/ogp.png"))
      image.resize "1200x630"
      image.to_blob
    end
  end
end

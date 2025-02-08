# app/controllers/spotify_controller.rb
class SpotifyController < ApplicationController
  # どのライブラリを使用するのか
  #   * 速度を重視する時: rest-client
  #   * Cookie等の自動追跡機能を使用する時: OpenURI
  #   *  postメソッドを使用して通信を行いたい時: Net::HTTP
  #   *　今回は速度を重視してrest-clientを使用しています
  require "rest-client"

  include Spotify::SpotifyApiClient
  include Spotify::SpotifySearchable
  include Spotify::SpotifyAutocompletable
  include Spotify::SpotifyTrackSelectable

  before_action :authenticate_user!
  before_action :set_per_page, only: [ :search ]

  private

  def set_per_page
    @per_page = 6
  end
end

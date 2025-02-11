module Spotify::SpotifyAutocompletable
  extend ActiveSupport::Concern
  include Spotify::SpotifyApiRequestable # Spotify APIリクエスト用のモジュールをインクルード
  require_relative '../../../errors/spotify_api_error'


  # Spotifyの検索APIを使ってオートコンプリート機能を実行するメソッド
  # ユーザーが入力したクエリに基づいて、曲やアーティストの候補を取得します。
  def autocomplete
    # Spotify APIにリクエストを送り、結果を取得
    results = spotify_get("search", autocomplete_params)

    # 結果をフォーマットしてJSON形式で返す
    render json: format_results(results)
  rescue StandardError => e
    # エラーが発生した場合の処理
    handle_autocomplete_error(e)
  end

  private

  # Spotify APIに渡す検索パラメータを構築するメソッド
  # ユーザーが入力したクエリや検索タイプ（曲、アーティストなど）を設定します。
  def autocomplete_params
    {
      params: {
        q: params[:query],                # 検索クエリ（ユーザーが入力した文字列）
        type: params[:type] || "track,artist", # 検索タイプ（デフォルトは曲とアーティスト）
        limit: 10,                         # 結果の最大数（10件）
        fields: "tracks.items(id,name,artists.name),artists.items(id,name)" # 必要なフィールドのみ取得
      }
    }
  end

  # Spotify APIの検索結果をフォーマットするメソッド
  # 曲とアーティストの情報をそれぞれフォーマットし、1つのリストにまとめます。
  def format_results(results)
    format_items(results, "tracks", "track") + format_items(results, "artists", "artist") #必要な情報のみ取得
  end

  # Spotify APIの検索結果をフォーマットするメソッド
  # key : 検索結果のハッシュのキー（"tracks" or "artists"）
  # type : フォーマットするアイテムのタイプ（"track" or "artist"）
  def format_items(results, key, type)
    # 検索結果のハッシュから指定されたキーの値を取得
    # その値は配列のため、mapメソッドで各要素をフォーマット
    items = results.dig(key, "items") || []
    items.map do |item|
      # itemが曲の場合
      if type == "track"
        # 曲のID、名前、アーティスト名を取得してハッシュに格納
        {
          id: item["id"],
          name: item["name"],
          type: type,
          artist: item["artists"].map { |a| a["name"] }.join(", ")
        }
      # itemがアーティストの場合
      elsif type == "artist"
        # アーティストのID、名前を取得してハッシュに格納
        {
          id: item["id"],
          name: item["name"],
          type: type
        }
      end
    end
  end
  # オートコンプリート中にエラーが発生した場合の処理
  # エラーメッセージをログに記録し、ユーザーにエラーメッセージを返します。
  def handle_autocomplete_error(error)
    if error.is_a?(SpotifyApiError) # Spotify API特有のエラー
      Rails.logger.error "Spotify API Error: #{error.message}. Params: #{params&.to_unsafe_h || {}}"
      render json: { error: "Spotify APIでエラーが発生しました" }, status: :service_unavailable
    else # 通常のエラー
      Rails.logger.error "Autocomplete Error: #{error.message}. Params: #{params&.to_unsafe_h || {}}"
      render json: { error: "検索中にエラーが発生しました" }, status: :bad_request
    end
  end  
end

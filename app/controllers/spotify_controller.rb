class SpotifyController < ApplicationController
  before_action :authenticate_user!
  # どのライブラリを使用するのか
  #   * 速度を重視する時: rest-client
  #   * Cookie等の自動追跡機能を使用する時: OpenURI
  #   *  postメソッドを使用して通信を行いたい時: Net::HTTP
  #   *　今回は速度を重視してrest-clientを使用しています
  require "rest-client"

# 検索機能
def search
  # tracksに検索結果を格納
  # query_partsに検索クエリを格納
  @tracks = []
  query_parts = []

  # ページネーションの設定
  @per_page = 6  # タイムラインと同じく6件に設定
  page = (params[:page] || 1).to_i # URLの?以降に指定されたページ番号　ex: search?page=2の場合、pageは2になり、パラメータが無い場合は1になる
  # offsetの計算
  # 例えば、page=2の時、offset=6になるため、7個目の要素から始まる
  # 1ページ目は0から始まるため、 offset = (2-1) * 6 = 6
  offset = (page.to_i - 1) * @per_page

  # フォームの値をセッションに保存
  if params[:journal].present? #journalの値(タイトルと内容と感情と公開)が存在する場合
    session[:journal_form] = { #セッションに値を保存
      title: params[:journal][:title], #タイトル
      content: params[:journal][:content], #内容
      emotion: params[:journal][:emotion], #感情
    }
  end

  # 初期検索条件の追加
  if params[:search_conditions].present? && params[:search_values].present? #検索条件と検索値が存在する場合
     # 検索条件と検索値を対応付けて配列にする
    # 例: search_conditions = ["year", "artist"], search_values = ["2020", "椎名林檎"] の場合
    # .zipで → [["year", "2020"], ["artist", "椎名林檎"]] という組み合わせの配列を作成
    params[:search_conditions].zip(params[:search_values]).each do |condition, value| 
      # 条件と値が存在する場合
      # 例: condition = "year", value = "2020" の場合
      if condition.present? && value.present?
        # 条件の種類によって処理を分岐
        case condition
        # yearの場合
        when "year"
          # 年代をSpotify APIのクエリに変換（例：1990s → year:1990-1999）
          # valueに「1990s」などの文字列が含まれる場合、\d{4}という正規表現にマッチングする
          # マッチング結果の1つ目のグループ（()で囲まれた部分）を decade に代入
          # .match ではマッチング結果を MatchData オブジェクトとして返す
          # .[](1) というメソッドは MatchData オブジェクトの1つ目のグループを文字列として返す
          # (1) という数字は、 () で囲まれたグループの番号を指定する
          # 例えば、/(\d{4})(\w)/ という正規表現であれば、 .[](1) ではマッチング結果の1つ目(1990sであれば1990年)を指定する
          # つまり、(\d{4}) という部分にマッチングした文字列を取得する
          decade = value.match(/(\d{4})s/)&.[](1)
          # decade が存在する場合
          if decade
            # decadeの1年目を start_year
            start_year = decade
            # decadeの終了年を end_yearとする
            end_year = decade.to_i + 9
            # year:#{start_year}-#{end_year} の形式のクエリ（例：year:1990-1999の１０年間）を query_parts という一つの配列に追加
            query_parts << "year:#{start_year}-#{end_year}"
          end
        else
          # condition が keyword の場合
          # value は keyword として扱う
          query_parts << (condition == "keyword" ? value : "#{condition}:#{value}")
        end
      end
    end
  else
    # 検索条件が無効な場合、"検索条件を入力してください。" というアラートを表示
    flash.now[:alert] = "検索条件を入力してください。"
    #spotify/_search.html.erbというパーシャルをレンダリング
    return render partial: "spotify/search"
  end

  #　query_stringという変数に、query_parts(query_partsは上で定義済み）をまとめた文字列を代入
  query_string = query_parts.join(" ")

  # query_stringが空の場合
  if query_string.blank?
    # "検索条件が無効です" というアラートを表示
    flash.now[:alert] = "検索条件が無効です。"
    #spotify/_search.html.erbというパーシャルをレンダリング
    return render partial: "spotify/search"
  end

  # 例外処理の開始
  # beginからrescueまでの処理中にエラーが発生した場合、
  # rescueで指定したエラー処理を実行する
  # 例：
  # - Spotify APIのアクセストークンの取得に失敗
  # - APIからのレスポンスが不正
  # - ネットワークエラー
  begin
    # Spotify APIのアクセストークンの取得
    token = get_spotify_access_token

    # RestClientを使ってSpotify APIにGETリクエストを送る
    # URLの"v1"はAPIのバージョンを示す
    # - APIのバージョン管理により、新機能追加や仕様変更があっても古いバージョンは維持される
    # - 例：将来v2が出ても、v1を使用しているアプリは影響を受けない
    # - Spotifyの場合、v1は安定版のAPIバージョン
    #
    # APIエンドポイント（URL）について
    # - https://api.spotify.com/v1/search は Spotify Web API のドキュメントで定義
    # - 公式ドキュメント: https://developer.spotify.com/documentation/web-api/reference/search
    # - このエンドポイントで曲、アーティスト、アルバムなどの検索が可能
    response = RestClient.get(
      "https://api.spotify.com/v1/search",
      {
        # 認証情報の設定
        # - Authorization: APIリクエストの認証に使用するHTTPヘッダー
        # - "Bearer": トークンの種類を示す。OAuth2.0で使用される標準的な認証方式
        #   - Bearer（持参人）という名前の通り、トークンを持っている人がAPIを使用できる
        #   - 形式: "Bearer" + スペース + アクセストークン
        # - #{token}: get_spotify_access_tokenで取得した一時的なアクセストークン
        #   - トークンの有効期限は1時間
        #   - 期限切れの場合は自動的に再取得される
        Authorization: "Bearer #{token}",
        "Accept-Language" => "ja",  # 日本語表記を優先
        params: {
          q: query_string, # 検索クエリ qは検索文字列　ex: "artist:椎名林檎" query_stringは上で定義済み
          type: "track", # 検索対象を曲に限定
          market: "JP",  # 日本のマーケットに限定
          limit: @per_page, # 1ページの曲の数(@per_pageは上で定義しているように6に設定している)
          offset: offset # 1ページ目は1から６まで、2ページ目は7から12までとなるように設定している
        }
      }
    )

    # JSONをパースして、必要な情報を取得
    # - parse: JSON形式の文字列をRubyのハッシュやオブジェクトに変換すること
    # - response.body: APIから返ってきた生のJSONデータ（文字列）
    # 例：
    # JSON文字列: '{"name": "曲名", "artist": "アーティスト名"}'
    # ↓ parse後
    # Rubyハッシュ: {"name" => "曲名", "artist" => "アーティスト名"}
    results = JSON.parse(response.body)
    
    # APIレスポンスが正常で、曲データが存在する場合
    # - .any?: 配列が空でないかをチェックするメソッド
    #   - 配列に要素が1つでもあれば true
    #   - 配列が空の場合は false
    # 例：
    # [1, 2, 3].any? => true
    # [].any? => false
    #今回の場合、　トラックがきちんと取得されていて、中に何かしらのデータがあることを確認
    if results["tracks"] && results["tracks"]["items"].any?
      # APIレスポンスから曲データを取得
      # - map: 配列の各要素に対してブロックを実行し、新しい配列を生成する
      # 今回の場合、track: 1曲の情報を保持するハッシュとしてマップされる
      @tracks = results["tracks"]["items"].map do |track|
        {
          spotify_track_id: track["id"], # spotify_track_id: 曲のID
          song_name: track["name"], #song_name: 曲の名前
          artist_name: track["artists"].first["name"], #artist_name: アーティストの名前
          album_image: track["album"]["images"].first["url"], #album_image: アルバム画像のURL
        }
      end

      # ページネーション情報の設定
      # - total_count: 曲の総数
      # - page: 現在のページ
      # - per_page: 1ページの曲の数
      #total_countは検索結果の総数で設定している
      @total_count = results["tracks"]["total"]

      # @total_count個の配列を、@per_page個ずつのページに分割して、page番目のページを取得
      @tracks = Kaminari.paginate_array(@tracks, total_count: @total_count).page(page).per(@per_page)
    else
      # トラックの中に何も取得できなかった場合
      @tracks = []
      # 検索結果が見つかりませんでした。というアラートを表示
      flash.now[:alert] = "検索結果が見つかりませんでした。"
    end


  # エラー処理を2つに分ける理由：
  # 1. エラーの原因が異なる
  #    - BadRequest（400）: APIの使用方法が間違っている（クエリの形式、認証など）
  #    - StandardError: システムの問題（ネットワーク、サーバー、プログラムなど）
  # 2. 対応方法が異なる
  #    - BadRequest: APIの使用方法を修正する必要がある
  #    - StandardError: システムの状態を確認する必要がある
  # 3. デバッグ時の対応が異なる
  #    - BadRequest: e.responseでAPIからのエラー詳細を確認
  #    - StandardError: e.messageで一般的なエラーメッセージを確認
  
  # BadRequestエラー（400）の処理
  # - 不正なリクエスト（クエリが長すぎる、不正な文字が含まれているなど）
  # - アクセストークンの期限切れ
  # - APIの利用制限超過
  rescue RestClient::BadRequest => e
    Rails.logger.error "🚨 Spotify API Usage Error: #{e.response}"
    flash.now[:alert] = "検索条件が不正です。検索条件を見直してください。"
  
  # その他の予期しないエラーの処理
  # - ネットワークエラー
  # - タイムアウト
  # - サーバーエラー（500系）
  # - プログラムのバグ
  rescue StandardError => e
    Rails.logger.error "🚨 System Error: #{e.message}"
    flash.now[:alert] = "システムエラーが発生しました。時間をおいて再度お試しください。"
  end

  # spotifyの検索結果をログに出力
  Rails.logger.debug(
    "Spotify Search Results:\n" \
    "- Query: #{query_string}\n" \
    "- Total Results: #{@total_count}\n" \
    "- Current Page: #{page}\n" \
    "- Results in Current Page: #{@tracks&.size || 0}"
  )

  # 結果の表示
  # tracksに何か入っている場合
  if @tracks.any?
    # spotify/results.html.erbをレンダリングして、
    # localsはrenderメソッドに渡すためのローカル変数を定義するためのオプション
    # 検索クエリと検索結果をビューに渡す
    render "spotify/results", locals: { 
      tracks: @tracks,
      query_string: format_query_for_display(query_string) 
    }
  else
    # 検索結果が見つからなかった場合  
    # 検索結果がありませんでした。というアラートメッセージを表示
    flash.now[:alert] = "検索結果がありませんでした。"
    # renderとredirect_toの違い：
    # - render: 同じリクエスト内でテンプレートを表示（現在の変数やflash.nowの内容が保持される）
    # - redirect_to: 新しいリクエストを発生させる（現在の変数やflash.nowの内容が失われる）
    # この場合、flash.nowを使用しているのでrenderを使う
    render "spotify/search"
  end
end

  def results
    @tracks = []

    # フォームの値をセッションに保存
    if params[:journal].present?
      session[:journal_form] = {
        title: params[:journal][:title],
        content: params[:journal][:content],
        emotion: params[:journal][:emotion],
        public: params[:journal][:public] == "1"
      } if params[:journal].present?

      Rails.logger.info "✅ Form data saved in session from results: #{session[:journal_form]}"
    end

    if params[:initial_query].present?
      @tracks = search_tracks(
        query: params[:initial_query],
        type: params[:initial_search_type]
      )
    end
  end

  def autocomplete
    token = SpotifyToken.last

    if token.nil? || token.expired?
      fetch_spotify_token
      token = SpotifyToken.last
    end

    if token.nil?
      Rails.logger.error "Spotifyトークンが取得できませんでした"
      render json: { error: "Spotifyトークンが取得できませんでした" }, status: :internal_server_error
      return
    end

    access_token = token.access_token

    url = "https://api.spotify.com/v1/search"
    headers = {
      "Authorization" => "Bearer #{access_token}",
      "Content-Type" => "application/json",
      "Accept-Language" => "ja"
    }
    query_params = URI.encode_www_form({
      q: params[:query],
      type: params[:type] || "track,artist",
      limit: 10
    })
    full_url = "#{url}?#{query_params}"

    begin
      response = RestClient.get(full_url, headers)
      results = JSON.parse(response.body)

      autocomplete_results = []

      # 検索タイプに応じて結果を整形
      if results["tracks"] && results["tracks"]["items"]
        autocomplete_results += results["tracks"]["items"].map do |track|
          {
            id: track["id"],
            name: track["name"],
            type: "track",
            artist: track["artists"].map { |a| a["name"] }.join(", ")
          }
        end
      end

      if results["artists"] && results["artists"]["items"]
        autocomplete_results += results["artists"]["items"].map do |artist|
          {
            id: artist["id"],
            name: artist["name"],
            type: "artist"
          }
        end
      end

      render json: autocomplete_results
    rescue RestClient::Unauthorized => e
      Rails.logger.error "🚨 Unauthorized: #{e.message}"
      # Workerではなく直接fetch_spotify_tokenを呼び出す
      fetch_spotify_token
      token = SpotifyToken.last
      # 再試行
      response = RestClient.get(
        full_url,
        headers.merge("Authorization" => "Bearer #{token.access_token}")
      )
      render json: JSON.parse(response.body)
    rescue => e
      Rails.logger.error "🚨 API Error: #{e.message}"
      render json: { error: "検索中にエラーが発生しました" }, status: :bad_request
    end
  end

  # 🎯 トラック選択機能
  def select_tracks
    return unless params[:selected_track].present?

    begin
      # 選択した曲の情報をセッションに保存
      session[:selected_track] = JSON.parse(params[:selected_track])

      # フォームの入力値をセッションに保存
      session[:journal_form] = {
        title: params[:journal][:title],
        content: params[:journal][:content],
        emotion: params[:journal][:emotion],
        public: params[:journal][:public] == "1"
      } if params[:journal].present?

      Rails.logger.info "✅ Track and form data saved in session: #{session[:selected_track]}, #{session[:journal_form]}"
      flash[:notice] = "曲を保存しました。"
      redirect_to new_journal_path
    rescue JSON::ParserError => e
      Rails.logger.error "🚨 JSON Parse Error: #{e.message}"
      flash.now[:alert] = "曲の保存に失敗しました。エラー: #{e.message}"
      render :search, status: :unprocessable_entity
    rescue StandardError => e
      Rails.logger.error "🚨 Unexpected Error: #{e.message}"
      flash.now[:alert] = "予期しないエラーが発生しました。"
      render :search, status: :unprocessable_entity
    end
  end

  def artist_genres
    return render json: { error: "Track ID is required" }, status: :bad_request if params[:track_id].blank?

    begin
      token = get_spotify_access_token

      # トラック情報を取得してアーティストIDを取得
      track_response = RestClient.get(
        "https://api.spotify.com/v1/tracks/#{params[:track_id]}",
        { Authorization: "Bearer #{token}" }
      )
      track_data = JSON.parse(track_response.body)
      artist_id = track_data["artists"].first["id"]

      # アーティスト情報からジャンルを取得
      artist_response = RestClient.get(
        "https://api.spotify.com/v1/artists/#{artist_id}",
        { Authorization: "Bearer #{token}" }
      )
      artist_data = JSON.parse(artist_response.body)
      genres = artist_data["genres"]

      # ジャンルを判定
      genre = determine_genre(genres)

      render json: { genre: genre }
    rescue => e
      Rails.logger.error "Error fetching Spotify genres: #{e.message}"
      render json: { error: "Failed to fetch genre information" }, status: :internal_server_error
    end
  end

  private

  def batch_fetch_artists(artist_ids, token)
    return {} if artist_ids.empty?

    # アーティストIDを20個ずつのグループに分割（Spotify APIの制限）
    artist_ids.each_slice(20).reduce({}) do |result, ids_group|
      begin
        response = RestClient.get(
          "https://api.spotify.com/v1/artists?ids=#{ids_group.join(',')}",
          {
            "Authorization" => "Bearer #{token.access_token}",
            "Content-Type" => "application/json",
            "Accept-Language" => "ja"
          }
        )

        JSON.parse(response.body)["artists"].each do |artist|
          result[artist["id"]] = artist["name"]
        end
      rescue RestClient::Unauthorized
        token.reload
        SpotifyTokenRefreshWorker.new.perform
        # 再試行
        retry
      rescue StandardError => e
        Rails.logger.error "🚨 Batch Artist Fetch Error: #{e.message}"
      end

      result
    end
  end

  def fetch_spotify_token
    uri = URI("https://accounts.spotify.com/api/token")
    request = Net::HTTP::Post.new(uri)
    request.basic_auth(ENV["SPOTIFY_CLIENT_ID"], ENV["SPOTIFY_CLIENT_SECRET"])
    request.set_form_data(
      "grant_type" => "refresh_token",
      "refresh_token" => ENV["SPOTIFY_REFRESH_TOKEN"]
    )

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end

    if response.is_a?(Net::HTTPSuccess)
      data = JSON.parse(response.body)
      # 既存のトークンを削除
      SpotifyToken.destroy_all
      # 新しいトークンを作成
      SpotifyToken.create!(
        user_id: current_user.id,  # current_userのIDを設定
        access_token: data["access_token"],
        refresh_token: ENV["SPOTIFY_REFRESH_TOKEN"],
        expires_at: Time.current + data["expires_in"].seconds
      )
    else
      Rails.logger.error "トークンの取得に失敗しました: #{response.body}"
    end
  end

  def get_spotify_access_token
    response = RestClient.post("https://accounts.spotify.com/api/token",
      {
        grant_type: "client_credentials",
        client_id: ENV["SPOTIFY_CLIENT_ID"],
        client_secret: ENV["SPOTIFY_CLIENT_SECRET"]
      },
      {
        content_type: "application/x-www-form-urlencoded"
      }
    )
    JSON.parse(response.body)["access_token"]
  end

  def determine_genre(genres)
    return "others" if genres.blank?

    genre_patterns = {
      "j-pop" => /j-pop|jpop|japanese/,
      "k-pop" => /k-pop|kpop|korean/,
      "idol" => /idol|boy band|girl group/,
      "vocaloid" => /vocaloid|virtual singer/,
      "game" => /game|gaming|chiptune/,
      "classical" => /classical|orchestra/,
      "jazz" => /jazz|bebop|swing/,
      "western" => /pop|rock|hip hop|rap/
    }

    genres.each do |genre|
      genre_patterns.each do |key, pattern|
        return key if genre.match?(pattern)
      end
    end

    "others"
  end

  def current_page
    (params[:page] || 1).to_i
  end

  def render_error(message, status = :bad_request)
    render json: { error: message }, status: status
  end

  # 検索条件を日本語表示に変換するメソッド
  def format_query_for_display(query)
    # 検索条件のマッピング
    condition_mapping = {
      'artist:' => 'アーティスト名:',
      'track:' => '曲名:',
      'album:' => 'アルバム名:',
      'year:' => '年代:'
    }
  
    # 各検索条件を日本語に変換
    formatted_query = query.dup
    condition_mapping.each do |eng, jpn|
      formatted_query.gsub!(eng, jpn)
    end
  
    formatted_query
  end
end

# 日記の管理を行うコントローラー
class JournalsController < ApplicationController
  include Ogp::OgpHandler

  # 各アクションの前に実行する処理を定義
  before_action :set_journal, only: [ :edit, :update, :destroy ]
  before_action :set_journal_for_show, only: [ :show ] # 詳細表示時に日記を取得
  before_action :store_location, only: [ :index ] # 一覧表示時に現在のURLを保存
  before_action :authenticate_user!, except: [ :show, :timeline ] # show, timeline以外はログインが必要
  before_action :authorize_journal, only: [ :edit, :update, :destroy ] # 編集・更新・削除は作成者のみ可能

  # 自分の日記一覧を表示
  def index
    # ログインユーザーの日記を取得
    @journals = current_user.journals
                            .includes(:favorites, user: { avatar_attachment: :blob })

    # 感情でフィルタリング
    @journals = @journals.where(emotion: params[:emotion]) if params[:emotion].present?

    # ジャンルでフィルタリング
    @journals = @journals.where(genre: params[:genre]) if params[:genre].present?

    # 作成日時で並び替えとページネーション
    sort_direction = params[:sort] == "asc" ? :asc : :desc
    @journals = @journals.order(created_at: sort_direction).page(params[:page]).per(6)

    # N+1問題を解消しながら、お気に入り数を取得
    @favorite_counts = @journals.each_with_object({}) do |journal, hash|
      hash[journal.id] = journal.favorites.size
    end

    # ユーザーがお気に入りしたジャーナルを取得
    favorite_journal_ids = Favorite.where(journal_id: @journals.map(&:id), user_id: current_user.id).pluck(:journal_id)
    @user_favorites = @journals.map { |journal| [ journal.id, favorite_journal_ids.include?(journal.id) ] }.to_h if current_user
  end

  # 公開された日記のタイムラインを表示
  def timeline
    # 公開された日記のみを取得
    base_query = Journal.where(public: true) .includes(:favorites, user: { avatar_attachment: :blob })

    if user_signed_in?
      following_user_ids = current_user.following.pluck(:id)
      @journals = base_query
    else
      @journals = base_query
    end

    # 感情でフィルタリング
    @journals = @journals.where(emotion: params[:emotion]) if params[:emotion].present?

    # ジャンルでフィルタリング
    @journals = @journals.where(genre: params[:genre]) if params[:genre].present?

    # 作成日時で並び替えとページネーション
    sort_direction = params[:sort] == "asc" ? :asc : :desc
    @journals = @journals.order(created_at: sort_direction).page(params[:page]).per(6)
  end

  # 日記の詳細を表示
  def show
    @journal = Journal.friendly.find(params[:id])
    @user = @journal.user
    @user_name = @user.name

    prepare_meta_tags if @journal.present?

    # クローラー以外はログインが必要
    if !user_signed_in? && !crawler?
      # 非公開記事の場合
      unless @journal.public?
        store_location
        redirect_to new_user_session_path, notice: "ログインしてください"
        nil
      end
    end
  end

  # 新規作成フォームを表示
  def new
    # トップページからのアクセス時はセッションをクリア
    if params[:from] == "top"
      session.delete(:selected_track)
      session.delete(:journal_form)
    end

    @journal = Journal.new
    @journal.emotion = nil

    if session[:selected_track].present?
      # 選択された曲の情報を日記に設定
      @journal.assign_attributes(
        song_name: session[:selected_track]["song_name"], # 曲名
        artist_name: session[:selected_track]["artist_name"], # アーティスト名
        album_image: session[:selected_track]["album_image"], # アルバム画像
        spotify_track_id: session[:selected_track]["spotify_track_id"] # SpotifyトラックID
      )
    end

    if session[:journal_form].present?
      # セッションから保存されていたフォームの入力値を復元
      form_data = session[:journal_form]
      # 日記の属性を設定
      # assign_attributesは、日記の属性を設定するメソッド
      # 使用方法は、@journal.assign_attributes(title: "タイトル", content: "内容", emotion: "感情", public: true)のように
      # 日記の属性を設定することができる
      @journal.assign_attributes(
        title: form_data["title"],
        content: form_data["content"],
        emotion: form_data["emotion"],
        public: form_data["public"]
      )
      # emotionの数値を文字列キーに変換
      # 例えば、emotionが1の場合、emotion_keyは"happy"になる
      # このように、emotionの数値を文字列キーに変換することができる
      if form_data["emotion"].present?
        emotion_key = Journal.emotions.key(form_data["emotion"])
        @journal.emotion = emotion_key if emotion_key.present?
      end

      Rails.logger.info "✅ Form data restored from session: #{@journal.attributes}"
    else
      Rails.logger.warn "⚠️ No form data found in session"
    end
  end

  # 日記を新規作成
  def create
    # ログインユーザーの日記を作成
    # buildは、日記を作成するメソッド
    # 使用方法は、@journal = current_user.journals.build(title: "タイトル", content: "内容", emotion: "感情", public: true)のように
    # 日記を作成することができる
    @journal = current_user.journals.build(journal_params)

    # セッションから選択された曲の情報を復元
    # セッションは、ブラウザのセッションを保存するもの
    # 例えば、曲を選択したときに、その曲の情報をセッションに保存しておくことができる
    # その後、日記を作成するときに、その曲の情報を復元することができる
    if session[:selected_track].present?
      @journal.assign_attributes(
        song_name: session[:selected_track]["song_name"],
        artist_name: session[:selected_track]["artist_name"],
        album_image: session[:selected_track]["album_image"],
        spotify_track_id: session[:selected_track]["spotify_track_id"],
      )
    end

    if @journal.save
      # 保存成功時はセッションをクリア
      session.delete(:selected_track)
      session.delete(:journal_form)

      redirect_to @journal, notice: "日記を保存しました。"
    else
      # 保存失敗時はエラーメッセージを表示
      Rails.logger.error "Journal save failed: #{@journal.errors.full_messages}"
      error_messages = @journal.errors.map(&:message)
      flash.now[:alert] = error_messages.join("、")
      render :new, status: :unprocessable_entity
    end
  end

  # 編集フォームを表示
  def edit
    @journal = current_user.journals.friendly.find(params[:id])

    # トップページからのアクセス時はセッションをクリア
    if params[:from] == "top"
      session.delete(:selected_track)
      session.delete(:journal_form)
    end

    # セッションから選択された曲の情報を復元
    if session[:selected_track].present?
      @journal.assign_attributes(
        song_name: session[:selected_track]["song_name"],
        artist_name: session[:selected_track]["artist_name"],
        album_image: session[:selected_track]["album_image"],
        spotify_track_id: session[:selected_track]["spotify_track_id"]
      )
    end

    # セッションからフォームの入力値を復元
    if session[:journal_form].present?
      form_data = session[:journal_form]
      @journal.assign_attributes(
        title: form_data["title"],
        content: form_data["content"],
        emotion: form_data["emotion"],
        public: form_data["public"]
      )
    end
  end

  # 日記を更新
  def update
    @journal = current_user.journals.friendly.find(params[:id])
    Rails.logger.info " Update action called with edit_source: #{session[:edit_source]}"

    # セッションから選択された曲の情報を復元（spotify_track_idを含む）
    if session[:selected_track].present?
      params[:journal].merge!(
        song_name: session[:selected_track]["song_name"],
        artist_name: session[:selected_track]["artist_name"],
        album_image: session[:selected_track]["album_image"],
        spotify_track_id: session[:selected_track]["spotify_track_id"],
      )
    end

    if @journal.update(journal_params)
      # 更新成功時は元のページにリダイレクト
      flash[:notice] = "日記を更新しました"
      # リダイレクト先のパスを取得
      # get_redirect_pathは、リダイレクト先のパスを取得するメソッド
      # リダイレクト先のパスは、リダイレクト先のページに応じて適切なパスを返す
      # 例えば、リダイレクト先のページが日記の詳細ページの場合、日記の詳細ページのパスを返す
      redirect_path = get_redirect_path
      Rails.logger.info " Redirecting to: #{redirect_path}"
      redirect_to redirect_path
    else
      # 更新失敗時はエラーメッセージを表示
      # .mapは、配列の各要素に対してメソッドを適用するメソッド
      # 例えば、@journal.errors.map(&:message)は、@journalのエラーメッセージを配列に変換する
      error_messages = @journal.errors.map(&:message)
      flash.now[:alert] = error_messages.join("、")
      render :edit, status: :unprocessable_entity
    end
  end

  # 日記を削除
  def destroy
    @journal = current_user.journals.friendly.find(params[:id])
    @journal.destroy
    flash[:notice] = "日記を削除しました"

    # 削除前のページに応じて適切なページにリダイレクト
    # 例えば、削除前のページがマイページの場合、マイページにリダイレクトする
    # 例えば、削除前のページがタイムラインの場合、タイムラインにリダイレクトする
    # 例えば、削除前のページが日記の詳細ページの場合、日記の詳細ページにリダイレクトする
    # request.refererは、リダイレクト元のURLを取得するメソッド
    # refererは、リファラーという
    # リファラーは、リダイレクト元のURLを取得するメソッド
    # 例えば、リダイレクト元のURLがマイページの場合、mypage_pathを返す
    # 例えば、リダイレクト元のURLがタイムラインの場合、timeline_journals_pathを返す
    # 例えば、リダイレクト元のURLが日記の詳細ページの場合、日記の詳細ページにリダイレクトする
    # include?は、指定された文字列が含まれているかどうかを判定するメソッド
    # 例えば、request.referer&.include?("mypage")は、リダイレクト元のURLがマイページの場合、trueを返す
    # 例えば、request.referer&.include?("timeline")は、リダイレクト元のURLがタイムラインの場合、trueを返す
    # 例えば、request.referer&.include?("journals")は、リダイレクト元のURLが日記の詳細ページの場合、trueを返す
    redirect_path = if request.referer&.include?("mypage")
                     mypage_path
    elsif request.referer&.include?("timeline")
                     timeline_journals_path
    else
                     journals_path
    end

    Rails.logger.info " Redirecting after delete to: #{redirect_path} from referer: #{request.referer}"
    redirect_to redirect_path
  end

  private

  # 編集・更新・削除用の日記取得
  # 例えば、set_journalは、日記を取得するメソッド
  def set_journal
    @journal = Journal.friendly.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    flash[:alert] = "指定された日記が見つかりませんでした"
    redirect_to journals_path
  end

  # 詳細表示用の日記取得
  def set_journal_for_show
    @journal = Journal.friendly.find(params[:id])
    # rescueは、エラーが発生した場合に実行されるメソッド
    # ActiveRecord::RecordNotFoundは、レコードが見つからない場合に発生するエラー
  rescue ActiveRecord::RecordNotFound
    redirect_to journals_path, alert: "指定された日記は存在しません"
  end

  # 現在のURLをセッションに保存
  def store_location
    return unless request.referer
    # caseは、条件分岐を行うメソッド
    case request.referer
    # whenは、条件分岐を行うメソッド
    # /journals$/ の書き方
    # 例えば、/journals$/ は、journalsのパスに一致する
    # 例えば、/mypages\/\d+$/ は、mypageのパスに数字のIDを含むパターンに一致する
    # $ は、行末を表す
    # \d+ は、1回以上の数字を表す
    # 例えば、/mypages\/\d+$/ は、mypageのパスに数字のIDを含むパターンに一致する
    when /journals$/          # index
      session[:return_to] = journals_path
    when /mypages\/\d+$/    # mypage（数字のIDを含むパターンに修正）
      session[:return_to] = mypage_path
    else
      session[:return_to] = journals_path
    end
    Rails.logger.info " Stored return location: #{session[:return_to]} from referer: #{request.referer}"
  end

  # 保存されたURLを取得
  def return_path
    session[:return_to] || journals_path
  end
  # 日記の所有者チェック
  def authorize_journal
    unless @journal.user == current_user
      # redirect_backは前のページに戻るメソッドで、
      # fallback_locationは戻れない場合のデフォルトパスを指定します
      # 例: 直接URLを入力した場合は前のページがないため、journals_pathにリダイレクトされます
      redirect_back fallback_location: journals_path, alert: "削除する権限がありません。"
    end
  end

  # Strong Parametersをjournal_paramsとして定義
  # 許可するパラメータ:
  # - title: タイトル
  # - content: 内容
  # - emotion: 感情
  # - genre: ジャンル
  # - song_name: 曲名
  # - artist_name: アーティスト名
  # - album_name: アルバム名
  # - album_image: アルバム画像URL
  # - spotify_track_id: SpotifyのトラックID
  # - public: 公開設定
  def journal_params
    params.require(:journal).permit(
      :title,
      :content,
      :emotion,
      :genre,
      :song_name,
      :artist_name,
      :album_name,
      :album_image,
      :spotify_track_id,
      :public
    )
  end

  # 編集元のURLをセッションに保存
  def store_edit_source
    return unless request.referer

    session[:previous_url] = request.referer
    Rails.logger.info " Stored previous URL: #{session[:previous_url]}"
  end

  # リダイレクト先のパスを取得
  def get_redirect_path
    # previous_urlを取得してセッションから削除
    # .deleteは、セッションから削除するメソッド
    # セッションから previous_url を取得し、同時に削除する
    # session.delete(:key) は、指定したキーの値を返しつつ、セッションからそのキーと値を削除する
    # 例: session[:previous_url] = "/mypage" の場合
    #     previous_url = session.delete(:previous_url) で
    #     previous_url には "/mypage" が代入され、
    #     session[:previous_url] は nil になる
    previous_url = session.delete(:previous_url)
    Rails.logger.info " Previous URL for redirect: #{previous_url}"

    # previous_urlがmypageの場合はmypage_pathにリダイレクト
    if previous_url&.include?("mypage")
      mypage_path
    # previous_urlがtimelineの場合はtimeline_journals_pathにリダイレクト
    elsif previous_url&.include?("timeline")
      timeline_journals_path
    else
      journals_path
    end
  end
end

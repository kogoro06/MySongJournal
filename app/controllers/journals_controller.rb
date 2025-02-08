class JournalsController < ApplicationController
  before_action :set_journal, only: [ :edit, :update, :destroy ]
  before_action :set_journal_for_show, only: [ :show ]
  before_action :store_location, only: [ :index ]
  before_action :authenticate_user!, except: [ :show, :timeline ]
  before_action :authorize_journal, only: [ :edit, :update, :destroy ]
  before_action :prepare_meta_tags, only: [ :show ]

  # 一覧表示
  def index
    @journals = current_user.journals

    # 感情フィルター
    @journals = @journals.where(emotion: params[:emotion]) if params[:emotion].present?

    # ジャンルフィルター
    @journals = @journals.where(genre: params[:genre]) if params[:genre].present?

    # 並び替え
    sort_direction = params[:sort] == "asc" ? :asc : :desc
    @journals = @journals.order(created_at: sort_direction).page(params[:page]).per(6)
  end

  # タイムライン表示
  def timeline
    base_query = Journal.where(public: true)

    if user_signed_in?
      following_user_ids = current_user.following.pluck(:id)
      @journals = base_query
    else
      @journals = base_query
    end

    # 感情フィルター
    @journals = @journals.where(emotion: params[:emotion]) if params[:emotion].present?

    # ジャンルフィルター
    @journals = @journals.where(genre: params[:genre]) if params[:genre].present?

    # 並び替え
    sort_direction = params[:sort] == "asc" ? :asc : :desc
    @journals = @journals.order(created_at: sort_direction).page(params[:page]).per(6)
  end

  # 詳細表示
  def show
    if !user_signed_in? && !crawler?
      authenticate_user!
      return
    end

    @journal = Journal.friendly.find(params[:id])
    @user = @journal.user
    @user_name = @user.name

    # 非公開記事の場合はログインチェック
    unless @journal.public?
      if !user_signed_in? && !crawler?
        store_location
        redirect_to new_user_session_path, notice: "ログインしてください"
        return
      end
    end

    prepare_meta_tags
  end

  # 新規作成フォーム表示
  def new
    # トップページからのアクセス時はセッションをクリア
    if params[:from] == "top"
      session.delete(:selected_track)
      session.delete(:journal_form)
    end

    @journal = Journal.new
    @journal.emotion = nil

    # セッションから曲の情報を復元
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
      # emotionを数値から文字列キーに変換
      if form_data["emotion"].present?
        emotion_key = Journal.emotions.key(form_data["emotion"])
        @journal.emotion = emotion_key if emotion_key.present?
      end
    end
  end

  # 日記作成処理
  def create
    @journal = current_user.journals.build(journal_params)

    # セッションから曲の情報を復元（spotify_track_idを含む）
    if session[:selected_track].present?
      @journal.assign_attributes(
        song_name: session[:selected_track]["song_name"],
        artist_name: session[:selected_track]["artist_name"],
        album_image: session[:selected_track]["album_image"],
        spotify_track_id: session[:selected_track]["spotify_track_id"],
      )
    end

    if @journal.save
      # セッションをクリア
      session.delete(:selected_track)
      session.delete(:journal_form)

      redirect_to @journal, notice: "日記を保存しました。"
    else
      Rails.logger.error "Journal save failed: #{@journal.errors.full_messages}"
      error_messages = @journal.errors.map(&:message)
      flash.now[:alert] = error_messages.join("、")
      render :new, status: :unprocessable_entity
    end
  end

  # 編集フォーム表示
  def edit
    @journal = current_user.journals.friendly.find(params[:id])

    # トップページからのアクセス時はセッションをクリア
    if params[:from] == "top"
      session.delete(:selected_track)
      session.delete(:journal_form)
    end

    # セッションから曲の情報を復元
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

  # 更新処理
  def update
    @journal = current_user.journals.friendly.find(params[:id])
    Rails.logger.info " Update action called with edit_source: #{session[:edit_source]}"

    # セッションから曲の情報を復元（spotify_track_idを含む）
    if session[:selected_track].present?
      params[:journal].merge!(
        song_name: session[:selected_track]["song_name"],
        artist_name: session[:selected_track]["artist_name"],
        album_image: session[:selected_track]["album_image"],
        spotify_track_id: session[:selected_track]["spotify_track_id"],
      )
    end

    if @journal.update(journal_params)
      flash[:notice] = "日記を更新しました"
      redirect_path = get_redirect_path
      Rails.logger.info " Redirecting to: #{redirect_path}"
      redirect_to redirect_path
    else
      error_messages = @journal.errors.map(&:message)
      flash.now[:alert] = error_messages.join("、")
      render :edit, status: :unprocessable_entity
    end
  end

  # 削除処理
  def destroy
    @journal = current_user.journals.friendly.find(params[:id])
    @journal.destroy
    flash[:notice] = "日記を削除しました"

    # リファラーに基づいて適切なページにリダイレクト
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

  def set_journal
    @journal = current_user.journals.friendly.find(params[:id])
  end

  def set_journal_for_show
    @journal = Journal.friendly.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to journals_path, alert: "指定された日記は存在しません"
  end

  def store_location
    return unless request.referer

    case request.referer
    when /journals$/          # index
      session[:return_to] = journals_path
    when /mypages\/\d+$/    # mypage（数字のIDを含むパターンに修正）
      session[:return_to] = mypage_path
    else
      session[:return_to] = journals_path
    end
    Rails.logger.info " Stored return location: #{session[:return_to]} from referer: #{request.referer}"
  end

  def return_path
    session[:return_to] || journals_path
  end

  def authorize_journal
    unless @journal.user == current_user
      redirect_back fallback_location: journals_path, alert: "削除する権限がありません。"
    end
  end

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

  def store_edit_source
    return unless request.referer

    # リファラーのURLをセッションに保存
    session[:previous_url] = request.referer
    Rails.logger.info " Stored previous URL: #{session[:previous_url]}"
  end

  def get_redirect_path
    previous_url = session.delete(:previous_url)
    Rails.logger.info " Previous URL for redirect: #{previous_url}"

    if previous_url&.include?("mypage")
      mypage_path
    elsif previous_url&.include?("timeline")
      timeline_journals_path
    else
      journals_path
    end
  end

  def crawler?
    crawler_user_agents = [
      "Twitterbot",
      "facebookexternalhit",
      "LINE-Parts/",
      "Discordbot",
      "Slackbot",
      "bot",
      "spider",
      "crawler"
    ]
    user_agent = request.user_agent.to_s.downcase
    crawler_user_agents.any? { |crawler| user_agent.include?(crawler.downcase) }
  end

  def prepare_meta_tags
    return unless @journal

    @ogp_title = @journal.song_name.presence || "MY SONG JOURNAL"
    @ogp_description = @journal.artist_name.presence || "音楽と一緒に日々の思い出を記録しよう"

    # 更新日時をクエリパラメータとして追加
    cache_key = @journal.updated_at.to_i.to_s

    @ogp_image = url_for(
      controller: :images,
      action: :ogp,
      text: "#{@journal.song_name} - #{@journal.artist_name}",
      album_image: @journal.album_image,
      v: cache_key  # versionパラメータとして更新日時を使用
    )
  end

  def check_crawler_or_authenticate
    return if crawler?
    authenticate_user!
  end

  def crawler?
    crawler_user_agents = [
      "Twitterbot",
      "facebookexternalhit",
      "LINE-Parts/",
      "Discordbot",
      "Slackbot",
      "bot",
      "spider",
      "crawler",
      "OGP Checker"
    ]

    # リファラーによるチェックを追加
    crawler_referrers = [
      "ogp.buta3.net"
    ]

    user_agent = request.user_agent.to_s.downcase
    referer = request.referer.to_s.downcase

    # User-Agentまたはリファラーのどちらかがクローラーと判定された場合にtrueを返す
    crawler_user_agents.any? { |bot| user_agent.include?(bot.downcase) } ||
    crawler_referrers.any? { |ref| referer.include?(ref) }
  end
end

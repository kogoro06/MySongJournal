class JournalsController < ApplicationController
  before_action :authenticate_user!, except: [ :show, :index, :timeline ]
  before_action :set_journal, only: [ :edit, :update, :destroy ]  # showを除外
  before_action :set_journal_for_show, only: [ :show ]  # showアクション用
  before_action :store_location, only: [ :index, :timeline ]
  before_action :authorize_journal, only: [ :edit, :update, :destroy ]
  before_action :store_edit_source, only: [ :edit ]

  # 一覧表示
  def index
    # 一覧表示時にセッションをクリア
    session.delete(:selected_track)
    session.delete(:journal_form)

    @journals = current_user.journals.order(created_at: :desc)
    @journals = @journals.where(emotion: params[:emotion]) if params[:emotion].present?
    @journals = @journals.page(params[:page]).per(6)  # 1ページあたり6件表示

    # デバッグログ
    @journals.each do |journal|
      Rails.logger.debug "Journal ID: #{journal.id}"
      Rails.logger.debug "Album Image URL: #{journal.album_image}"
    end
  end

  # タイムライン表示
  def timeline
    @journals = Journal.includes(:user).order(created_at: :desc)
    @journals = @journals.where(emotion: params[:emotion]) if params[:emotion].present?
    @journals = @journals.page(params[:page]).per(6)  # 1ページあたり6件表示
  end

  # 詳細表示
  def show
    # @journalは set_journal_for_show で設定済み
  end

  # 新規作成フォーム表示
  def new
    # トップページからのアクセス時はセッションをクリア
    if params[:from] == "top"
      session.delete(:selected_track)
      session.delete(:journal_form)
    end

    @journal = Journal.new

    # セッションから曲の情報を復元
    if session[:selected_track].present?
      @journal.assign_attributes(
        song_name: session[:selected_track]["song_name"],
        artist_name: session[:selected_track]["artist_name"],
        album_image: session[:selected_track]["album_image"],
        preview_url: session[:selected_track]["preview_url"],
        spotify_track_id: session[:selected_track]["spotify_track_id"]
      )
    end

    # セッションからフォームの入力値を復元
    if session[:journal_form].present?
      form_data = session[:journal_form]
      @journal.assign_attributes(
        title: form_data["title"],
        content: form_data["content"]
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

    if @journal.save
      # セッションをクリア
      session.delete(:selected_track)
      session.delete(:journal_form)

      # 保存成功後は一覧ページにリダイレクト
      redirect_to journals_path, notice: "日記を保存しました。"
    else
      Rails.logger.error "Journal save failed: #{@journal.errors.full_messages}"
      flash.now[:alert] = "日記の保存に失敗しました。"
      render :new, status: :unprocessable_entity
    end
  end

  # 編集フォーム表示
  def edit
    @journal = current_user.journals.find(params[:id])
    Rails.logger.info "🔍 Edit action called with referer: #{request.referer}"
  end

  # 更新処理
  def update
    @journal = current_user.journals.find(params[:id])
    Rails.logger.info "🔄 Update action called with edit_source: #{session[:edit_source]}"

    if @journal.update(journal_params)
      flash[:notice] = "日記を更新しました"
      redirect_path = get_redirect_path
      Rails.logger.info "📍 Redirecting to: #{redirect_path}"
      redirect_to redirect_path
    else
      flash.now[:alert] = "更新に失敗しました"
      render :edit, status: :unprocessable_entity
    end
  end

  # 削除処理
  def destroy
    @journal = current_user.journals.find(params[:id])
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

    Rails.logger.info "🗑️ Redirecting after delete to: #{redirect_path} from referer: #{request.referer}"
    redirect_to redirect_path
  end

  private

  def set_journal
    @journal = current_user.journals.find(params[:id])
  end

  def set_journal_for_show
    @journal = Journal.find(params[:id])  # 全ての日記から検索
  end

  def store_location
    return unless request.referer

    case request.referer
    when /journals$/          # index
      session[:return_to] = journals_path
    when /timeline$/         # timeline
      session[:return_to] = timeline_journals_path
    when /mypages\/\d+$/    # mypage（数字のIDを含むパターンに修正）
      session[:return_to] = mypage_path
    else
      session[:return_to] = journals_path
    end
    Rails.logger.info "📍 Stored return location: #{session[:return_to]} from referer: #{request.referer}"
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
      :title, :content, :emotion, :song_name, :artist_name, :album_image, :preview_url, :spotify_track_id
    )
  end

  def store_edit_source
    return unless request.referer

    # リファラーのURLをセッションに保存
    session[:previous_url] = request.referer
    Rails.logger.info "💾 Stored previous URL: #{session[:previous_url]}"
  end

  def get_redirect_path
    previous_url = session.delete(:previous_url)
    Rails.logger.info "🔍 Previous URL for redirect: #{previous_url}"

    if previous_url&.include?("mypage")
      mypage_path
    elsif previous_url&.include?("timeline")
      timeline_journals_path
    else
      journals_path
    end
  end
end

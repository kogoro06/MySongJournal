class JournalsController < ApplicationController
  before_action :authenticate_user!, except: [:show, :index]
  before_action :set_journal, only: [:show, :edit, :update, :destroy]
  before_action :authorize_journal, only: [:edit, :update, :destroy]

  # 一覧表示
  def index
    @emotion_filter = params[:emotion]
    @journals = current_user.journals
    @journals = @journals.where(emotion: @emotion_filter) if @emotion_filter.present?
    @journals = @journals.order(created_at: :asc)
  end

  # 詳細表示
  def show
    # `set_journal` ですでに @journal をセットしているので、ここは不要
  end

  # 新規作成フォーム表示
  def new
    @journal = Journal.new

    # セッションに選択されたトラック情報がある場合、それを反映
    if session[:selected_track].present?
      track = session[:selected_track]
      Rails.logger.debug "🎵 Session Track Data: #{track.inspect}"

      @journal.song_name = track["song_name"]
      @journal.artist_name = track["artist_name"]
      @journal.album_image = track["album_image"]
      @journal.preview_url = track["preview_url"]
      @journal.spotify_track_id = track["spotify_track_id"]

      # セッションのデータは使用後にクリア
      session.delete(:selected_track)
    end
  end

  # 日記作成処理
  def create
    @journal = current_user.journals.new(journal_params)

    if session[:selected_track].present?
      track = session[:selected_track]
      @journal.song_name ||= track["song_name"]
      @journal.artist_name ||= track["artist_name"]
      @journal.album_image ||= track["album_image"]
      @journal.preview_url ||= track["preview_url"]
      @journal.spotify_track_id ||= track["spotify_track_id"]
    end

    Rails.logger.debug "🚀 Journal Params: #{journal_params.inspect}"
    Rails.logger.debug "🎵 Session Track: #{session[:selected_track].inspect}"

    if @journal.save
      session.delete(:selected_track) # 使用後はセッションをクリア
      redirect_to journals_path, notice: "日記の作成に成功しました."
    else
      Rails.logger.debug "❌ Journal save errors: #{@journal.errors.full_messages}"
      render :new, status: :unprocessable_entity
    end
  end

  # 編集フォーム表示
  def edit
  end

  # 更新処理
  def update
    if @journal.update(journal_params)
      redirect_to journals_path, notice: "日記が更新されました."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # 削除処理
  def destroy
    @journal.destroy
    redirect_to journals_path, notice: "日記が削除されました."
  end

  private

  # 日記をセットする
  def set_journal
    @journal = current_user.journals.find(params[:id])
  end

  # ユーザー権限の確認
  def authorize_journal
    unless @journal.user == current_user
      redirect_back fallback_location: journals_path, alert: "削除する権限がありません。"
    end
  end

  # 日記パラメータの許可
  def journal_params
    params.require(:journal).permit(
      :title, :content, :emotion, :song_name, :artist_name, :album_image, :preview_url, :spotify_track_id
    ).tap do |journal_params|
      journal_params[:emotion] = journal_params[:emotion].to_i if journal_params[:emotion].present?
    end
  end
end

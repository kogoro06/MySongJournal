class JournalsController < ApplicationController
  before_action :authenticate_user!, except: [ :show, :index ]
  before_action :set_journal, only: [ :show, :edit, :update, :destroy ]
  before_action :authorize_journal, only: [ :edit, :update, :destroy ]

  # 一覧表示
  def index
    @emotion_filter = params[:emotion]
    @journals = current_user.journals
    @journals = @journals.where(emotion: @emotion_filter) if @emotion_filter.present?
    @journals = @journals.order(created_at: :asc)
  end

  # 詳細表示
  def show
    @journal = Journal.find(params[:id])
  end

  # 新規作成フォーム表示
  def new
    @journal = Journal.new

    if session[:selected_track].present?
      track = session[:selected_track]
      Rails.logger.debug "🎵 Session Track Data: #{track.inspect}"

      @journal.song_name = track["song_name"]
      @journal.artist_name = track["artist_name"]
      @journal.album_image = track["album_image"]
      @journal.preview_url = track["preview_url"]
    end
  end

  def create
    @journal = current_user.journals.new(journal_params)

    if session[:selected_track].present?
      track = session[:selected_track]
      @journal.song_name ||= track["song_name"]
      @journal.artist_name ||= track["artist_name"]
      @journal.album_image ||= track["album_image"]
      @journal.preview_url ||= track["preview_url"]
    end

    Rails.logger.debug "🚀 Journal Params: #{journal_params.inspect}"
    Rails.logger.debug "🎵 Session Track: #{session[:selected_track].inspect}"

    if @journal.save
      session.delete(:selected_track)
      redirect_to journals_path, notice: "日記の作成に成功しました."
    else
      Rails.logger.debug "❌ Journal save errors: #{@journal.errors.full_messages}"
      render :new
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

  def set_journal
    @journal = current_user.journals.find(params[:id])
  end

  def authorize_journal
    unless @journal.user == current_user
      redirect_back fallback_location: journals_path, alert: "削除する権限がありません。"
    end
  end

  def journal_params
    params.require(:journal).permit(
      :title, :content, :emotion, :song_name, :artist_name, :album_image, :preview_url
    ).tap do |journal_params|
      journal_params[:emotion] = journal_params[:emotion].to_i if journal_params[:emotion].present?
    end
  end
end

class JournalsController < ApplicationController
  before_action :authenticate_user!, except: [ :show, :index ]
  before_action :set_journal, only: [ :show, :edit, :update, :destroy ]
  before_action :authorize_journal, only: [ :edit, :update, :destroy ]
  def index
    @emotion_filter = params[:emotion] # フィルター条件を取得
    @journals = if @emotion_filter.present?
                  current_user.journals.where(emotion: @emotion_filter) # ログインユーザーの日記を絞り込み
    else
                  current_user.journals # ログインユーザーの日記のみ取得
    end
  end
  def show
    @journals = Journal.find(params[:id])
  end

  def new
    @journal = Journal.new
  end

  def create
    Rails.logger.debug "Received params: #{params.inspect}"
    @journal = current_user.journals.new(journal_params)
    if @journal.save
      redirect_to journals_path, notice: "日記の作成に成功しました."
    else
      Rails.logger.debug "Journal save errors: #{@journal.errors.full_messages}"
      render :new
    end
  end

  def edit
    @journal = Journal.find(params[:id])
  end

  def update
    if @journal.update(journal_params)
      redirect_to journals_path, notice: "日記が更新されました."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @journal.destroy
    redirect_to journals_path, notice: "日記が削除されました."
  end

  def timeline
    @journals = Journal.includes(:user).order(created_at: :desc)
    @journals = @journals.where(emotion: params[:emotion]) if params[:emotion].present?
  end

  private

  def journal_params
    params.require(:journal).permit(:title, :emotion, :content, :artist_name, :song_name, :preview_url, :album_image)
  end

  def set_journal
    @journal = Journal.find(params[:id])
  end
  def authorize_journal
    unless @journal.user == current_user
      redirect_to journals_path, alert: "削除する権限がありません。"
    end
  end

  def journal_params
    params.require(:journal).permit(:title, :content, :emotion, :artist_name, :song_name).tap do |p|
      p[:emotion] = p[:emotion].to_i if p[:emotion].present?
    end
  end
end

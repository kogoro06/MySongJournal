class JournalsController < ApplicationController
  before_action :authenticate_user!, except: [:show, :index]
  before_action :set_journal, only: [:show, :edit, :update, :destroy]
  before_action :authorize_journal, only: [:edit, :update, :destroy]

  def index
    @journals = Journal.all
  end

  def show
    @journals = Journal.find(params[:id])
  end

  def new
    @journal = Journal.new
  end

  def create
    @journal = current_user.journals.new(journal_params)
    if @journal.save
      redirect_to journals_path, notice: "日記の作成に成功しました."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @journal.update(journal_params)
      redirect_to @journal, notice: "Journal was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @journal.destroy
    redirect_to journals_path, notice: "Journal was successfully deleted."
  end

  private

  def journal_params
    params.require(:journal).permit(:title, :emotion, :content, :artist_name, :song_name, :preview_url, :album_image)
  end

  def set_journal
    @journal = Journal.find(params[:id])
  end

  def authorize_journal
    redirect_to journals_path, alert: "You are not authorized to perform this action." unless @journal.user == current_user
  end
end

class FavoritesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_journal

  def create
    @favorite = current_user.favorites.find_or_initialize_by(journal: @journal)
    
    if @favorite.persisted? || @favorite.save
      @journal.reload
      respond_to do |format|
        format.turbo_stream
      end
    else
      render_error_response
    end
  rescue ActiveRecord::RecordNotUnique
    respond_to do |format|
      format.turbo_stream
    end
  end

  def destroy
    @favorite = current_user.favorites.find_by(journal: @journal)
    
    if @favorite&.destroy
      @journal.reload
      respond_to do |format|
        format.turbo_stream
      end
    else
      render_error_response
    end
  end

  private

  def set_journal
    @journal = Journal.friendly.find(params[:journal_id])
  rescue ActiveRecord::RecordNotFound
    render_error_response
  end

  def render_error_response
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "favorite_button_#{@journal.id}",
          html: "エラーが発生しました"
        )
      end
      format.html do
        flash[:alert] = "いいねの処理中にエラーが発生しました"
        redirect_back(fallback_location: journals_path)
      end
    end
  end
end

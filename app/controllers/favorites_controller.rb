class FavoritesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_journal

  def create
    favorite = current_user.favorites.build(journal_id: @journal.id)
    favorite.save
    render_favorite_button
  end

  def destroy
    favorite = current_user.favorites.find_by(journal_id: @journal.id)
    favorite.destroy
    render_favorite_button
  end

  private

  def set_journal
    @journal = Journal.find(params[:journal_id])
  end

  def render_favorite_button
    render turbo_stream: turbo_stream.replace(
      "journal-card-#{@journal.id}",
      partial: 'journals/journal_card',
      locals: { journal: @journal }
    )
  end
end 
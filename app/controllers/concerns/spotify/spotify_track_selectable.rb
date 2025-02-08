module Spotify::SpotifyTrackSelectable
  extend ActiveSupport::Concern
  include Spotify::SpotifyApiRequestable

  def select_tracks
    return unless params[:selected_track].present?
    save_track_and_form_data
    redirect_to new_journal_path
  rescue StandardError => e
    handle_selection_error(e)
  end

  private

  def save_track_and_form_data
    session[:selected_track] = JSON.parse(params[:selected_track])
    save_journal_form if params[:journal].present?
  end

  def save_journal_form
    session[:journal_form] = {
      title: params[:journal][:title],
      content: params[:journal][:content],
      emotion: params[:journal][:emotion]
    }
  end

  def handle_selection_error(error)
    Rails.logger.error "🚨 Track Selection Error: #{error.message}"
    flash.now[:alert] = "曲の選択中にエラーが発生しました。"
    render :search, status: :unprocessable_entity
  end
end

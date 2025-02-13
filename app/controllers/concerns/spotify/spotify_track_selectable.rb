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
    return unless params[:journal].present?
    flash.now[:alert] = "フォームデータが存在しません"
    # digメソッドは、ネストされたハッシュから安全に値を取得するメソッドです
    # 例: params = { journal: { title: "タイトル" } } の場合
    # params[:journal][:title] と書くと、params[:journal]がnilの時にエラーになります
    # params.dig(:journal, :title) と書くと、途中がnilでもnilを返すだけで安全です
    # 下記の場合、params[:journal]がnilの時もエラーにならずnilを返します
    session[:journal_form] = {
      title: params.dig(:journal, :title),
      content: params.dig(:journal, :content),
      emotion: params.dig(:journal, :emotion),
      public: params.dig(:journal, :public)
    }.compact
  end

  def handle_selection_error(error)
    Rails.logger.error "🚨 Track Selection Error: #{error.message}"
    flash.now[:alert] = "曲の選択中にエラーが発生しました。"
    render :search, status: :unprocessable_entity
  end
end

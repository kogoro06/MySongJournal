class JournalsController < ApplicationController
  before_action :authenticate_user!, except: [ :show, :index ]
  before_action :set_journal, only: [ :show, :edit, :update, :destroy ]
  before_action :authorize_journal, only: [ :edit, :update, :destroy ]

  # 一覧表示
  def index
    # 一覧表示時にセッションをクリア
    session.delete(:selected_track)
    session.delete(:journal_form)

    @journals = current_user.journals.order(created_at: :desc)
    @journals = @journals.where(emotion: params[:emotion]) if params[:emotion].present?
  end

  # 詳細表示
  def show
    # `set_journal` ですでに @journal をセットしているので、ここは不要
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
    )
  end
end

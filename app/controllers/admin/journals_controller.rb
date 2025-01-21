module Admin
  class JournalsController < Admin::BaseController
    before_action :set_journal, only: [ :show, :edit, :update, :destroy ]

    def index
      @journals = Journal.includes(:user).order(created_at: :desc)
    end

    def show
    end

    def edit
    end

    def update
      if @journal.update(journal_params)
        redirect_to admin_journal_path(@journal), notice: "日記を更新しました"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @journal.destroy!
      redirect_to admin_journals_path, notice: "日記を削除しました", status: :see_other
    end

    private

    def set_journal
      @journal = Journal.find(params[:id])
    end

    def journal_params
      params.require(:journal).permit(:title, :artist_name, :song_name, :emotion)
    end
  end
end

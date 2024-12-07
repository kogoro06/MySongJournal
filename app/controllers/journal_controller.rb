class JournalController < ApplicationController
before_action :authenticate_user!, except: [ :show, :index ]

  def index
    @journals = Journal.all
  end

  def show
    @journal = Journal.find(params[:id])
  end

  def new
    @journal = Journal.new
  end

  def create
    @journal = current_user.journals.new(journal_params)

    if @journal.save
    redirect_to @journal, notice: "Journal was successfully created."
    else
      render :new
    end
  end
end

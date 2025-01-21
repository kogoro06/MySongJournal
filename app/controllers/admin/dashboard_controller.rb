class Admin::DashboardController < Admin::BaseController
  def index
    @total_users = User.count
    @total_journals = Journal.count
    # その他の管理画面で必要な情報
  end
end

class Authentications::UserActivitiesController < DashboardsController
  def index
    @user_activities = Current.user.user_activities.order(created_at: :desc)
  end
end

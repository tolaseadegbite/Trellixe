class Authentications::UserActivitiesController < ApplicationController
  def index
    @user_activities = Current.user.user_activities.order(created_at: :desc)
  end
end

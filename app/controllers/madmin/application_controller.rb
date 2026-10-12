module Madmin
  class ApplicationController < Madmin::BaseController
    before_action :authenticate_admin_user

    def authenticate_admin_user
      redirect_to root_path, alert: "Not authorized." unless current_user&.admin?
    end

    # Use the same current_user from the application
    def current_user
      Current.user
    end

    def user_signed_in?
      current_user.present?
    end
  end
end

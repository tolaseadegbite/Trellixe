module Madmin
  class ApplicationController < Madmin::BaseController
    # Engine controllers don't run the main ApplicationController chain, so
    # the session must be resolved here (identical logic to the app's
    # set_current_user_from_session) before any authorization check.
    before_action :set_current_user_from_session
    before_action :authenticate_admin_user

    def authenticate_admin_user
      # Engine controllers don't inherit the app's route helpers, so the
      # plain path string stands in for root_path here.
      redirect_to "/", alert: "Not authorized." unless current_user&.admin?
    end

    def current_user
      Current.user
    end

    def user_signed_in?
      current_user.present?
    end

    private

    def set_current_user_from_session
      Current.session = Session.find_by_id(cookies.signed[:session_token])
    end
  end
end

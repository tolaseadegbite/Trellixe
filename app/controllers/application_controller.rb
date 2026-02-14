class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  # allow_browser versions: :modern

  include Pagy::Backend
  include SetCurrentRequestDetails

  # Make these methods available as helpers in all views
  helper_method :current_user, :user_signed_in?, :current_role, :admin?
  helper_method :context_notifications

  # --- CALLBACK ORDER IS CRITICAL ---
  # 1. Set IP and User Agent
  before_action :set_current_request_details
  # 2. Find the User from the Session cookie
  before_action :set_current_user_from_session
  # 3. Find the Active Workspace (Requires User to be set first)
  before_action :set_current_account
  # 4. Enforce Login (Redirect if no User)
  before_action :authenticate
  # 5. Wraps request in time zone block
  around_action :switch_time_zone, if: :current_user

  def pending_follow_ups
    # Scoped to Current User AND Current Account logic should happen here
    # For now, we fetch tasks assigned to the user
    @pending_follow_ups = current_user.follow_up_tasks
                                      .where(completed_at: nil)
                                      .order(due_at: :asc)
                                      .includes(invitation: [ :event, :contact ])
                                      .limit(15)
  end

  # Helper for views/controllers to check permissions quickly
  def current_role
    return nil unless user_signed_in? && Current.account
    @current_role ||= Current.user.memberships.find_by(account: Current.account)&.role
  end

  def admin?
    current_role == "admin"
  end

  def context_notifications
    # Memoize to prevent multiple DB queries in one request
    @_context_notifications ||= begin
      # 1. Base Scope: The current user
      scope = current_user.notifications

      # 2. Filter: Only this account OR Global (nil)
      #    This prevents "Account 1" events from showing in "Account 2"
      scope = scope.where(account_id: [ Current.account.id, nil ]) if Current.account

      # 3. Sort
      scope.newest_first
    end
  end

  private

  # This method now ONLY sets the current user state for the request.
  # It runs on every page, even public ones, so we always know if a user is logged in.
  def set_current_user_from_session
    if session_record = Session.find_by_id(cookies.signed[:session_token])
      Current.session = session_record
    end
  end

  # This is the new helper method to access the currently logged-in user.
  def current_user
    Current.user
  end

  # This is the new boolean helper to check if a user is logged in.
  def user_signed_in?
    current_user.present?
  end

  # Your authenticate method is now cleaner. It USES the helpers.
  # Its only job is to protect pages by redirecting.
  def authenticate
    unless user_signed_in?
      redirect_to sign_in_path, alert: "You must be signed in to access this page."
    end
  end

  # This is your existing method, it's perfect.
  def set_current_request_details
    Current.user_agent = request.user_agent
    Current.ip_address = request.ip
  end

  # This is your existing method, it's perfect.
  def require_sudo
    unless Current.session.sudo?
      redirect_to new_sessions_sudo_path(proceed_to_url: request.original_url)
    end
  end

  def switch_time_zone(&block)
    # Use the user's timezone, or fallback to UTC if invalid
    Time.use_zone(current_user.time_zone || "UTC", &block)
  end
end

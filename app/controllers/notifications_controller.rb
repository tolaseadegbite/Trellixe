class NotificationsController < DashboardsController
  before_action :authenticate

  # Opening the list is triage: every visit (mobile bell, desktop
  # popover "View all") marks the in-scope unread notifications read,
  # silently. Rows render read on first paint; badges refresh with the
  # layout render that follows this action.
  def index
    mark_scope_as_read

    @notifications = current_user.notifications
                                 .where(account_id: [ Current.account.id, nil ])
                                 .newest_first.limit(50)
  end

  def show
    @notification = current_user.notifications.find(params[:id])

    @notification.mark_as_read!

    redirect_to helpers.notification_destination(@notification)
  end

  def mark_all_as_read
    mark_scope_as_read

    redirect_back(fallback_location: notifications_path, notice: "All notifications marked as read.")
  end

  private

  # Single definition of "everything this user hasn't seen in this
  # workspace": account notifications plus global (account-less) ones.
  def mark_scope_as_read
    scope = current_user.notifications.unread

    if Current.account
      scope = scope.where(account_id: [ Current.account.id, nil ])
    end

    scope.update_all(read_at: Time.current, seen_at: Time.current)
  end
end

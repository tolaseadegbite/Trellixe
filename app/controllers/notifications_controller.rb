class NotificationsController < DashboardsController
  before_action :authenticate

  def index
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
    scope = current_user.notifications.unread

    if Current.account
      scope = scope.where(account_id: [ Current.account.id, nil ])
    end

    scope.update_all(read_at: Time.current, seen_at: Time.current)

    redirect_back(fallback_location: notifications_path, notice: "All notifications marked as read.")
  end
end

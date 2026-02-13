class DashboardsController < ApplicationController
  layout "dashboard"

  def show
    @pending_follow_ups = current_user.follow_up_tasks
                                    .where(completed_at: nil)
                                    .order(due_at: :asc)
                                    .includes(invitation: [ :event, :contact ])
                                    .limit(15)

    @upcoming_events = Current.account.events
                                 .where("starts_at > ?", Time.current)
                                 .order(starts_at: :asc)
                                 .limit(15)
  end
end

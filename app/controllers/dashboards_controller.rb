class DashboardsController < ApplicationController
  layout "dashboard"

  def show
    account = Current.account
    @upcoming_events = account.events.upcoming.order(starts_at: :asc).limit(4).includes(:invitations)
    @pending_tasks = current_user.follow_up_tasks.for_account(account).pending
                                 .order(due_at: :asc).limit(8)
                                 .includes(invitation: [ :event, :contact ])
    @overdue_count = current_user.follow_up_tasks.for_account(account).pending.where("due_at < ?", Time.current).count
    @contacts_count = account.contacts.count
    @week_contacts = account.contacts.where("contacts.created_at >= ?", 7.days.ago).count
    invites = Invitation.joins(:event).where(events: { owner_type: "Account", owner_id: account.id })
    @attendance_rate = invites.any? ? (invites.attended.count * 100.0 / invites.count).round : 0
    @invites_count = invites.count
    @follow_ups_count = invites.joins(:follow_up_tasks).distinct.count
    @follow_up_rate = @invites_count.positive? ? (@follow_ups_count * 100.0 / @invites_count).round : 0
  end
end

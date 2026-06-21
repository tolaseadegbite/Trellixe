class DashboardsController < ApplicationController
  layout "dashboard"

  def show
    base = current_user.follow_up_tasks
                        .pending
                        .for_account(Current.account)
                        .includes(invitation: [ :event, :contact ])
                        .order(due_at: :asc)

    @overdue = base.where(due_at: ...Time.current).limit(5)
    @due_today = base.where(due_at: Time.current.beginning_of_day..Time.current.end_of_day).limit(5)
    @due_this_week = base.where(due_at: (Time.current + 1.day).beginning_of_day..(Time.current + 7.days).end_of_day).limit(5)

    @events_today = Current.account.events
                             .where(starts_at: Time.current.all_day)
                             .order(starts_at: :asc)

    @upcoming_events = Current.account.events
                                .where("starts_at > ?", Time.current.end_of_day)
                                .order(starts_at: :asc)
                                .limit(5)

    @contacts_count = Current.account.contacts.count
    @events_this_month = Current.account.events
                                .where(starts_at: Time.current.beginning_of_month..Time.current.end_of_month)
                                .count
    @total_tasks = current_user.follow_up_tasks.for_account(Current.account).count
    @done_tasks = current_user.follow_up_tasks.for_account(Current.account).where.not(completed_at: nil).count
    @pending_tasks = @total_tasks - @done_tasks
    @task_completion = @total_tasks > 0 ? ((@done_tasks.to_f / @total_tasks) * 100).round : 0
    @team_count = Current.account.memberships.count
  end
end

class FollowUpTasksController < DashboardsController
  def index
    # 1. Find tasks assigned to ME
    # 2. Filter tasks where the associated Event belongs to the CURRENT ACCOUNT
    base_query = current_user.follow_up_tasks
                             .where(completed_at: nil)
                             .joins(invitation: :event)
                             .where(events: { owner_type: "Account", owner_id: Current.account.id })

    @q = base_query.ransack(params[:q])

    records = @q.result
                    .includes(invitation: [ :contact, :event ])
                    .order(due_at: :asc)

    @pagy, @follow_up_tasks = pagy(records)

    @filterable_events = Event.where(id: base_query.joins(:invitation).select("invitations.event_id"))
                            .distinct
                            .order(:name)
  end
end

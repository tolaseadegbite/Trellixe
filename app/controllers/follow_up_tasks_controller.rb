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

  def bulk_update
    @task_ids = params[:task_ids] || []
    action_type = params[:commit] # The value of the clicked button

    if @task_ids.empty?
      flash.now[:alert] = "No tasks selected."
      render_flash
      return
    end

    # 1. Secure Scope: Find tasks assigned to user AND belonging to current account context
    @tasks = current_user.follow_up_tasks
                         .where(id: @task_ids, completed_at: nil)
                         .joins(invitation: :event)
                         .where(events: { owner_type: "Account", owner_id: Current.account.id })

    count = @tasks.count

    if count == 0
      flash.now[:alert] = "No valid tasks found."
      render_flash
      return
    end

    # 2. Logic Branch
    case action_type
    when "Mark Complete"
      @tasks.update_all(completed_at: Time.current, updated_at: Time.current)
      flash.now[:notice] = "Marked #{count} tasks as complete."
    when "Snooze 24h"
      # Shift due_at forward by 1 day
      # We use SQL directly to keep relative time differences if desired,
      # or just set a fixed time. Simple fixed time is safer for bulk actions.
      new_time = 24.hours.from_now
      @tasks.update_all(due_at: new_time, updated_at: Time.current)
      flash.now[:notice] = "Snoozed #{count} tasks for 24 hours."
    end

    # 3. Response
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to follow_up_tasks_path, notice: flash.now[:notice] }
    end
  end

  private

  def render_flash
    render turbo_stream: turbo_stream.update("flash_messages", partial: "shared/flash")
  end
end

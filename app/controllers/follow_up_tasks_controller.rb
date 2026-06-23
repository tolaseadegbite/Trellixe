class FollowUpTasksController < DashboardsController
  def index
    @scope = params[:scope] == "past" ? "past" : "pending"

    base_query = current_user.follow_up_tasks.for_account(Current.account)

    base_query = if @scope == "past"
      base_query.where.not(completed_at: nil)
    else
      base_query.pending
    end

    @q = base_query.ransack(params[:q])

    records = @q.result
                    .includes(invitation: [ :contact, :event ], interaction_logs: :user)
                    .order(@scope == "past" ? { completed_at: :desc } : { due_at: :asc })

    @pagy, @follow_up_tasks = pagy(records)
  end

  def bulk_update
    @task_ids = params[:task_ids] || []
    action_type = params[:commit]

    if @task_ids.empty?
      flash.now[:alert] = "No tasks selected."
      render_flash
      return
    end

    @tasks = current_user.follow_up_tasks
                         .where(id: @task_ids)
                         .pending
                         .for_account(Current.account)

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

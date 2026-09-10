class FollowUpTasksController < DashboardsController
  include FollowUpQueue

  def index
    @scope = params[:scope] == "past" ? "past" : "pending"

    base_query = current_user.follow_up_tasks.for_account(Current.account)

    base_query = if @scope == "past"
      base_query.where.not(completed_at: nil)
    else
      base_query.pending
    end

    @q = base_query.ransack(params[:q])

    if @scope == "pending"
      @queue = queue_state(params[:focus])
      @pagy, _page = pagy(@queue.records) # footer page-nav only; the queue reads @queue
    else
      records = @q.result
                      .includes(invitation: [ :contact, :event ], interaction_logs: :user)
                      .order(completed_at: :desc)

      @pagy, @follow_up_tasks = pagy(records)
    end

    @queue_context = FollowUpQueue.context_for(params, @scope)
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
    when "Mark Complete", "Done"
      completed_ids = @tasks.pluck(:id)
      @tasks.update_all(completed_at: Time.current, updated_at: Time.current)
      mark_completed_notifications_read(completed_ids)
      flash.now[:notice] = "Marked #{count} #{"task".pluralize(count)} as complete."
    when "Snooze 24h"
      # Shift due_at forward by 1 day
      # We use SQL directly to keep relative time differences if desired,
      # or just set a fixed time. Simple fixed time is safer for bulk actions.
      new_time = 24.hours.from_now
      @tasks.update_all(due_at: new_time, updated_at: Time.current)
      flash.now[:notice] = "Snoozed #{count} #{"task".pluralize(count)} for 24 hours."
    end

    # 3. Response
    respond_to do |format|
      format.turbo_stream do
        # The pending table is gone — the queue re-renders from the same
        # loader the index uses, so counts and promotion stay correct.
        @queue = queue_state
        @pagy, _page = pagy(@queue.records)
        @queue_context = FollowUpQueue.context_for(params, "pending")
      end
      format.html { redirect_to follow_up_tasks_path, notice: flash.now[:notice] }
    end
  end

  private

  # Mirrors InteractionLogsController#mark_related_notifications_read for a
  # set of tasks: completing work clears its badges. Snooze deliberately
  # skips this — pending work keeps its badge lit.
  def mark_completed_notifications_read(task_ids)
    gids = FollowUpTask.where(id: task_ids).map { |t| t.to_gid.to_s }
    event_ids = Noticed::Event.where(type: "FollowUpTaskNotifier")
                              .where("params #>> '{task, _aj_globalid}' IN (?)", gids)
                              .pluck(:id)
    current_user.notifications.where(event_id: event_ids)
                .update_all(read_at: Time.current, seen_at: Time.current)
  end

  def render_flash
    render turbo_stream: turbo_stream.update("flash_messages", partial: "shared/flash")
  end
end

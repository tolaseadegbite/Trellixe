class InteractionLogsController < DashboardsController
  before_action :set_follow_up_task, only: [:new, :create]

  def new
    # Build a new interaction_log associated with the task, contact, and user.
    @interaction_log = @follow_up_task.interaction_logs.build(
      contact: @follow_up_task.invitation.contact,
      user: current_user
    )
  end

  def create
    @interaction_log = @follow_up_task.interaction_logs.build(interaction_log_params)
    @interaction_log.contact = @follow_up_task.invitation.contact
    @interaction_log.user = current_user

    respond_to do |format|
      ActiveRecord::Base.transaction do
        @interaction_log.save!
        @follow_up_task.update!(completed_at: Time.current)
      end

      # format.turbo_stream
      format.html { redirect_to follow_up_tasks_path, notice: "Follow-up successfully logged!" }

    rescue ActiveRecord::RecordInvalid
      format.turbo_stream { render :new, status: :unprocessable_entity }
      format.html { render :new, status: :unprocessable_entity }
    end
  end

  private

  def set_follow_up_task
    # Find the task securely, scoped to the current user.
    @follow_up_task = current_user.follow_up_tasks.find(params[:follow_up_task_id])
  end

  def interaction_log_params
    params.require(:interaction_log).permit(:note)
  end
end
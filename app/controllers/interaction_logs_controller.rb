class InteractionLogsController < DashboardsController
  before_action :set_follow_up_task, only: [ :new, :create ]
  before_action :set_interaction_log, only: [ :edit, :update, :destroy, :confirm_delete ]
  before_action :authorize_owner!, only: [ :edit, :update, :destroy, :confirm_delete ]

  def new
    @interaction_log = @follow_up_task.interaction_logs.build(
      contact: @follow_up_task.invitation.contact,
      user: current_user
    )
  end

  def edit
  end

  def confirm_delete
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

      mark_related_notifications_read

      format.turbo_stream
      format.html { redirect_to follow_up_tasks_path, notice: "Follow-up successfully logged!" }

    rescue ActiveRecord::RecordInvalid
      format.turbo_stream { render :new, status: :unprocessable_entity }
      format.html { render :new, status: :unprocessable_entity }
    end
  end

  def update
    respond_to do |format|
      if @interaction_log.update(interaction_log_params)
        format.turbo_stream
        format.html { redirect_back_or_to contact_path(@interaction_log.contact), notice: "Log updated." }
      else
        format.turbo_stream { render :edit, status: :unprocessable_entity }
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @interaction_log.destroy!
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_back_or_to contact_path(@interaction_log.contact), notice: "Log deleted." }
    end
  end

  private

  def set_follow_up_task
    @follow_up_task = current_user.follow_up_tasks.for_account(Current.account).find(params[:follow_up_task_id])
  end

  def set_interaction_log
    @interaction_log = InteractionLog.joins(follow_up_task: { invitation: :event })
                                     .where(events: { owner_type: "Account", owner_id: Current.account.id })
                                     .find(params[:id])
  end

  def authorize_owner!
    unless can_edit_log?(@interaction_log)
      redirect_back_or_to contact_path(@interaction_log.contact), alert: "You can only edit your own logs."
    end
  end

  def interaction_log_params
    params.require(:interaction_log).permit(:note)
  end

  def mark_related_notifications_read
    task_gid = @follow_up_task.to_gid.to_s
    event_ids = Noticed::Event.where(type: "FollowUpTaskNotifier")
                              .where("params #>> '{task, _aj_globalid}' = ?", task_gid)
                              .pluck(:id)
    current_user.notifications.where(event_id: event_ids)
                .update_all(read_at: Time.current, seen_at: Time.current)
  end
end

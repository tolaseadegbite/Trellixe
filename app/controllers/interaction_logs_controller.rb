class InteractionLogsController < DashboardsController
  before_action :set_follow_up_task, only: [ :new, :create ], if: -> { params[:follow_up_task_id].present? }
  before_action :set_contact, only: [ :new, :create ], if: -> { params[:contact_id].present? }
  before_action :set_interaction_log, only: [ :edit, :update, :destroy, :confirm_delete ]
  before_action :authorize_owner!, only: [ :edit, :update, :destroy, :confirm_delete ]

  def new
    if @follow_up_task
      @interaction_log = @follow_up_task.interaction_logs.build(
        contact: @follow_up_task.invitation.contact,
        user: current_user
      )
      # When logging from the follow-up queue, the form posts back with this
      # context so the queue can advance in place after a successful save.
      @queue_context = params[:from] == "queue" ? params.slice(:from, :scope, :q).to_unsafe_h : nil
    else
      @interaction_log = @contact.interaction_logs.build(user: current_user)
    @contact_events = @contact.events.distinct.order(starts_at: :desc)
    if params[:event_id].present?
      @preset_event = Current.account.events.find(params[:event_id])
    end
      # Preset (locked) event when linked from an event-scoped entry point
      # such as the contact's open-follow-ups strip. Scoped find: tampered
      # ids 404 instead of attaching foreign events.
      if params[:event_id].present?
        @preset_event = Current.account.events.find(params[:event_id])
        @interaction_log.event = @preset_event
      else
        @interaction_log.event = @contact_events.first
      end
    end
  end

  def edit
  end

  def confirm_delete
  end

  def create
    return create_from_follow_up_task if @follow_up_task

    @interaction_log = @contact.interaction_logs.build(interaction_log_params)
    @interaction_log.user = current_user
    # Scope the chosen event to the account — tampered ids 404 via the scoped find.
    if params[:interaction_log][:event_id].present?
      @interaction_log.event = Current.account.events.find(params[:interaction_log][:event_id])
    end
    @contact_events = @contact.events.distinct.order(starts_at: :desc)

    respond_to do |format|
      if @interaction_log.save
        flash.now[:notice] = "Interaction logged."
        format.turbo_stream { render :create_for_contact }
        format.html { redirect_to contact_path(@contact), notice: "Interaction logged." }
      else
        format.turbo_stream { render :new, status: :unprocessable_entity }
        format.html { render :new, status: :unprocessable_entity }
      end
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

  def set_contact
    @contact = Current.account.contacts.find(params[:contact_id])
  end

  def create_from_follow_up_task
    @interaction_log = @follow_up_task.interaction_logs.build(interaction_log_params)
    @interaction_log.contact = @follow_up_task.invitation.contact
    @interaction_log.user = current_user
    # Preserved for the re-rendered form on validation failure, and used
    # below to advance the queue on success.
    @queue_context = params[:from] == "queue" ? params.slice(:from, :scope, :q).to_unsafe_h : nil

    respond_to do |format|
      ActiveRecord::Base.transaction do
        @interaction_log.save!
        @follow_up_task.update!(completed_at: Time.current)
      end

      mark_related_notifications_read

      if params[:from] == "queue"
        @queue = FollowUpQueue.load_for(current_user, Current.account, params[:q])
        @pagy, _page = pagy(@queue.records)
        @queue_context = FollowUpQueue.context_for(params, "pending")
      end

      format.turbo_stream { render(@queue ? :create_from_queue : :create) }
      format.html { redirect_to follow_up_tasks_path, notice: "Follow-up successfully logged!" }

    rescue ActiveRecord::RecordInvalid
      format.turbo_stream { render :new, status: :unprocessable_entity }
      format.html { render :new, status: :unprocessable_entity }
    end
  end

  def set_interaction_log
    # Contact-scoped: covers queue-linked and standalone logs. Contacts are
    # account-owned, so this is the tenancy boundary (same as set_contact).
    @interaction_log = InteractionLog.joins(:contact)
                                     .where(contacts: { owner_type: "Account", owner_id: Current.account.id })
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

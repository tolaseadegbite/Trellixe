class InvitationsController < DashboardsController
  before_action :authenticate
  before_action :set_event, only: [ :create ]
  before_action :set_invitation, only: [ :edit, :update, :destroy ]
  before_action :set_available_contacts, only: [ :create ]

  def create
    contact_ids = params.dig(:invitation, :contact_ids)&.reject(&:blank?)

    if contact_ids.present?
      timestamp = Time.current
      # Create invitations for the contacts selected
      invitations_attributes = contact_ids.map do |contact_id|
        {
          event_id: @event.id,
          contact_id: contact_id,
          created_at: timestamp,
          updated_at: timestamp
        }
      end

      Invitation.insert_all(invitations_attributes)

      @new_invitations = @event.invitations.where(contact_id: contact_ids).includes(:contact)

      invited_ids = @event.invitations.pluck(:contact_id)
      @available_contacts = Current.account.contacts.where.not(id: invited_ids).order(:first_name)

      flash.now[:notice] = "#{contact_ids.count} #{'invitation'.pluralize(contact_ids.count)} sent."

      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to @event, notice: "#{contact_ids.count} invitations sent." }
      end
    else
      redirect_to @event, alert: "No contacts were selected."
    end
  end

  def edit
  end

  def update
    respond_to do |format|
      if @invitation.update(invitation_params)
        create_follow_up_task_if_needed(@invitation)

        flash.now[:notice] = "Invitation was successfully updated."

        format.turbo_stream
        format.html { redirect_to @invitation.event, notice: "Invitation was successfully updated." }
      else
        format.turbo_stream { render turbo_stream: turbo_stream.replace(@invitation, partial: "invitations/invitation", locals: { invitation: @invitation }), status: :unprocessable_entity }
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @invitation.destroy!
    flash.now[:notice] = "Invitation was successfully removed."

    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.remove(@invitation) }
      format.html { redirect_to @invitation.event, notice: "Invitation was successfully removed." }
    end
  end

  def bulk_update
    @invitation_ids = params[:invitation_ids] || []
    target_status = params[:status]

    if @invitation_ids.empty?
      flash.now[:alert] = "No invitations selected."
      render_flash
      return
    end

    # 1. Fetch invitations scoped to Current.account for security
    # We load them because we need to run callbacks/controller logic on each
    @invitations = Invitation.joins(:event)
                         .includes(:contact, :event)
                         .where(events: { owner_type: "Account", owner_id: Current.account.id })
                         .where(id: @invitation_ids)

    updated_count = 0

    # Preload existing follow-up tasks to avoid N+1 in create_follow_up_task_if_needed
    existing_follow_up_ids = FollowUpTask.where(invitation_id: @invitations.select(:id)).pluck(:invitation_id)
    @_existing_follow_up_ids = existing_follow_up_ids.to_set

    ActiveRecord::Base.transaction do
      @invitations.each do |invitation|
        # Skip if already in the target state
        next if invitation.status == target_status

        if invitation.update(status: target_status)
          # CRITICAL: Trigger the task creation logic if marked attended
          # This ensures the reminder job gets scheduled
          create_follow_up_task_if_needed(invitation) if target_status == "attended"
          updated_count += 1
        end
      end
    end

    flash.now[:notice] = "Marked #{updated_count} as #{target_status.humanize}."

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_back fallback_location: events_path, notice: flash.now[:notice] }
    end
  end

  private

  # Helper to render flash for error returns
  def render_flash
    render turbo_stream: turbo_stream.update("flash_messages", partial: "shared/flash")
  end

  def set_event
    # Scoped to Account: Ensure the event belongs to the active workspace
    @event = Current.account.events.find(params[:event_id])
  end

  def set_invitation
    # Scoped to Account: Ensure the invitation belongs to an event in this workspace
    @invitation = Invitation.joins(:event)
                            .where(events: { owner_type: "Account", owner_id: Current.account.id })
                            .find(params[:id])
    @event = @invitation.event
  end

  def set_available_contacts
    invited_ids = @event.invitations.pluck(:contact_id)
    # Scoped to Account: Only show contacts from this workspace
    @available_contacts = Current.account.contacts.where.not(id: invited_ids).order(:first_name)
  end

  def invitation_params
    params.require(:invitation).permit(:contact_id, :status, :notes)
  end

  def create_follow_up_task_if_needed(invitation)
    return unless invitation.attended? && invitation.saved_change_to_status?
    return if @_existing_follow_up_ids&.include?(invitation.id)

    event_end_time = invitation.event.starts_at + invitation.event.duration_in_minutes.minutes

    # due_date = event_end_time.next_day.beginning_of_day.advance(hours: 9)
    due_date = event_end_time.advance(minutes: 3)
    # due_date = event_end_time.tomorrow.change(hour: 9)

    FollowUpTask.create!(
      invitation: invitation,
      user: current_user,
      due_at: due_date
    )
  end
end

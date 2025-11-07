class InvitationsController < DashboardController
  before_action :set_event, only: [ :create ]
  before_action :set_invitation, only: [ :edit, :update, :destroy ]
  before_action :set_available_contacts, only: [ :create ]

  def create
    contact_ids = params.dig(:invitation, :contact_ids)&.reject(&:blank?)

    if contact_ids.present?
      timestamp = Time.current
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
        
        format.turbo_stream
        format.html { redirect_to @invitation.event, notice: "Invitation was successfully updated." }
      else
        format.turbo_stream { render turbo_stream: turbo_stream.replace(@invitation, partial: "invitations/invitation", locals: { invitation: @invitation }) }
        format.html { redirect_to @invitation.event, alert: "Failed to update invitation." }
      end
    end
  end

  def destroy
    @invitation.destroy!

    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.remove(@invitation) }
      format.html { redirect_to @invitation.event, notice: "Invitation was successfully removed." }
    end
  end

  private

  def set_event
    @event = current_user.events.find(params[:event_id])
  end

  def set_invitation
    @invitation = Invitation.joins(:event).where(events: { owner: current_user }).find(params[:id])
    @event = @invitation.event
  end

  def set_available_contacts
    invited_ids = @event.invitations.pluck(:contact_id)
    @available_contacts = current_user.contacts.where.not(id: invited_ids).order(:first_name)
  end

  def invitation_params
    params.require(:invitation).permit(:contact_id, :status, :notes)
  end

  # def create_follow_up_task_if_needed(invitation)
  #   # Guard clauses to ensure we only create a task when needed.
  #   return unless invitation.attended? && invitation.saved_change_to_status?
  #   return if FollowUpTask.exists?(invitation_id: invitation.id)

  #   # Calculate the event's end time.
  #   event_end_time = invitation.event.starts_at + invitation.event.duration_in_minutes.minutes

  #   due_date = 1.minute.from_now

  #   FollowUpTask.create!(
  #     invitation: invitation,
  #     user: current_user,
  #     due_at: due_date
  #   )
  # end

  def create_follow_up_task_if_needed(invitation)
    return unless invitation.attended? && invitation.saved_change_to_status?
    return if FollowUpTask.exists?(invitation_id: invitation.id)

    event_end_time = invitation.event.starts_at + invitation.event.duration_in_minutes.minutes

    due_date = event_end_time.next_day.beginning_of_day.advance(hours: 9)
    # due_date = event_end_time.tomorrow.change(hour: 9)

    FollowUpTask.create!(
      invitation: invitation,
      user: current_user,
      due_at: due_date
    )
  end
end

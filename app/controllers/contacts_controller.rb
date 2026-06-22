class ContactsController < DashboardsController
  before_action :set_contact, only: %i[ show edit update destroy ]

  def index
    records = Current.account.contacts.order(created_at: :desc)
    @search = records.ransack(params[:q])
    @pagy, @contacts = pagy(@search.result)
    @filterable_events = Current.account.events.order(:name)
    @bulk_event_options = Current.account.events
                                 .where("starts_at >= ?", Time.current.beginning_of_day)
                                 .order(starts_at: :asc)
                                 .map { |e| [ e.name, e.id ] }
  end

  def show
    @interaction_logs = @contact.interaction_logs
                                .includes(:user, follow_up_task: { invitation: :event })
                                .order(created_at: :desc)
  end

  def new
    # Build relative to the account
    @contact = Current.account.contacts.build
  end

  def create
    @contact = Current.account.contacts.new(contact_params)
    @contact.creator = current_user

    respond_to do |format|
      if @contact.save
        flash.now[:notice] = "Contact created."
        format.turbo_stream
      else
        flash.now[:alert] = @contact.errors.full_messages.to_sentence
        format.turbo_stream { render status: :unprocessable_entity }
      end
    end
  end

  # GET /contacts/1/edit
  def edit
  end

  # PATCH/PUT /contacts/1
  def update
    respond_to do |format|
      if @contact.update(contact_params)
        flash.now[:notice] = "Contact was successfully updated."
        format.turbo_stream
      else
        flash.now[:alert] = @contact.errors.full_messages.to_sentence
        format.turbo_stream { render status: :unprocessable_entity }
      end
    end
  end

  # DELETE /contacts/1
  def destroy
    @contact.destroy!
    flash.now[:notice] = "Contact was successfully destroyed."

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to contacts_url, status: :see_other, notice: "Contact was successfully destroyed." }
    end
  end

  def bulk_destroy
    # 1. Capture IDs safely
    @contact_ids = params[:contact_ids] || []

    # 2. Scope to account
    contacts_to_delete = Current.account.contacts.where(id: @contact_ids)
    count = contacts_to_delete.count

    if count > 0
      contacts_to_delete.destroy_all
      flash.now[:notice] = "Successfully deleted #{count} contacts."
    else
      flash.now[:alert] = "No contacts selected."
    end

    # 3. Respond
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to contacts_path, status: :see_other, notice: flash[:notice] }
    end
  end

  def bulk_assign_event
    @contact_ids = params[:contact_ids] || []
    event_id = params[:event_id] # FIX: Access specific key, not whole params object

    if @contact_ids.empty?
      flash.now[:alert] = "No contacts selected."
      render turbo_stream: turbo_stream.update("flash_messages", partial: "shared/flash")
      return
    end

    if event_id.blank?
      flash.now[:alert] = "Please select an event."
      render turbo_stream: turbo_stream.update("flash_messages", partial: "shared/flash")
      return
    end

    # 1. Verify event
    @event = Current.account.events.find(event_id)
    timestamp = Time.current

    # 2. Filter existing invitations
    existing_contact_ids = @event.invitations.where(contact_id: @contact_ids).pluck(:contact_id).map(&:to_s)
    new_contact_ids = @contact_ids - existing_contact_ids

    # 3. Batch Insert
    if new_contact_ids.any?
      invitations_attributes = new_contact_ids.map do |cid|
        { event_id: @event.id, contact_id: cid, created_at: timestamp, updated_at: timestamp }
      end

      Invitation.insert_all(invitations_attributes)
      flash.now[:notice] = "Successfully added #{new_contact_ids.size} contacts to #{@event.name}."
    else
      flash.now[:alert] = "Selected contacts were already assigned to #{@event.name}."
    end

    # 4. Respond (Flash + Reset UI)
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to contacts_path, status: :see_other, notice: flash.now[:notice] }
    end
  end

  private

    def set_contact
      # CRITICAL: Must find in Current.account, not current_user
      # Otherwise Bob can't see contacts Alice created for the team
      @contact = Current.account.contacts.find(params[:id])

      base_invitations = @contact.invitations.includes(:event, follow_up_tasks: :interaction_logs)
      @history_search = base_invitations.ransack(params[:q])
      @pagy, @invitations = pagy(@history_search.result.order("events.starts_at DESC"))
    end

    def contact_params
      params.require(:contact).permit(:first_name, :last_name, :email, :phone_number, :how_we_met)
    end
end

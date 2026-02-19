class ContactsController < DashboardsController
  before_action :set_contact, only: %i[ show edit update destroy ]

  def index
    # Use Current.account so everyone on the team sees the same list
    records = Current.account.contacts.order(created_at: :desc)
    @search = records.ransack(params[:q])
    @pagy, @contacts = pagy(@search.result)
    @filterable_events = Current.account.events.order(:name)
  end

  # GET /contacts/1
  def show
    # The @contact, @invitations, and @general_interaction_logs
    # instance variables are all set by the `set_contact` before_action.
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
        # Notify the user who created it (In-app)
        # NewContactNotifier.with(contact: @contact).deliver(current_user)
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

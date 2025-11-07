class ContactsController < DashboardController
  before_action :set_contact, only: %i[ show edit update destroy ]

  # GET /contacts
  def index
    records = current_user.contacts.order(created_at: :desc)
    @search = records.ransack(params[:q])
    @pagy, @contacts = pagy(@search.result)
    @filterable_events = current_user.events.order(:name)
  end

  # GET /contacts/1
  def show
    # The @contact, @invitations, and @general_interaction_logs
    # instance variables are all set by the `set_contact` before_action.
  end

  # GET /contacts/new
  def new
    @contact = current_user.contacts.build
  end

  # GET /contacts/1/edit
  def edit
  end

  # POST /contacts
  def create
    @contact = current_user.contacts.new(contact_params)
    @contact.creator_id = current_user.id

    respond_to do |format|
      if @contact.save
        NewContactNotifier.with(contact: @contact).deliver(current_user)
        flash.now[:notice] = "Contact was successfully submitted."
        format.turbo_stream
      else
        flash.now[:alert] = @contact.errors.full_messages.to_sentence
        format.turbo_stream { render status: :unprocessable_entity }
      end
    end
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

  private

    def set_contact
      @contact = current_user.contacts.find(params[:id])

      # 1. Define the base query for the contact's invitations
      base_invitations = @contact.invitations.includes(
        :event,
        follow_up_tasks: :interaction_logs
      )

      # 2. Apply Ransack search to the base query
      # Using a unique name to avoid conflicts with other search objects
      @history_search = base_invitations.ransack(params[:q])

      # 3. Get the full list of filtered invitations (before pagination)
      filtered_invitations = @history_search.result

      # 4. NOW, apply pagination to the filtered and sorted list
      # Sorting by the event's start date is most logical for a history view
      @pagy, @invitations = pagy(filtered_invitations.order("events.starts_at DESC"))
    end

    def contact_params
      params.require(:contact).permit(:first_name, :last_name, :email, :phone_number, :how_we_met)
    end
end

class EventsController < DashboardsController
  before_action :set_event, only: %i[ show edit update destroy ]

  def index
    @date = Date.parse(params.fetch(:date, Date.today.to_s))

    calendar_start_date = @date.beginning_of_month.beginning_of_week
    calendar_end_date = @date.end_of_month.end_of_week
    events_for_calendar = Current.account.events.where("starts_at < ?", calendar_end_date)
                                      .order(starts_at: :asc)

    @events_by_date = Hash.new { |h, k| h[k] = [] }

    events_for_calendar.each do |event|
      event_date_range = event.starts_at.to_date..event.ends_at.to_date
      event_date_range.each do |day|
        if (calendar_start_date..calendar_end_date).cover?(day)
          @events_by_date[day] << event
        end
      end
    end

    @scope = params.fetch(:scope, "upcoming")

    base_records = Current.account.events

    if @scope == "past"
      records = base_records.where("starts_at < ?", Time.current.beginning_of_day).order(starts_at: :desc)
    else
      records = base_records.where("starts_at >= ?", Time.current.beginning_of_day).order(starts_at: :asc)
    end

    if params[:q].present? && params[:q][:starts_at_lteq].present?
      end_date = Date.parse(params[:q][:starts_at_lteq]).end_of_day
      params[:q][:starts_at_lteq] = end_date
    end

    @search = records.ransack(params[:q])
    @pagy, @list_events = pagy(@search.result.includes(:invited_contacts))

    @filterable_contacts = Current.account.contacts.order(:first_name, :last_name)
  end

  def show
    base_invitations = @event.invitations.includes(:contact)
    @invitations_search = base_invitations.ransack(params[:q])
    filtered_invitations = @invitations_search.result

    raw_counts = @event.invitations.group(:status).count
    @stats = {
      total:    @event.invitations.count,
      attended: raw_counts["attended"] || 0
    }

    @pagy, @invitations = pagy(filtered_invitations.order("contacts.first_name ASC"))

    @new_invitation = @event.invitations.build
    invited_contact_ids = @event.invitations.select(:contact_id)
    @available_contacts = Current.account.contacts.where.not(id: invited_contact_ids).order(:first_name)
  end

  def new
    @event = Current.account.events.build
  end

  def edit
  end

  def create
    @event = Current.account.events.new(event_params)
    if @event.save
      flash.now[:notice] = "Event was successfully submitted."
      prepare_calendar_data
      render :create
    else
      flash.now[:alert] = @event.errors.full_messages.to_sentence
      render :create, status: :unprocessable_entity
    end
  end

  def update
    if @event.update(event_params)
      flash.now[:notice] = "Event was successfully updated."
      prepare_calendar_data
      render :update
    else
      flash.now[:alert] = @event.errors.full_messages.to_sentence
      render :update, status: :unprocessable_entity
    end
  end

  def destroy
    @event.destroy!
    flash.now[:notice] = "Event was successfully destroyed."
    prepare_calendar_data
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to events_url, notice: "Event was successfully destroyed." }
    end
  end

  private

    def set_event
      # Scope to Account
      @event = Current.account.events.find(params[:id])
    end

    def event_params
      params.expect(event: [ :owner_id, :owner_type, :name, :starts_at, :duration_in_minutes, contact_ids: [] ])
    end

    def prepare_calendar_data
      @date = @event&.starts_at&.to_date || Date.parse(params.fetch(:date, Date.today.to_s))
      
      # WRONG IN YOUR CODE: events_for_month = current_user.events...
      # CORRECT:
      events_for_month = Current.account.events
                                     .includes(:invitations)
                                     .where(starts_at: @date.all_month)
      @events_by_date = events_for_month.group_by { |event| event.starts_at.to_date }
    end
end

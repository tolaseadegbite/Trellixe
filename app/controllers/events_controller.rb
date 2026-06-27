class EventsController < DashboardsController
  before_action :set_event, only: %i[ show edit update destroy ]

  def index
    # 1. Calendar Logic
    @date = Date.parse(params.fetch(:date, Date.today.to_s))

    # Use the optimized scope to prevent loading entire history
    calendar_events = Current.account.events.in_range(
      @date.beginning_of_month.beginning_of_week,
      @date.end_of_month.end_of_week
    ).includes(:invitations)

    @events_by_date = calendar_events.group_by { |e| e.starts_at.to_date }

    # 1b. Merge virtual occurrences from event series
    series = Current.account.event_series.active
                    .where("starts_at <= ?", @date.end_of_month.end_of_week)
                    .where("ends_on IS NULL OR ends_on >= ?", @date.beginning_of_month.beginning_of_week)

    series.each do |s|
      occurrences = s.occurrences(from: @date.beginning_of_month.beginning_of_week,
                                  to: @date.end_of_month.end_of_week)
      occurrences.each do |occ|
        day = occ.to_date
        real = @events_by_date[day]&.any? { |e| e.event_series_id == s.id }
        next if real

        vir = Event.new(name: s.name, starts_at: occ,
                        duration_in_minutes: s.duration_in_minutes, event_series: s)
        @events_by_date[day] ||= []
        @events_by_date[day] << vir
      end
    end

    # 2. List Logic (Past vs Upcoming)
    @scope = params.fetch(:scope, "upcoming")

    records = if @scope == "past"
                # Events that have completely finished
                Current.account.events.past.order(starts_at: :desc)
    else
                # Events happening now or in the future
                Current.account.events.upcoming.order(starts_at: :asc)
    end

    # 3. Ransack Date Fix (End of day handling)
    if params[:q].present? && params[:q][:starts_at_lteq].present?
      end_date = Date.parse(params[:q][:starts_at_lteq]).end_of_day
      params[:q][:starts_at_lteq] = end_date
    end

    @search = records.ransack(params[:q])
    @pagy, @list_events = pagy(@search.result.includes(:invited_contacts, :invitations))

    @filterable_contacts = Current.account.contacts.order(:first_name, :last_name)
  end

  def show
    base_invitations = @event.invitations.includes(:contact, :event, :follow_up_tasks, interaction_logs: :user)
    @invitations_search = base_invitations.ransack(params[:q])
    filtered_invitations = @invitations_search.result

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
    respond_to do |format|
      if @event.save
        flash.now[:notice] = "Event was successfully submitted."
        prepare_calendar_data
        format.turbo_stream
        format.html { redirect_to events_path, notice: "Event was successfully submitted." }
      else
        flash.now[:alert] = @event.errors.full_messages.to_sentence
        format.turbo_stream { render :create, status: :unprocessable_entity }
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @event.update(event_params)
        flash.now[:notice] = "Event was successfully updated."
        prepare_calendar_data
        format.turbo_stream
        format.html { redirect_to events_path, notice: "Event was successfully updated." }
      else
        flash.now[:alert] = @event.errors.full_messages.to_sentence
        format.turbo_stream { render :update, status: :unprocessable_entity }
        format.html { render :edit, status: :unprocessable_entity }
      end
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

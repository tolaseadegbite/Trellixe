class EventSeriesController < DashboardsController
  before_action :set_event_series, only: [ :show, :edit, :update, :destroy, :generate_occurrence, :toggle_cancellation ]
  before_action :set_tags, only: [ :new, :edit ]

  def index
    @event_series = Current.account.event_series.order(starts_at: :desc)
  end

  def show
    redirect_to edit_event_series_path(@event_series)
  end

  def new
    @event_series = Current.account.event_series.build
  end

  def create
    @event_series = Current.account.event_series.new(event_series_params)

    respond_to do |format|
      if @event_series.save
        @event_series.generate_occurrence!(@event_series.starts_at)
        flash.now[:notice] = "Series created. First occurrence generated."
        format.turbo_stream
        format.html { redirect_to events_path, notice: "Series created." }
      else
        flash.now[:alert] = @event_series.errors.full_messages.to_sentence
        format.turbo_stream { render :create, status: :unprocessable_entity }
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  def edit
  end

  def update
    respond_to do |format|
      if @event_series.update(event_series_params)
        flash.now[:notice] = "Series updated."
        format.turbo_stream
        format.html { redirect_to events_path, notice: "Series updated." }
      else
        flash.now[:alert] = @event_series.errors.full_messages.to_sentence
        format.turbo_stream { render :update, status: :unprocessable_entity }
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @event_series.destroy!
    flash.now[:notice] = "Series removed."
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to events_path, notice: "Series removed." }
    end
  end

  def generate_occurrence
    date = Date.parse(params[:date])
    start_time = @event_series.starts_at.change(year: date.year, month: date.month, day: date.day)
    @event = @event_series.generate_occurrence!(start_time)

    if @event
      flash.now[:notice] = "Occurrence created."
    else
      flash.now[:alert] = "Occurrence already exists for this date."
    end

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to event_series_index_path, notice: flash.now[:notice] || flash.now[:alert] }
    end
  rescue ActiveRecord::RecordInvalid => e
    redirect_to event_series_index_path, alert: e.message
  end

  def toggle_cancellation
    @event_series.update!(cancelled_series: !@event_series.cancelled_series)
    flash.now[:notice] = @event_series.cancelled_series? ? "Series cancelled." : "Series reactivated."
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to event_series_index_path, notice: flash.now[:notice] }
    end
  end

  private

  def set_event_series
    @event_series = Current.account.event_series.find(params[:id])
  end

  def set_tags
    @tags = Current.account.tags.order(:name)
  end

  def event_series_params
    params.expect(event_series: [ :name, :duration_in_minutes, :starts_at, :ends_on,
                                   :recurrence_frequency, { day_of_week: [], tag_ids: [] } ])
  end
end

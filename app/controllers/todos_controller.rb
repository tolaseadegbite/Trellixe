class TodosController < DashboardsController
  before_action :set_todo, only: %i[ edit update destroy toggle_complete step_progress participate ]
  before_action :authorize_mutation!, only: %i[ edit update ]
  before_action :authorize_completion!, only: %i[ toggle_complete ]
  before_action :authorize_participation!, only: %i[ step_progress participate ]
  before_action :authorize_destroy!, only: %i[ destroy ]
  before_action :set_assignable_users, only: %i[ new edit create update ]

  STATUSES = %w[ open done ].freeze
  FILTERS = %w[ all mine personal goals overdue due_today ].freeze

  def index
    @status = STATUSES.include?(params[:status]) ? params[:status] : "open"
    @filter = FILTERS.include?(params[:filter]) ? params[:filter] : "all"

    base = Current.account.todos.visible_to(current_user)
    base = apply_filter(base)
    base = @status == "done" ? base.done : base.open

    @search = base.ransack(params[:q])
    @pagy, @todos = pagy(@search.result.includes(:user, todo_contacts: :contact, todo_participations: :user).order(due_at: :asc, created_at: :desc))
    @todo = Todo.new
  end

  def new
    @todo = Current.account.todos.new(user: current_user)
  end

  def edit
  end

  def create
    @todo = Current.account.todos.new(todo_params)
    @todo.creator = current_user
    # Members create personal todos for themselves; only admins assign
    # shared work to others. Forced here, never trusted from params.
    unless can_assign_todos?
      @todo.visibility = "personal"
      @todo.user = current_user
    end

    respond_to do |format|
      if @todo.save
        flash.now[:notice] = "Todo created."
        format.turbo_stream
        format.html { redirect_to todos_path, notice: "Todo created." }
      else
        flash.now[:alert] = @todo.errors.full_messages.to_sentence
        format.turbo_stream { render :create, status: :unprocessable_entity }
        format.html { redirect_to todos_path, alert: @todo.errors.full_messages.to_sentence }
      end
    end
  end

  def update
    respond_to do |format|
      if @todo.update(todo_params)
        flash.now[:notice] = "Todo updated."
        format.turbo_stream
        format.html { redirect_to todos_path, notice: "Todo updated." }
      else
        flash.now[:alert] = @todo.errors.full_messages.to_sentence
        format.turbo_stream { render :update, status: :unprocessable_entity }
        format.html { redirect_to todos_path, alert: @todo.errors.full_messages.to_sentence }
      end
    end
  end

  def toggle_complete
    @todo.update!(completed_at: @todo.completed? ? nil : Time.current)

    respond_to do |format|
      flash.now[:notice] = @todo.completed? ? "Todo completed." : "Todo reopened."
      format.turbo_stream { render :update }
      format.html { redirect_to todos_path, notice: flash.now[:notice] }
    end
  end

  def step_progress
    delta = params[:delta].to_i.clamp(-1, 1)
    @todo.update!(progress_count: (@todo.progress_count + delta).clamp(0, @todo.target_count || 0)) if @todo.goal?

    respond_to do |format|
      format.turbo_stream { render :update }
      format.html { redirect_to todos_path }
    end
  end

  # Participation roster: any member who can see a shared todo logs
  # themselves with one tap; tapping again removes the entry. Personal
  # todos have exactly one viewer, so there is nothing to join.
  def participate
    if @todo.participated?(current_user)
      @todo.todo_participations.find_by(user: current_user).destroy!
      flash.now[:notice] = "Removed from participants."
    else
      @todo.todo_participations.create!(user: current_user)
      flash.now[:notice] = "Participation logged."
    end

    respond_to do |format|
      format.turbo_stream { render :update }
      format.html { redirect_to todos_path, notice: flash.now[:notice] }
    end
  end

  def destroy
    @todo.destroy!
    respond_to do |format|
      flash.now[:notice] = "Todo deleted."
      format.turbo_stream
      format.html { redirect_to todos_path, notice: "Todo deleted." }
    end
  end

  private

  def apply_filter(scope)
    case @filter
    when "mine" then scope.for_member(current_user)
    when "personal" then scope.personal.where(user: current_user)
    when "goals" then scope.goals
    when "overdue" then scope.where("due_at < ?", Time.current)
    when "due_today" then scope.where(due_at: Time.current.beginning_of_day..Time.current.end_of_day)
    else scope
    end
  end

  # Privacy boundary doubles as tenancy: personal todos of other members
  # (and any cross-account id) 404 here instead of leaking.
  def set_todo
    @todo = Current.account.todos.visible_to(current_user).find(params[:id])
  end

  def set_assignable_users
    @assignable_users = Current.account.users.order(:email)
  end

  def authorize_mutation!
    return if can_edit_todo?(@todo)

    redirect_back_or_to todos_path, alert: "Permission denied."
  end

  def authorize_completion!
    return if can_complete_todo?(@todo)

    redirect_back_or_to todos_path, alert: "Permission denied."
  end

  # Executing (progress steps, participation): any member who can see a
  # shared todo. Personal owners use the edit form instead — execution
  # widgets render on shared todos only.
  def authorize_participation!
    return if @todo.shared?

    redirect_back_or_to todos_path, alert: "Permission denied."
  end

  def authorize_destroy!
    allowed = @todo.personal? ? @todo.user == current_user : admin?
    return if allowed

    redirect_back_or_to todos_path, alert: "Permission denied."
  end

  def todo_params
    permitted = [ :title, :due_at, :target_count, :progress_count, contact_ids: [] ]
    # Only admins may set visibility or reassign; members keep personal
    # todos personal and assigned to themselves (enforced in create).
    if can_assign_todos?
      permitted << :visibility
      permitted << :user_id
    end
    params.expect(todo: permitted)
  end
end

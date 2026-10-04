class AccountsController < DashboardsController
  before_action :authenticate
  before_action :ensure_admin!, only: [ :edit, :update, :destroy ]

  def new
    @account = Account.new
  end

  def create
    @account = Account.new(account_params)

    ActiveRecord::Base.transaction do
      @account.save!
      # Creator is always Admin
      Membership.create!(user: Current.user, account: @account, role: :admin)
    end

    # Switch context immediately
    session[:current_account_id] = @account.id
    redirect_to root_path, notice: "Workspace '#{@account.name}' created!"

  rescue ActiveRecord::RecordInvalid
    render :new, status: :unprocessable_entity
  end

  def edit
    @account = Current.account
  end

  def update
    @account = Current.account
    if @account.update(account_params)
      # Theme changes morph every session viewing this workspace (phone,
      # laptop, other tabs) so no device sits on a stale palette. Gated
      # to theme changes: name/reminder edits disturb nobody.
      if @account.saved_change_to_theme?
        Turbo::StreamsChannel.broadcast_refresh_to("appearance_account_#{@account.id}")
      end
      # Explicit return path: Referer is unreliable under Turbo fetches
      # (palette picks teleported to settings). Settings forms post no
      # return_to and fall back to themselves.
      redirect_to safe_return_to || edit_account_path(@account), notice: "Workspace updated."
    else
      # Loud failure: a silent re-render looks exactly like a save that
      # "reverted", with no way to tell the difference.
      flash.now[:alert] = @account.errors.full_messages.to_sentence
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @account = Current.account

    # 1. Password Challenge (Security)
    unless Current.user.authenticate(params[:password_challenge])
      redirect_to edit_account_path(@account), alert: "Incorrect password. Workspace was not deleted."
      return
    end

    # 2. Last Man Standing (Safety)
    if Current.user.accounts.count == 1
      redirect_to edit_account_path(@account), alert: "You cannot delete your only remaining workspace."
      return
    end

    @account.destroy!
    session[:current_account_id] = nil
    redirect_to root_path, notice: "Workspace deleted."
  end

  def switch
    # Lookup by Public ID from URL
    target_account = Current.user.accounts.find_by_public_id!(params[:id])

    session[:current_account_id] = target_account.id
    redirect_to dashboard_path, notice: "Switched to #{target_account.name}"
  end

  private

  # Local paths only — never follow a return_to off this host.
  def safe_return_to
    path = params[:return_to].to_s
    path if path.start_with?("/") && !path.start_with?("//")
  end

  def account_params
    params.require(:account).permit(:name, :theme, :reminder_clock, :pre_event_enabled,
      :pre_event_day_offset, :pre_event_buffer_minutes, :post_event_day_offset)
  end
end

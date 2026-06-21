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
      redirect_to edit_account_path(@account), notice: "Workspace updated."
    else
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
    redirect_back fallback_location: root_path, notice: "Switched to #{target_account.name}"
  end

  private

  def account_params
    params.require(:account).permit(:name)
  end

  def ensure_admin!
    redirect_to(root_path, alert: "Access denied.") and return unless admin?
  end
end

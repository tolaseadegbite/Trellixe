module SetCurrentRequestDetails
  extend ActiveSupport::Concern

  private

  def set_current_account
    return unless user_signed_in?

    # 1. Check if the user specifically switched to a team (stored in session)
    if session[:current_account_id]
      # Security: Ensure user actually belongs to this account
      # Using find_by(id:) because session stores the Integer ID, not Public ID
      Current.account = Current.user.accounts.find_by(id: session[:current_account_id])
    end

    # 2. Fallback: If no preference (or they lost access), default to their first account
    # Usually this is their "Personal Workspace"
    Current.account ||= Current.user.accounts.order(created_at: :asc).first

    # 3. Safety Net: If they somehow have ZERO accounts (database corruption or edge case),
    # trigger the personal workspace creation logic defined in User model
    if Current.account.nil?
      Current.user.send(:create_personal_workspace)
      Current.account = Current.user.accounts.first
    end
  end
end

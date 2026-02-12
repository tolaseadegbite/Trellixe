class MembersController < DashboardsController
  before_action :authenticate

  def index
    # Fetch active members
    @active_memberships = Current.account.memberships
                                 .includes(:user)
                                 .order(role: :asc, created_at: :desc)

    # Fetch pending invitations
    # Note: Using team_invitations association
    @pending_invitations = Current.account.team_invitations
                                  .order(created_at: :desc)
  end
end

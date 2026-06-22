class MembersController < DashboardsController
  before_action :authenticate

  def index
    @active_memberships = Current.account.memberships
                                 .includes(:user)
                                 .order(role: :asc, created_at: :desc)
                                 .limit(50)

    @pending_invitations = Current.account.team_invitations
                                  .order(created_at: :desc)
                                  .limit(50)
  end
end

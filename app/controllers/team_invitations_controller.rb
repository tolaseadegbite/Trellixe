class TeamInvitationsController < DashboardsController
  before_action :authenticate
  before_action :ensure_admin!, only: [ :new, :create, :destroy, :resend ]
  before_action :set_invitation, only: [ :destroy, :resend ]

  def new
    @invitation = TeamInvitation.new
  end

  def create
    # 1. Seat Limit Guard
    if Current.account.seat_limit_reached?
      msg = "Seat limit reached (#{Current.account.seat_limit}). Upgrade required."
      respond_to do |format|
        format.html { redirect_to members_path, alert: msg }
        format.turbo_stream do
          flash.now[:alert] = msg
          render turbo_stream: turbo_stream.update("flash_messages", partial: "shared/flash")
        end
      end
      return
    end

    @invitation = Current.account.team_invitations.new(invitation_params)

    if @invitation.save
      # 2. Send Email
      TeamInvitationMailer.with(invitation: @invitation).invite.deliver_later

      # 3. Global Notification for Existing Users
      if existing_user = User.find_by(email: @invitation.email.downcase)
        # Note: No account_id passed = Global Notification
        TeamNotifier::InvitationReceived.with(
          account_name: Current.account.name,
          token: @invitation.token
        ).deliver_later(existing_user)
      end

      respond_to do |format|
        format.html { redirect_to members_path, notice: "Invitation sent." }
        format.turbo_stream { flash.now[:notice] = "Invitation sent." }
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def resend
    if @invitation.updated_at > 5.minutes.ago
      flash.now[:alert] = "Please wait 5 minutes before resending."
      render turbo_stream: turbo_stream.update("flash_messages", partial: "shared/flash")
      return
    end

    ActiveRecord::Base.transaction do
      @invitation.update!(expires_at: 48.hours.from_now)
      @invitation.touch
    end

    TeamInvitationMailer.with(invitation: @invitation).invite.deliver_later

    respond_to do |format|
      format.html { redirect_to members_path, notice: "Invitation resent." }
      format.turbo_stream { flash.now[:notice] = "Invitation resent." }
    end
  end

  def destroy
    @invitation.destroy
    respond_to do |format|
      format.html { redirect_to members_path, notice: "Invitation revoked." }
      format.turbo_stream { flash.now[:notice] = "Invitation revoked." }
    end
  end

  private

  def set_invitation
    @invitation = Current.account.team_invitations.find_by_public_id!(params[:id])
  end

  def invitation_params
    params.require(:team_invitation).permit(:email, :role)
  end
end

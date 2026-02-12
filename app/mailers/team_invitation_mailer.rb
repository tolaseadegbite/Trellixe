class TeamInvitationMailer < ApplicationMailer
  def invite
    @invitation = params[:invitation]
    @account = @invitation.account

    # Use the named route for the acceptance link
    @url = team_invitation_acceptance_url(token: @invitation.token)

    mail(
      to: @invitation.email,
      subject: "You've been invited to join #{@account.name} on Trellixe"
    )
  end
end

class TeamInvitationAcceptancesController < ApplicationController
  skip_before_action :authenticate
  before_action :find_invitation

  def show
    if user_signed_in?
      # Security Check
      unless Current.user.email.downcase == @invitation.email.downcase
        render :wrong_user
      end
    else
      @user = User.new(email: @invitation.email)
    end
  end

  def update
    if user_signed_in?
      # Logged In: Explicit Join Button clicked
      accept_invitation(Current.user)
    else
      # New User: Registration Form submitted
      @user = User.new(user_params)
      @user.email = @invitation.email # Lock email
      @user.verified = true

      if @user.save
        accept_invitation(@user)
      else
        render :show, status: :unprocessable_entity
      end
    end
  end

  private

  def find_invitation
    @invitation = TeamInvitation.find_by(token: params[:token])

    if @invitation.nil?
      redirect_to root_path, alert: "Invalid invitation link."
      return
    end

    if @invitation.expired?
      redirect_to(root_path, alert: "Invitation expired. Ask admin to resend.") and return
    end
  end

  def accept_invitation(user)
    account = @invitation.account
    role = @invitation.role

    ActiveRecord::Base.transaction do
      Membership.create!(user: user, account: account, role: role)
      @invitation.destroy!
    end

    # Notify Admins
    admins = account.memberships.admin.includes(:user).map(&:user)
    admins.each do |admin|
      TeamNotifier::MemberJoined.with(
        account_id: account.id,
        user_name: user.full_name,
        account_name: account.name
      ).deliver_later(admin)
    end

    # Sign in and switch context
    session_record = user.sessions.create!
    cookies.signed.permanent[:session_token] = { value: session_record.id, httponly: true }
    session[:current_account_id] = account.id

    redirect_to root_path, notice: "You have joined #{account.name}!"
  end

  def user_params
    params.require(:user).permit(:first_name, :last_name, :password, :password_confirmation)
  end
end

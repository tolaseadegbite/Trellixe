class MembershipMailer < ApplicationMailer
  def role_changed
    @membership = params[:membership]
    @account = @membership.account
    @user = @membership.user
    @new_role = @membership.role

    mail(
      to: @user.email,
      subject: "Your role in #{@account.name} has been updated"
    )
  end

  def removed
    @user = params[:user]
    @account = params[:account]

    mail(
      to: @user.email,
      subject: "You have been removed from #{@account.name}"
    )
  end

  def member_left
    @admin = params[:admin]
    @user = params[:user]
    @account = params[:account]

    mail(
      to: @admin.email,
      subject: "#{@user.full_name} has left #{@account.name}"
    )
  end

  def member_joined
    @admin = params[:admin]
    @new_member = params[:new_member]
    @account = params[:account]

    mail(
      to: @admin.email,
      subject: "#{@new_member.full_name} has joined #{@account.name}"
    )
  end
end

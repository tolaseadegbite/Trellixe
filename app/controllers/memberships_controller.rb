class MembershipsController < DashboardsController
  before_action :authenticate
  before_action :set_membership, only: [ :update, :destroy ]
  before_action :ensure_admin!, only: [ :update ]

  def update
    new_role = membership_params[:role]

    # Guard: Last Admin check
    if @membership.admin? && new_role == "member" && Current.account.memberships.admin.count <= 1
      flash.now[:alert] = "You cannot demote the only Admin."
      render turbo_stream: [
        turbo_stream.replace(@membership, partial: "members/membership", locals: { membership: @membership }),
        turbo_stream.update("flash_messages", partial: "shared/flash")
      ]
      return
    end

    if @membership.update(role: new_role)
      # Notify if changed
      if @membership.saved_change_to_role?
        TeamNotifier::RoleChanged.with(
          account_id: Current.account.id,
          account_name: Current.account.name,
          user_id: @membership.user_id,
          user_name: @membership.user.full_name,
          role: new_role
        ).deliver_later(@membership.user)
      end

      respond_to do |format|
        format.html { redirect_to members_path, notice: "Role updated." }
        format.turbo_stream { flash.now[:notice] = "Role updated." }
      end
    else
      redirect_to members_path, alert: "Update failed."
    end
  end

  def destroy
    # Authorization: Admin OR Self
    unless admin? || @membership.user == Current.user
      redirect_to members_path, alert: "Permission denied."
      return
    end

    if @membership.user == Current.user
      # CASE 1: LEAVING
      if @membership.admin? && Current.account.memberships.admin.count == 1
        redirect_to members_path, alert: "You cannot leave because you are the only Admin."
        return
      end

      user_left = @membership.user
      account = @membership.account

      # Notify other admins
      admins = account.memberships.admin.where.not(user_id: user_left.id).includes(:user).map(&:user)

      @membership.destroy

      admins.each do |admin|
        TeamNotifier::MemberLeft.with(
          account_id: account.id,
          user_name: user_left.full_name,
          account_name: account.name
        ).deliver_later(admin)
      end

      session[:current_account_id] = nil
      redirect_to root_path, notice: "You left #{account.name}."

    else
      # CASE 2: KICKED
      user_removed = @membership.user
      account = @membership.account

      # Notify other admins (Audit)
      admins = account.memberships.admin.where.not(user_id: [ user_removed.id, Current.user.id ]).includes(:user).map(&:user)

      @membership.destroy

      # Notify User (In-App + Email)
      TeamNotifier::MemberRemoved.with(
        account_id: account.id,
        account_name: account.name,
        user_id: user_removed.id # For logic in helper
      ).deliver_later(user_removed)

      # Notify Admins
      admins.each do |admin|
        TeamNotifier::MemberRemoved.with(
          account_id: account.id,
          account_name: account.name,
          user_id: user_removed.id,
          user_name: user_removed.full_name,
          actor_name: Current.user.full_name
        ).deliver_later(admin)
      end

      respond_to do |format|
        format.html { redirect_to members_path, notice: "Member removed." }
        format.turbo_stream { flash.now[:notice] = "Member removed." }
      end
    end
  end

  private

  def set_membership
    @membership = Current.account.memberships.includes(:user).find_by!(public_id: params[:id])
  end

  def ensure_admin!
    redirect_to(members_path, alert: "Admins only.") and return unless admin?
  end

  def membership_params
    params.require(:membership).permit(:role)
  end
end

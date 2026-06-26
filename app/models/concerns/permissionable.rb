module Permissionable
  extend ActiveSupport::Concern

  included do
    helper_method :can_view_team?, :can_invite_members?, :can_manage_members?,
                  :can_manage_settings?, :can_manage_billing?,
                  :can_manage_all_logs?, :can_delete_workspace?
  end

  def can_view_team?
    user_signed_in? && Current.account.present?
  end

  def can_invite_members?
    admin?
  end

  def can_manage_members?
    admin?
  end

  def can_manage_settings?
    admin?
  end

  def can_manage_billing?
    admin?
  end

  def can_delete_workspace?
    admin?
  end

  def can_manage_all_logs?
    admin?
  end

  def can_edit_log?(log)
    log.user == current_user || admin?
  end
end

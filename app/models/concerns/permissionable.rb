module Permissionable
  extend ActiveSupport::Concern

  included do
      helper_method :can_view_team?, :can_invite_members?, :can_manage_members?,
                    :can_manage_settings?, :can_manage_billing?,
                    :can_manage_all_logs?, :can_delete_workspace?, :can_edit_log?,
                    :can_assign_todos?, :can_edit_todo?, :can_complete_todo?
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

  def can_assign_todos?
    admin?
  end

  # Managing (fields, assignment, deletion): admins for shared todos,
  # creators for their own personal ones.
  def can_edit_todo?(todo)
    admin? || (todo.personal? && todo.user == current_user)
  end

  # Closing: admins, plus the assignee of an assigned shared todo.
  # Team-wide todos have no assignee, so only admins close them.
  def can_complete_todo?(todo)
    admin? || (todo.user.present? && todo.user == current_user)
  end
end

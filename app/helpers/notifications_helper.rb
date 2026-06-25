module NotificationsHelper
  def notification_message(notification)
    event = notification.event
    params = event.params
    recipient = notification.recipient

    case event.type
    when "TeamNotifier::RoleChanged"
      if recipient.id == params[:user_id]
        "Your role in #{params[:account_name]} was changed to #{params[:role].humanize} by #{params[:actor_name]}."
      else
        "#{params[:user_name]}'s role was changed to #{params[:role].humanize} by #{params[:actor_name]}."
      end

    when "TeamNotifier::MemberRemoved"
      if recipient.id == params[:user_id]
        "You have been removed from #{params[:account_name]}."
      else
        "#{params[:user_name]} was removed from the team by #{params[:actor_name]}."
      end

    when "TeamNotifier::MemberLeft"
      "#{params[:user_name]} has left #{params[:account_name]}."

    when "TeamNotifier::MemberJoined"
      "#{params[:user_name]} has joined #{params[:account_name]}."

    when "TeamNotifier::InvitationReceived"
      "You have been invited to join #{params[:account_name]}."

    when "FollowUpTaskNotifier"
      if params[:task]
        "Follow up with #{params[:task].contact.full_name}"
      else
        "Follow up reminder"
      end
    end
  end

  def notification_destination(notification)
    event = notification.event
    params = event.params
    recipient = notification.recipient

    case event.type
    when "TeamNotifier::MemberRemoved"
      recipient.id == params[:user_id] ? root_path : members_path

    when "TeamNotifier::InvitationReceived"
      team_invitation_acceptance_path(token: params[:token])

    when "FollowUpTaskNotifier"
      if params[:task]
        new_follow_up_task_interaction_log_path(params[:task])
      else
        follow_up_tasks_path
      end

    else
      members_path
    end
  end

  def notification_avatar_url(notification)
    event_type = notification.event.type
    return nil if event_type == "TeamNotifier::RoleChanged"

    params = notification.event.params
    if params[:user_id].present?
      user = User.find_by(id: params[:user_id])
      return user_avatar_url(user) if user
    end
    nil
  end

  def notification_actor_avatar_url(notification)
    params = notification.event.params
    if params[:actor_id].present?
      actor = User.find_by(id: params[:actor_id])
      return user_avatar_url(actor) if actor
    end
    nil
  end

  def notification_avatar_initials(notification)
    event_type = notification.event.type
    params = notification.event.params
    if params[:task].present?
      params[:task].contact.full_name.split.first(2).map(&:first).join.upcase
    elsif params[:user_name].present? && event_type != "TeamNotifier::RoleChanged"
      params[:user_name].split.first(2).map(&:first).join.upcase
    else
      params[:account_name]&.split&.first(2)&.map(&:first)&.join&.upcase || notification.account&.name&.first(2)&.upcase || "??"
    end
  end
end

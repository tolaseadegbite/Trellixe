module NotificationsHelper
  def notification_message(notification)
    event = notification.event
    params = event.params
    recipient = notification.recipient

    case event.type
    when "TeamNotifier::RoleChanged"
      if recipient.id == params[:user_id]
        if recipient.id == params[:actor_id]
          "Your role in #{params[:account_name]} was changed to #{params[:role].humanize} by you."
        else
          "Your role in #{params[:account_name]} was changed to #{params[:role].humanize} by #{params[:actor_name]}."
        end
      else
        if recipient.id == params[:actor_id]
          "#{params[:user_name]}'s role was changed to #{params[:role].humanize} by you."
        else
          "#{params[:user_name]}'s role was changed to #{params[:role].humanize} by #{params[:actor_name]}."
        end
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

    when "TeamNotifier::InvitationDeclined"
      "#{params[:email]} declined the invitation to #{params[:account_name]}."

    when "FollowUpTaskNotifier"
      if follow_up_task_param(notification)
        "Follow up with #{follow_up_task_param(notification).contact.full_name}"
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
      if (task = follow_up_task_param(notification))
        new_follow_up_task_interaction_log_path(task)
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
    if (task = follow_up_task_param(notification)).present?
      task.contact.full_name.split.first(2).map(&:first).join.upcase
    elsif params[:user_name].present? && event_type != "TeamNotifier::RoleChanged"
      params[:user_name].split.first(2).map(&:first).join.upcase
    else
      params[:account_name]&.split&.first(2)&.map(&:first)&.join&.upcase || notification.account&.name&.first(2)&.upcase || "??"
    end
  end

  private

  # A reminder's task may be gone (undone check-in, removed guest). GlobalID
  # lookup raises RecordNotFound for missing records, so resolve defensively —
  # callers fall back to generic copy instead of 500ing the whole list.
  def follow_up_task_param(notification)
    notification.event.params[:task]
  rescue ActiveRecord::RecordNotFound
    nil
  end
end

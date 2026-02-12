module NotificationsHelper
  def notification_message(notification)
    event = notification.event
    params = event.params
    recipient = notification.recipient

    case event.type
    when "TeamNotifier::RoleChanged"
      if recipient.id == params[:user_id]
        "Your role in #{params[:account_name]} was changed to #{params[:role].humanize}."
      else
        "#{params[:user_name]}'s role was changed to #{params[:role].humanize}."
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

    else
      "New activity in your workspace."
    end
  end

  def notification_destination(notification)
    event = notification.event
    params = event.params
    recipient = notification.recipient

    case event.type
    when "TeamNotifier::MemberRemoved"
      # If user was removed, they can't see the team page -> go to root
      recipient.id == params[:user_id] ? root_path : members_path

    when "TeamNotifier::InvitationReceived"
      # Go to the public acceptance page
      team_invitation_acceptance_path(token: params[:token])

    else
      # Default: Go to the Team Directory
      members_path
    end
  end

  # UI Helper for Initials (Workspace Square vs User Circle)
  def notification_avatar_initials(notification)
    params = notification.event.params
    if params[:user_name].present?
      params[:user_name].split.first(2).map(&:first).join.upcase
    else
      # Fallback to Account Initials if no user name (e.g. Invitations)
      notification.account&.name&.first(2)&.upcase || "??"
    end
  end

  def notification_avatar_style(notification)
    # Circle for user events, Square for system/workspace events
    notification.event.params[:user_name].present? ? "rounded-full bg-teal-600" : "rounded-md bg-black"
  end
end

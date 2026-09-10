class DeliveryMethods::TurboStreamDelivery < Noticed::DeliveryMethod
  def deliver
    # 1. Determine Stream Name (Global vs Account-Specific)
    stream_name = if notification.params[:account_id]
      "notifications_#{recipient.id}_account_#{notification.params[:account_id]}"
    else
      "notifications_#{recipient.id}_global"
    end

    # 2. Update Sidebar List (the only live list — the index page renders
    #    from the DB on visit, and prepending to it would fight its pagy
    #    footer while spamming missing-target errors everywhere else)
    broadcast_to_stream(stream_name, "sidebar-notifications-list", "notifications/notification")

    # 3. Update Badges (desktop sidebar popover + header bell — the only
    #    badge roots in the shell; targeting absent ids spams the console
    #    with missing-target errors)
    broadcast_badge(stream_name, "sidebar")
    broadcast_badge(stream_name, "header")
  end

  private

  def broadcast_to_stream(stream, target_id, partial)
    recipient.broadcast_prepend_to(
      stream,
      target: target_id,
      partial: partial,
      locals: { notification: notification }
    )
  end

  def broadcast_badge(stream, suffix)
    recipient.broadcast_replace_to(
      stream,
      target: "#{suffix}-notification-badge",
      partial: "notifications/badge",
      locals: { unread: true, id_suffix: suffix }
    )
  end
end

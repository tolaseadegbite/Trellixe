class DeliveryMethods::TurboStreamDelivery < Noticed::DeliveryMethod
  def deliver
    # 1. Determine Stream Name (Global vs Account-Specific)
    stream_name = if notification.params[:account_id]
      "notifications_#{recipient.id}_account_#{notification.params[:account_id]}"
    else
      "notifications_#{recipient.id}_global"
    end

    # 2. Update Sidebar List
    broadcast_to_stream(stream_name, "sidebar-notifications-list", "notifications/notification")

    # 3. Update Header/Mobile List
    broadcast_to_stream(stream_name, "notifications-list", "notifications/notification")

    # 4. Update Badges
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

class WebPushDelivery < Noticed::DeliveryMethods::Base
  # This method is called by Noticed
  def deliver
    # `recipient` is the User object
    # Find all their subscriptions
    public_key = Rails.application.credentials.dig(:vapid, :public_key) || ENV["VAPID_PUBLIC_KEY"]
    private_key = Rails.application.credentials.dig(:vapid, :private_key) || ENV["VAPID_PRIVATE_KEY"]
    subject = ENV["VAPID_SUBJECT"].presence || "mailto:hello@trellixe.com"

    if public_key.blank? || private_key.blank?
      Rails.logger.warn "WebPush skipped: missing VAPID keys. Set credentials.vapid or VAPID_PUBLIC_KEY/VAPID_PRIVATE_KEY."
      return
    end

    recipient.web_push_subscriptions.each do |subscription|
      WebPush.payload_send(
        message: message.to_json,
        endpoint: subscription.endpoint,
        p256dh: subscription.p256dh,
        auth: subscription.auth,
        vapid: {
          subject: subject,
          public_key: public_key,
          private_key: private_key
        }
      )
    rescue WebPush::Error => e
      # Handle errors (e.g., subscription expired, log it)
      Rails.logger.error "WebPush Error: #{e.message}"
      # You might want to delete the invalid subscription
      # subscription.destroy
    end
  end

  # We need to define how the notification's data
  # is formatted into a message.
  def message
    # `notification` is the Notifier object (e.g., NewComment)
    # We call a method on it to get the payload
    notification.event.web_push_payload
  end
end

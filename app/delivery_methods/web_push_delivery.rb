class WebPushDelivery < Noticed::DeliveryMethods::Base
  # This method is called by Noticed
  def deliver
    # `recipient` is the User object
    # Find all their subscriptions
    recipient.web_push_subscriptions.each do |subscription|
      WebPush.payload_send(
        message: message.to_json,
        endpoint: subscription.endpoint,
        p256dh: subscription.p256dh,
        auth: subscription.auth,
        vapid: {
          subject: "mailto:your-email@example.com", # Change this
          public_key: Rails.application.credentials.vapid[:public_key],
          private_key: Rails.application.credentials.vapid[:private_key]
        }
      )
    rescue WebPush::Error => e
      # Handle errors (e.g., subscription expired, log it)
      puts "WebPush Error: #{e.message}"
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

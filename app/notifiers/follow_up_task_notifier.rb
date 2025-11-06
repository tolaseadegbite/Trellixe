class FollowUpTaskNotifier < ApplicationNotifier
  # We will deliver this notification via our existing web push method.
  deliver_by :web_push, class: "WebPushDelivery"

  # This method defines the content of the push notification.
  def web_push_payload
    # The `params` hash contains the follow_up_task we passed in.
    task = params[:task]
    contact_name = task.contact.full_name
    event_name = task.event.name

    {
      title: "Time to Follow Up!",
      body: "Don't forget to connect with #{contact_name} from #{event_name}.",
      # This URL will take the user to their to-do list when they click the notification.
      url: new_follow_up_task_interaction_log_url(task)
    }
  end
end

class FollowUpTaskNotifier < ApplicationNotifier
  deliver_by :web_push, class: "WebPushDelivery"
  deliver_by :turbo_stream, class: "DeliveryMethods::TurboStreamDelivery"

  def web_push_payload
    task = params[:task]

    {
      title: "Time to Follow Up!",
      body: "Don't forget to connect with #{task.contact.full_name} from #{task.event.name}.",
      url: new_follow_up_task_interaction_log_path(task)
    }
  end

  def recipient_attributes_for(recipient)
    super.merge(account_id: params[:account_id])
  end
end

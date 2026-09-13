class PreEventDigestNotifier < ApplicationNotifier
  deliver_by :web_push, class: "WebPushDelivery"
  deliver_by :turbo_stream, class: "DeliveryMethods::TurboStreamDelivery"

  def web_push_payload
    {
      title: "Nudges for #{params[:event_name]}",
      body: "#{params[:invitee_count]} #{"guest".pluralize(params[:invitee_count])} to nudge before it starts.",
      url: event_path(params[:event_id])
    }
  end

  def recipient_attributes_for(recipient)
    super.merge(account_id: params[:account_id])
  end
end

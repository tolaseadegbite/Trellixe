# To deliver this notification:
#
# NewContactNotifier.with(record: @post, message: "New post").deliver(User.all)

class NewContactNotifier < ApplicationNotifier
  deliver_by :web_push, class: "WebPushDelivery"

  # This method will be called by your delivery class
  def web_push_payload
    {
      title: "New Contact!",
      body: "A new contact, '#{params[:contact].full_name}' was created.",
      url: contact_url(params[:contact])
    }
  end
end

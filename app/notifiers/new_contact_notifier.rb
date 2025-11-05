# To deliver this notification:
#
# NewContactNotifier.with(record: @post, message: "New post").deliver(User.all)

class NewContactNotifier < ApplicationNotifier
  deliver_by :web_push, class: "WebPushDelivery"

  # This method will be called by your delivery class
  def web_push_payload
    {
      title: "New Comment!",
      body: "A new contact was created on '#{params[:contact].full_name}'.",
      url: contact_url(params[:contact])
    }
  end
end

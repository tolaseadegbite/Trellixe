class TeamNotifier < Noticed::Event
  # Use our custom delivery method
  deliver_by :turbo_stream, class: "DeliveryMethods::TurboStreamDelivery"

  # Ensure account_id is stored in the notification record for filtering
  def recipient_attributes_for(recipient)
    super.merge(account_id: params[:account_id])
  end
end

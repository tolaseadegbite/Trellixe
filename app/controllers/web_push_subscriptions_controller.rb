class WebPushSubscriptionsController < DashboardController
  def create
    # Find or create the subscription for the current user
    @subscription = current_user.web_push_subscriptions.find_or_initialize_by(
      endpoint: subscription_params[:endpoint]
    )

    if @subscription.update(
         p256dh: subscription_params.dig(:keys, :p256dh),
         auth: subscription_params.dig(:keys, :auth)
       )
      render json: { message: "Subscription saved." }, status: :ok
    else
      render json: { error: "Could not save subscription." }, status: :unprocessable_entity
    end
  end

  private

  def subscription_params
    # This structure matches the JSON from the browser's PushManager
    params.require(:subscription).permit(
      :endpoint,
      keys: [ :p256dh, :auth ]
    )
  end
end

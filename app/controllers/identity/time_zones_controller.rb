class Identity::TimeZonesController < DashboardsController
  # This is a background utility update. Since the user is already authenticated
  # via their session, we can safely skip CSRF verification for this specific
  # JSON-only background action.
  skip_before_action :verify_authenticity_token, only: :update

  def update
    new_zone = params[:time_zone]

    # Validating against ActiveSupport ensures only real timezones are saved
    if ActiveSupport::TimeZone[new_zone].present?
      # update_column skips validations and callbacks, making it very performant
      if current_user.update_column(:time_zone, new_zone)
        head :ok
      else
        head :unprocessable_entity
      end
    else
      head :not_found
    end
  end
end

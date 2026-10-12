class MissionControlController < ActionController::Base
  # Only enable HTTP basic auth if credentials are configured
  if Rails.application.credentials.dig(:mission_control, :username).present? &&
     Rails.application.credentials.dig(:mission_control, :password).present?
    http_basic_authenticate_with(
      name: Rails.application.credentials.dig(:mission_control, :username),
      password: Rails.application.credentials.dig(:mission_control, :password)
    )
  end
end

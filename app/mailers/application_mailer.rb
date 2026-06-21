class ApplicationMailer < ActionMailer::Base
  default from: Rails.application.credentials.dig(:mailer, :from) || ENV.fetch("MAILER_FROM", "from@example.com")
  layout "mailer"
end

class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("SMTP_FROM_EMAIL", "noreply@example.com")
  layout "mailer"
end

class PublicTokenMailer < ApplicationMailer
  default from: ENV.fetch("MAILER_FROM_EMAIL", "noreply@callab.app")

  # Send warning when token is expiring soon
  def expiry_warning(calendar)
    @calendar = calendar
    @user = calendar.user
    @days_remaining = calendar.days_until_token_expires
    @expires_at = calendar.public_token_expires_at

    mail(
      to: @user.email,
      subject: "Your public calendar link expires in #{@days_remaining} days"
    )
  end

  # Send notification when token has expired
  def token_expired(calendar)
    @calendar = calendar
    @user = calendar.user
    @expired_at = calendar.public_token_expires_at

    mail(
      to: @user.email,
      subject: "Your public calendar link has expired"
    )
  end

  # Send confirmation when token is regenerated
  def token_regenerated(calendar)
    @calendar = calendar
    @user = calendar.user
    @new_expires_at = calendar.public_token_expires_at
    @public_url = generate_public_url(calendar)

    mail(
      to: @user.email,
      subject: "Your public calendar link has been regenerated"
    )
  end

  private

  def generate_public_url(calendar)
    # Generate the base URL for the public calendar
    # Adjust this based on your frontend URL structure
    base_url = ENV.fetch("FRONTEND_URL", "https://callab.app")
    "#{base_url}/public/calendar/#{calendar.public_token}"
  end
end

class PublicTokenMaintenanceJob < ApplicationJob
  queue_as :default

  # Run this job daily to:
  # 1. Send expiry warning emails for tokens expiring soon
  # 2. Clean up expired tokens (optional - you may want to keep them for audit)
  def perform
    send_expiry_warnings
    cleanup_expired_tokens if cleanup_enabled?
    log_token_statistics
  end

  private

  def send_expiry_warnings
    Calendar.with_expiring_soon_tokens.includes(:user).find_each do |calendar|
      next if calendar.user.email.blank?
      next if warning_already_sent?(calendar)

      # Send warning email
      PublicTokenMailer.expiry_warning(calendar).deliver_later

      Rails.logger.info "Sent expiry warning for calendar #{calendar.id} (expires: #{calendar.public_token_expires_at})"
    end
  end

  def cleanup_expired_tokens
    # Option 1: Nullify expired tokens (recommended for audit trail)
    expired_count = Calendar.with_expired_tokens.count

    Calendar.with_expired_tokens.find_each do |calendar|
      # Keep the token but mark it as expired by setting revoked_at
      # This maintains audit trail while preventing usage
      calendar.update_column(:public_token_revoked_at, Time.current) unless calendar.public_token_revoked?
    end

    Rails.logger.info "Marked #{expired_count} expired tokens as revoked"

    # Option 2: Completely remove tokens (use with caution)
    # Calendar.with_expired_tokens.update_all(
    #   public_token: nil,
    #   public_token_expires_at: nil,
    #   public_token_last_used_at: nil
    # )
  end

  def log_token_statistics
    stats = {
      total_calendars: Calendar.count,
      active_tokens: Calendar.with_active_tokens.count,
      expired_tokens: Calendar.with_expired_tokens.count,
      expiring_soon: Calendar.with_expiring_soon_tokens.count,
      revoked_tokens: Calendar.where.not(public_token_revoked_at: nil).count
    }

    Rails.logger.info "Public Token Statistics: #{stats.to_json}"
  end

  def warning_already_sent?(calendar)
    # Check if we've sent a warning in the last 24 hours
    # You can implement this using a separate table or cache
    # For now, we'll send once when it enters the warning window
    calendar.days_until_token_expires && calendar.days_until_token_expires == Calendar::TOKEN_EXPIRY_WARNING_DAYS
  end

  def cleanup_enabled?
    # You can make this configurable via environment variable
    ENV.fetch("CLEANUP_EXPIRED_TOKENS", "true") == "true"
  end
end

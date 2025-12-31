module PublicTokenValidation
  extend ActiveSupport::Concern

  class TokenExpiredError < StandardError; end
  class TokenRevokedError < StandardError; end
  class RateLimitExceededError < StandardError; end

  included do
    rescue_from TokenExpiredError, with: :render_token_expired
    rescue_from TokenRevokedError, with: :render_token_revoked
    rescue_from RateLimitExceededError, with: :render_rate_limit_exceeded
  end

  private

  def find_and_validate_public_token!(token)
    calendar = Calendar.find_by!(public_token: token)

    # Check if token is revoked
    if calendar.public_token_revoked?
      raise TokenRevokedError, "This public link has been revoked"
    end

    # Check if token is expired
    if calendar.public_token_expired?
      raise TokenExpiredError, "This public link has expired"
    end

    # Check rate limiting
    if calendar.token_usage_rate_limit_exceeded?
      raise RateLimitExceededError, "Rate limit exceeded for this public link"
    end

    # Record token usage and update last used timestamp
    calendar.record_token_usage!

    calendar
  end

  def render_token_expired
    render json: {
      error: "Token Expired",
      message: "This public link has expired. Please contact the calendar owner for a new link.",
      expired_at: @calendar&.public_token_expires_at,
      support_message: "Public links are valid for #{Calendar::DEFAULT_TOKEN_EXPIRY_DAYS} days from creation."
    }, status: :forbidden
  end

  def render_token_revoked
    render json: {
      error: "Token Revoked",
      message: "This public link has been revoked by the calendar owner.",
      support_message: "Please request a new link from the calendar owner."
    }, status: :forbidden
  end

  def render_rate_limit_exceeded
    render json: {
      error: "Rate Limit Exceeded",
      message: "Too many requests. Please try again later.",
      retry_after: 3600 # seconds (1 hour)
    }, status: :too_many_requests
  end
end

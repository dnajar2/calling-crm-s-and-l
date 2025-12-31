class Calendar < ApplicationRecord
  belongs_to :user
  has_many :events, dependent: :destroy

  # Constants for token management
  DEFAULT_TOKEN_EXPIRY_DAYS = 30
  TOKEN_EXPIRY_WARNING_DAYS = 7
  MAX_TOKEN_USAGE_PER_HOUR = 100

  # Validations
  validates :public_token, uniqueness: true, allow_nil: true

  # Scopes
  scope :with_active_tokens, -> { where("public_token IS NOT NULL AND public_token_revoked_at IS NULL AND (public_token_expires_at IS NULL OR public_token_expires_at > ?)", Time.current) }
  scope :with_expired_tokens, -> { where("public_token IS NOT NULL AND public_token_expires_at IS NOT NULL AND public_token_expires_at <= ?", Time.current) }
  scope :with_expiring_soon_tokens, -> { where("public_token IS NOT NULL AND public_token_revoked_at IS NULL AND public_token_expires_at BETWEEN ? AND ?", Time.current, TOKEN_EXPIRY_WARNING_DAYS.days.from_now) }

  # Generate a unique public token before creating the calendar
  before_create :generate_public_token

  # Token status methods
  def public_token_active?
    public_token.present? &&
      public_token_revoked_at.nil? &&
      (public_token_expires_at.nil? || public_token_expires_at > Time.current)
  end

  def public_token_expired?
    public_token.present? &&
      public_token_expires_at.present? &&
      public_token_expires_at <= Time.current
  end

  def public_token_revoked?
    public_token_revoked_at.present?
  end

  def public_token_expiring_soon?
    return false unless public_token_active?
    return false if public_token_expires_at.nil?

    public_token_expires_at <= TOKEN_EXPIRY_WARNING_DAYS.days.from_now
  end

  def days_until_token_expires
    return nil if public_token_expires_at.nil?
    return 0 if public_token_expired?

    ((public_token_expires_at - Time.current) / 1.day).ceil
  end

  # Token management methods
  def regenerate_public_token!(expiry_days: DEFAULT_TOKEN_EXPIRY_DAYS)
    transaction do
      self.public_token = generate_unique_token
      self.public_token_expires_at = expiry_days.days.from_now
      self.public_token_revoked_at = nil
      self.public_token_usage_count = 0
      self.public_token_last_used_at = nil
      save!
    end
  end

  def revoke_public_token!
    update!(public_token_revoked_at: Time.current)
  end

  def extend_public_token!(additional_days: DEFAULT_TOKEN_EXPIRY_DAYS)
    return false unless public_token_active?

    new_expiry = if public_token_expires_at.present?
      [public_token_expires_at, Time.current].max + additional_days.days
    else
      additional_days.days.from_now
    end

    update!(public_token_expires_at: new_expiry)
  end

  def record_token_usage!
    increment!(:public_token_usage_count)
    touch(:public_token_last_used_at)
  end

  def token_usage_rate_limit_exceeded?
    return false if public_token_last_used_at.nil?
    return false if public_token_last_used_at < 1.hour.ago

    # Check if usage count suggests rate limit breach
    # This is a simple implementation - consider using Redis for production
    hourly_usage = self.class.connection.select_value(<<-SQL)
      SELECT COUNT(*)
      FROM events
      WHERE calendar_id = #{id}
        AND created_at >= NOW() - INTERVAL '1 hour'
    SQL

    hourly_usage.to_i > MAX_TOKEN_USAGE_PER_HOUR
  end

  # Token analytics
  def public_token_stats
    {
      token: public_token&.first(8) + "..." + public_token&.last(4),
      status: token_status,
      total_usage_count: public_token_usage_count || 0,
      last_used_at: public_token_last_used_at,
      expires_at: public_token_expires_at,
      days_until_expiry: days_until_token_expires,
      expiring_soon: public_token_expiring_soon?,
      created_events_count: events.count,
      created_events_last_30_days: events.where("created_at >= ?", 30.days.ago).count
    }
  end

  private

  def generate_public_token
    self.public_token = generate_unique_token
    self.public_token_expires_at = DEFAULT_TOKEN_EXPIRY_DAYS.days.from_now
    self.public_token_usage_count = 0
  end

  def generate_unique_token
    loop do
      token = SecureRandom.urlsafe_base64(32)
      break token unless Calendar.exists?(public_token: token)
    end
  end

  def token_status
    return "revoked" if public_token_revoked?
    return "expired" if public_token_expired?
    return "active" if public_token_active?
    "inactive"
  end
end

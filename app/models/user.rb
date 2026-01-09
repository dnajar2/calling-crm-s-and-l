class User < ApplicationRecord
  has_secure_password validations: false

  has_many :clients, dependent: :destroy
  has_many :calendars, dependent: :destroy
  has_one :calendar, -> { order(created_at: :asc) }, class_name: 'Calendar'
  has_many :notes, dependent: :destroy
  has_many :event_notes, dependent: :destroy

  validates :email, presence: true, uniqueness: { case_sensitive: false }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 8 }, if: -> { password.present? }
  validates :name, presence: true
  validates :timezone, presence: true, inclusion: { in: ActiveSupport::TimeZone.all.map(&:name) }

  before_save :normalize_email
  before_validation :set_default_timezone, on: :create

  # OAuth users don't need password
  validate :password_or_oauth_required
  after_create :create_default_calendar

  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.email = auth.info.email
      user.name = auth.info.name
      user.email_verified = true
      user.password = SecureRandom.hex(32) # Random password for OAuth users
    end
  end

  def generate_password_reset_token
    self.reset_password_token = SecureRandom.urlsafe_base64(32)
    self.reset_password_sent_at = Time.current
    save!
  end

  def password_reset_valid?
    reset_password_sent_at && reset_password_sent_at > 2.hours.ago
  end

  private

  def normalize_email
    self.email = email.downcase.strip if email.present?
  end

  def password_or_oauth_required
    if provider.blank? && password_digest.blank?
      errors.add(:password, "can't be blank")
    end
  end

  def create_default_calendar
    calendars.create!(is_primary: true) unless calendars.exists?
  end

  def set_default_timezone
    self.timezone ||= "UTC"
  end
end

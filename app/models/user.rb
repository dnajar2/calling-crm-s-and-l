class User < ApplicationRecord
  has_secure_password validations: false

  has_many :clients, dependent: :destroy
  has_many :calendars, dependent: :destroy
  has_many :notes, dependent: :destroy

  validates :email, presence: true, uniqueness: { case_sensitive: false }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 8 }, if: -> { password.present? }
  validates :name, presence: true

  before_save :normalize_email

  # OAuth users don't need password
  validate :password_or_oauth_required

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
end

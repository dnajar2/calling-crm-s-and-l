class Calendar < ApplicationRecord
  belongs_to :user
  has_many :events, dependent: :destroy

  # Generate a unique public token before creating the calendar
  before_create :generate_public_token

  private

  def generate_public_token
    self.public_token = loop do
      token = SecureRandom.urlsafe_base64(32)
      break token unless Calendar.exists?(public_token: token)
    end
  end
end

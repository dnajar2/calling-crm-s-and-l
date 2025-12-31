class Event < ApplicationRecord
  belongs_to :calendar
  belongs_to :client
  has_many :event_notes, dependent: :destroy

  validate :no_overlap
  after_create :send_notifications

  private

  def no_overlap
    overlaps = calendar.events
    .where.not(id: id)
    .where("(start_time, end_time) OVERLAPS (?, ?)", start_time, end_time)

    if overlaps.exists?
      errors.add(:base, "Event overlaps with an existing booking")
    end
  end

  def send_notifications
    # Send SMS to client (if phone number exists)
    SmsNotificationService.send_event_confirmation(self)

    # Send email to client (if email exists)
    EventMailer.client_notification(self).deliver_later if client.email.present?

    # Send email to user
    EventMailer.user_notification(self).deliver_later if calendar.user.email.present?
  rescue => e
    # Log error but don't prevent event creation
    Rails.logger.error("Failed to send notifications for event #{id}: #{e.message}")
  end
end

class CalendarBlockout < ApplicationRecord
  belongs_to :calendar

  validates :start_date, presence: true
  validates :end_date, presence: true
  validates :recurring, inclusion: { in: Calendar::VALID_RECURRING_TYPES }
  validate :end_date_after_start_date

  scope :active, -> { where("end_date >= ?", Date.current) }
  scope :for_date_range, ->(start_date, end_date) {
    where("start_date <= ? AND end_date >= ?", end_date, start_date)
  }

  # Check if a specific date is blocked by this blockout
  def blocks_date?(date)
    return false if date < start_date || date > end_date

    case recurring
    when 'weekly'
      # Check if the day of week matches
      (start_date..end_date).any? { |d| d.wday == date.wday }
    when 'monthly'
      # Check if the day of month matches
      (start_date..end_date).any? { |d| d.day == date.day }
    else
      # Non-recurring: just check if date is in range
      date >= start_date && date <= end_date
    end
  end

  private

  def end_date_after_start_date
    return if end_date.blank? || start_date.blank?

    if end_date < start_date
      errors.add(:end_date, "must be after or equal to start date")
    end
  end
end

# app/services/calendar_availability.rb
class CalendarAvailability
  DEFAULT_SLOT_MINUTES = 30
  DEFAULT_START_HOUR   = 9  # 9:00
  DEFAULT_END_HOUR     = 17 # 17:00

  def initialize(calendar, date)
    @calendar = calendar
    @date     = date
    @timezone = calendar.timezone.presence || "America/Los_Angeles"
  end

  # Returns an array of ISO8601 strings representing available start times
  def slots
    require "active_support/time"

    # Interpret the date in the calendar’s timezone
    tz = ActiveSupport::TimeZone[@timezone]
    day_start = tz.parse(@date.to_s).change(hour: DEFAULT_START_HOUR, min: 0)
    day_end   = tz.parse(@date.to_s).change(hour: DEFAULT_END_HOUR,   min: 0)

    # Load existing events for that day (in that timezone)
    events = @calendar.events
      .where("start_time >= ? AND start_time < ?", day_start, day_end)

    slots = []
    slot_length = DEFAULT_SLOT_MINUTES.minutes

    current_start = day_start

    while current_start + slot_length <= day_end
      current_end = current_start + slot_length

      unless overlaps_existing_event?(current_start, current_end, events)
        # Optional: skip past times if the date is today
        if current_start > tz.now
          slots << current_start.iso8601
        end
      end

      current_start += slot_length
    end

    slots
  end

  private

  def overlaps_existing_event?(slot_start, slot_end, events)
    events.any? do |event|
      # Simple overlap check: [a,b) and [c,d) overlap if a < d && c < b
      event.start_time < slot_end && slot_start < event.end_time
    end
  end
end

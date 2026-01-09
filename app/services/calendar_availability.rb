# app/services/calendar_availability.rb
class CalendarAvailability
  def initialize(calendar, date)
    @calendar = calendar
    @date = Date.parse(date.to_s)
    @user_timezone = @calendar.user.timezone || "UTC"
  end

  # Returns an array of ISO8601 strings representing available start times
  def slots
    require "active_support/time"

    # Get timezone
    tz = ActiveSupport::TimeZone[@user_timezone]
    unless tz
      Rails.logger.error("Invalid timezone: #{@user_timezone}, falling back to UTC")
      tz = ActiveSupport::TimeZone["UTC"]
    end

    # Check if date is blocked
    return [] if date_is_blocked?

    # Check advance booking windows
    return [] unless within_booking_window?(tz)

    # Get working hours for this day of week
    day_name = @date.strftime('%A').downcase
    day_config = @calendar.working_hours[day_name] || @calendar.working_hours[day_name.to_sym]
    
    return [] unless day_config && day_config['enabled']
    return [] if day_config['ranges'].blank?

    # Generate slots for all time ranges
    all_slots = []
    day_config['ranges'].each do |range|
      all_slots.concat(generate_slots_for_range(range, tz))
    end

    all_slots.sort
  end

  private

  def date_is_blocked?
    @calendar.blockouts.active.any? { |blockout| blockout.blocks_date?(@date) }
  end

  def within_booking_window?(tz)
    now = tz.now
    target_date_start = tz.parse(@date.to_s).beginning_of_day
    target_date_end = tz.parse(@date.to_s).end_of_day

    # Check if the entire day is in the past
    return false if target_date_end < now

    # Check maximum advance booking (use start of day)
    max_advance = @calendar.max_advance_days.days
    return false if target_date_start > (now + max_advance)

    # Min advance notice is checked per-slot in slot_available?, not per-day
    true
  end

  def generate_slots_for_range(range, tz)
    slots = []
    
    # Parse start and end times for this range
    start_hour, start_min = range['start'].split(':').map(&:to_i)
    end_hour, end_min = range['end'].split(':').map(&:to_i)

    range_start = tz.parse(@date.to_s).change(hour: start_hour, min: start_min)
    range_end = tz.parse(@date.to_s).change(hour: end_hour, min: end_min)

    # Get slot duration and buffer from calendar settings
    slot_duration = @calendar.slot_duration_minutes.minutes
    buffer_time = @calendar.buffer_minutes.minutes

    # Load existing events for this day
    day_start = tz.parse(@date.to_s).beginning_of_day
    day_end = tz.parse(@date.to_s).end_of_day
    events = @calendar.events.where("start_time >= ? AND start_time < ?", day_start, day_end)

    current_start = range_start

    while current_start + slot_duration <= range_end
      current_end = current_start + slot_duration

      # Check if slot is available
      if slot_available?(current_start, current_end, events, buffer_time, tz)
        slots << current_start.iso8601
      end

      current_start += slot_duration
    end

    slots
  end

  def slot_available?(slot_start, slot_end, events, buffer_time, tz)
    # Skip past times
    return false if slot_start <= tz.now

    # Check minimum advance notice
    min_advance = @calendar.min_advance_hours.hours
    return false if slot_start < (tz.now + min_advance)

    # Check for overlaps with existing events (including buffer time)
    events.each do |event|
      # Add buffer time before and after existing events
      event_start_with_buffer = event.start_time - buffer_time
      event_end_with_buffer = event.end_time + buffer_time

      # Check if slot overlaps with buffered event time
      if slot_start < event_end_with_buffer && slot_end > event_start_with_buffer
        return false
      end
    end

    true
  end
end

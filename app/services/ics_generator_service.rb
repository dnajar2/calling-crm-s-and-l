require "icalendar"

class IcsGeneratorService
  def self.generate(event)
    calendar = Icalendar::Calendar.new

    # Get the user's timezone from the calendar, default to UTC
    tz = event.calendar.timezone || "UTC"

    calendar.event do |e|
      e.dtstart = Icalendar::Values::DateTime.new(event.start_time, "tzid" => tz)
      e.dtend = Icalendar::Values::DateTime.new(event.end_time, "tzid" => tz)
      e.summary = event.title
      e.description = event.description
      e.uid = "event-#{event.id}@callab.app"
      e.organizer = Icalendar::Values::CalAddress.new("mailto:#{event.calendar.user.email}", cn: event.calendar.user.name)
      e.attendee = Icalendar::Values::CalAddress.new("mailto:#{event.client.email}", cn: event.client.name)
    end

    calendar.publish
    calendar.to_ical
  end
end

module Ai
  module Tools
    class ListAvailability < BaseTool
      def self.schema
        {
          name: "list_availability",
          description: "Lists available time slots for scheduling. Returns calendar availability for a specific date or date range.",
          input_schema: {
            type: "object",
            properties: {
              start_date: {
                type: "string",
                description: "Start date in YYYY-MM-DD format"
              },
              end_date: {
                type: "string",
                description: "End date in YYYY-MM-DD format (optional, defaults to start_date)"
              },
              calendar_id: {
                type: "integer",
                description: "Specific calendar ID (optional, uses user's first calendar if not provided)"
              }
            },
            required: [ "start_date" ]
          }
        }
      end

      def execute(input)
        start_date = Date.parse(input["start_date"])
        end_date = input["end_date"] ? Date.parse(input["end_date"]) : start_date
        calendar = input["calendar_id"] ? @user.calendars.find(input["calendar_id"]) : @user.calendars.first

        return { error: "No calendar found" } unless calendar

        # Get all events in the date range
        events = calendar.events.where(start_time: start_date.beginning_of_day..end_date.end_of_day)
                        .order(:start_time)

        # Simple availability: list busy times
        busy_slots = events.map do |event|
          {
            start: event.start_time.iso8601,
            end: event.end_time.iso8601,
            title: event.title
          }
        end

        {
          calendar_name: calendar.name,
          date_range: "#{start_date} to #{end_date}",
          busy_slots: busy_slots,
          message: busy_slots.empty? ? "Fully available" : "#{busy_slots.count} event(s) scheduled"
        }
      end
    end
  end
end

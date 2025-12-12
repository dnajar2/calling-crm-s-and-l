module Ai
  module Tools
    class CreateEvent < BaseTool
      def self.schema
        {
          name: "create_event",
          description: "Creates a new event/appointment in the calendar with a client.",
          input_schema: {
            type: "object",
            properties: {
              client_id: {
                type: "integer",
                description: "The ID of the client for this event"
              },
              title: {
                type: "string",
                description: "Event title/subject"
              },
              description: {
                type: "string",
                description: "Event description (optional)"
              },
              start_time: {
                type: "string",
                description: "Start time in ISO 8601 format (e.g., 2025-12-11T10:00:00Z)"
              },
              end_time: {
                type: "string",
                description: "End time in ISO 8601 format (e.g., 2025-12-11T11:00:00Z)"
              },
              calendar_id: {
                type: "integer",
                description: "Calendar ID (optional, uses first calendar if not provided)"
              }
            },
            required: [ "client_id", "title", "start_time", "end_time" ]
          }
        }
      end

      def execute(input)
        calendar = input["calendar_id"] ? @user.calendars.find(input["calendar_id"]) : @user.calendars.first
        return { error: "No calendar found" } unless calendar

        client = Client.find_by(id: input["client_id"], user: @user)
        return { error: "Client not found" } unless client

        event = calendar.events.create!(
          client: client,
          title: input["title"],
          description: input["description"],
          start_time: Time.parse(input["start_time"]),
          end_time: Time.parse(input["end_time"])
        )

        {
          success: true,
          event: {
            id: event.id,
            title: event.title,
            client: client.name,
            start_time: event.start_time.iso8601,
            end_time: event.end_time.iso8601
          },
          message: "Event created successfully"
        }
      rescue => e
        { error: e.message }
      end
    end
  end
end

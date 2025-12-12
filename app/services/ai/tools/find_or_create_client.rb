module Ai
  module Tools
    class FindOrCreateClient < BaseTool
      def self.schema
        {
          name: "find_or_create_client",
          description: "Finds an existing client by name or email, or creates a new client if not found.",
          input_schema: {
            type: "object",
            properties: {
              name: {
                type: "string",
                description: "Client's full name"
              },
              email: {
                type: "string",
                description: "Client's email address (optional)"
              },
              phone: {
                type: "string",
                description: "Client's phone number (optional)"
              }
            },
            required: [ "name" ]
          }
        }
      end

      def execute(input)
        # Try to find by email first if provided
        client = if input["email"].present?
          @user.clients.find_by(email: input["email"])
        else
          # Otherwise try to find by name (case-insensitive partial match)
          @user.clients.where("LOWER(name) LIKE ?", "%#{input["name"].downcase}%").first
        end

        if client
          {
            found: true,
            client: {
              id: client.id,
              name: client.name,
              email: client.email,
              phone: client.phone
            },
            message: "Found existing client"
          }
        else
          # Create new client
          client = @user.clients.create!(
            name: input["name"],
            email: input["email"],
            phone: input["phone"]
          )

          {
            found: false,
            client: {
              id: client.id,
              name: client.name,
              email: client.email,
              phone: client.phone
            },
            message: "Created new client"
          }
        end
      rescue => e
        { error: e.message }
      end
    end
  end
end

module Ai
  module Tools
    class SearchNotes < BaseTool
      def self.schema
        {
          name: "search_notes",
          description: "Searches through user's notes using semantic search to find relevant information about preferences, past conversations, and context. Use this to recall user preferences, client history, and previous discussions.",
          input_schema: {
            type: "object",
            properties: {
              query: {
                type: "string",
                description: "The search query (e.g., 'meeting preferences', 'what did I discuss with John', 'scheduling preferences')"
              },
              limit: {
                type: "integer",
                description: "Maximum number of results to return (default: 5)"
              }
            },
            required: [ "query" ]
          }
        }
      end

      def execute(input)
        query = input["query"]
        limit = input["limit"] || 5

        # Generate embedding for the query
        embedding = generate_embedding(query)

        # Perform semantic search using pgvector
        notes = Note.where(user: @user)
                    .nearest_neighbors(:embedding, embedding, distance: "cosine")
                    .limit(limit)

        results = notes.map do |note|
          {
            id: note.id,
            content: note.content,
            created_at: note.created_at.iso8601
          }
        end

        {
          query: query,
          results_count: results.count,
          notes: results,
          message: results.empty? ? "No relevant notes found" : "Found #{results.count} relevant note(s)"
        }
      rescue => e
        { error: e.message }
      end

      private

      def generate_embedding(text)
        EmbeddingService.generate(text)
      end
    end
  end
end

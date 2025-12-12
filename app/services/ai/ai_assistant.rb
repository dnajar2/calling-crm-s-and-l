require "anthropic"

class Ai::AiAssistant
  MAX_ITERATIONS = 10

  def initialize(query, user)
    @query = query
    @user = user
    @client = Anthropic::Client.new(api_key: ENV["ANTHROPIC_API_KEY"])
    @conversation = []
  end

  def run
    # First, search notes for relevant context (RAG)
    context = retrieve_context(@query)

    # Build initial system prompt with context
    system = build_system_prompt(context)

    # Start conversation
    @conversation << { role: "user", content: @query }

    begin
      # Call Claude WITHOUT tools - we want JSON response for n8n
      response = @client.messages.create(
        max_tokens: 2048,
        system: system,
        messages: @conversation,
        model: "claude-sonnet-4-5-20250929"
      )

      # Extract text response (should be JSON)
      text_blocks = response.content.select { |c| c.is_a?(Anthropic::Models::TextBlock) }
      json_text = text_blocks.map(&:text).join.strip

      # Remove code fences if present (Claude sometimes adds them despite instructions)
      json_text = json_text.gsub(/^```json\n/, "").gsub(/\n```$/, "").strip

      # Try to parse as JSON to validate
      parsed = JSON.parse(json_text)

      # Return the parsed JSON for n8n to use
      parsed
    rescue JSON::ParserError => e
      Rails.logger.error("AI returned invalid JSON: #{e.message}")
      Rails.logger.error("Response was: #{json_text}")
      {
        "thought" => "Error: AI returned invalid JSON",
        "actions" => [
          {
            "type" => "ask_clarification",
            "question" => "I encountered an error. Please try again."
          }
        ]
      }
    rescue => e
      Rails.logger.error("AI Assistant error: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      {
        "thought" => "Error: #{e.message}",
        "actions" => [
          {
            "type" => "ask_clarification",
            "question" => "I encountered an error. Please try again."
          }
        ]
      }
    end
  end

  private

  def retrieve_context(query)
    # Use search_notes tool to get relevant context
    search_tool = Ai::Tools::SearchNotes.new(@user)
    result = search_tool.execute({ "query" => query, "limit" => 3 })

    if result[:notes] && result[:notes].any?
      result[:notes].map { |note| note[:content] }.join("\n\n")
    else
      nil
    end
  rescue => e
    nil # Silently fail if no notes found
  end

  def build_system_prompt(context)
    base_prompt = <<~PROMPT
		<system>
		You are an AI scheduling assistant for an automation system (n8n).

		⚠️ CRITICAL RULES:
		- You MUST respond with **VALID JSON ONLY**.
		- You MUST NOT output markdown.
		- You MUST NOT output code blocks like ```json.
		- You MUST NOT output explanations before or after the JSON.
		- You MUST output exactly ONE JSON object — no more, no less.
		- If you are unsure, ask a clarification question using "ask_clarification".

		RESPONSE FORMAT (ABSOLUTELY REQUIRED):

		{
			"thought": "short reasoning about user's intent",
			"actions": [
				{
					"type": "list_availability" | "search_notes" | "create_event" | "find_or_create_client" | "ask_clarification",
					...parameters...
				}
			]
		}

		Your JSON MUST NOT contain trailing commas.

		If the user is only greeting, respond with:

		{
			"thought": "User greeted; no scheduling intent.",
			"actions": [
				{ "type": "ask_clarification", "question": "How can I help with scheduling?" }
			]
		}
		</system>
  	PROMPT

    context ? base_prompt + "\n\nRELEVANT CONTEXT:\n#{context}" : base_prompt
  end
end

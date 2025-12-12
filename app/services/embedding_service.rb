class EmbeddingService
  def self.generate(text)
    client = Ollama.new(
      credentials: { address: ENV.fetch("OLLAMA_HOST", "http://host.docker.internal:11434") }
    )

    response = client.embeddings({
      model: "nomic-embed-text",
      prompt: text
    })

    # ollama-ai gem returns an array of events
    # Get the first (and only) event and extract the embedding
    response.first&.dig("embedding")
  rescue => e
    Rails.logger.error("Embedding generation failed: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
    nil
  end
end

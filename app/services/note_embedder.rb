class NoteEmbedder
  DIMENSIONS = 1536

  def self.embed(text)
    # 🔁 OPTION 1: STUB for now (random vector, just to exercise pipeline)
    # Replace this with a real embedding call when ready
    Array.new(DIMENSIONS) { rand(-1.0..1.0) }

    # 🔁 OPTION 2: REAL example with OpenAI / RubyLLM (pseudo-code)
    #
    # embedding = RubyLLM.embed(text, model: "text-embedding-3-small")
    # embedding.vectors.first
  end
end

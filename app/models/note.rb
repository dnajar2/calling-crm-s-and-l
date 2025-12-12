class Note < ApplicationRecord
  belongs_to :user

  # This is from the neighbor gem
  has_neighbors :embedding

  # Generate embeddings automatically
  before_save :generate_embedding, if: :content_changed?

  private

  def generate_embedding
    return unless content.present?

    self.embedding = EmbeddingService.generate(content)
  end
end

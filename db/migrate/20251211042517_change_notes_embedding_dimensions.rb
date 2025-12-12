class ChangeNotesEmbeddingDimensions < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def up
    # Remove the old index
    remove_index :notes, :embedding, algorithm: :concurrently if index_exists?(:notes, :embedding)

    # Remove the old embedding column with 1536 dimensions
    remove_column :notes, :embedding

    # Add new embedding column with 768 dimensions (for nomic-embed-text)
    add_column :notes, :embedding, :vector, limit: 768

    # Recreate the index
    add_index :notes, :embedding, using: :ivfflat, opclass: :vector_l2_ops, algorithm: :concurrently
  end

  def down
    # Remove the index
    remove_index :notes, :embedding, algorithm: :concurrently if index_exists?(:notes, :embedding)

    # Revert back to 1536 dimensions
    remove_column :notes, :embedding
    add_column :notes, :embedding, :vector, limit: 1536

    # Recreate the index
    add_index :notes, :embedding, using: :ivfflat, opclass: :vector_l2_ops, algorithm: :concurrently
  end
end

class AddEmbeddingIndexToNotes < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def change
    add_index :notes, :embedding, using: :ivfflat, opclass: :vector_l2_ops, algorithm: :concurrently
  end
end

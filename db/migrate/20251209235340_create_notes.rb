class CreateNotes < ActiveRecord::Migration[7.2]
  def change
    create_table :notes do |t|
      t.references :user, null: false, foreign_key: true
      t.text :content
      t.vector :embedding, limit: 1536

      t.timestamps
    end
  end
end

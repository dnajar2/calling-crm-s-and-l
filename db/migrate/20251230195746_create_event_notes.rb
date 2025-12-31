class CreateEventNotes < ActiveRecord::Migration[8.1]
  def change
    create_table :event_notes do |t|
      t.references :event, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.text :content, null: false
      t.boolean :visible_to_client, default: false, null: false
      t.boolean :follow_up_required, default: false, null: false
      t.datetime :occurred_at

      t.timestamps
    end

    add_index :event_notes, [:event_id, :created_at]
    add_index :event_notes, :follow_up_required, where: "follow_up_required = true"
  end
end

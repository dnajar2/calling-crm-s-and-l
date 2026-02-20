class CreateCalendarBlockouts < ActiveRecord::Migration[8.1]
  def change
    create_table :calendar_blockouts do |t|
      t.references :calendar, null: false, foreign_key: true
      t.date :start_date, null: false
      t.date :end_date, null: false
      t.string :reason
      t.string :recurring # 'weekly', 'monthly', or null

      t.timestamps
    end

    add_index :calendar_blockouts, [:calendar_id, :start_date]
    add_index :calendar_blockouts, [:calendar_id, :end_date]
  end
end

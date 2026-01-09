class AddIsPrimaryToCalendars < ActiveRecord::Migration[8.1]
  def change
    add_column :calendars, :is_primary, :boolean, default: false, null: false
    add_index :calendars, [:user_id, :is_primary]
    
    # Set the first calendar for each user as primary
    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE calendars
          SET is_primary = true
          WHERE id IN (
            SELECT DISTINCT ON (user_id) id
            FROM calendars
            ORDER BY user_id, created_at ASC
          )
        SQL
      end
    end
  end
end

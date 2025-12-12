class AddPublicTokenToCalendars < ActiveRecord::Migration[7.2]
  def change
    add_column :calendars, :public_token, :string
    add_index :calendars, :public_token, unique: true
  end
end

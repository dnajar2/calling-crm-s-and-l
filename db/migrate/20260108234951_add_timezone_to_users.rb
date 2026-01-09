class AddTimezoneToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :timezone, :string, default: "UTC", null: false
    
    # Set existing users to UTC timezone
    reversible do |dir|
      dir.up do
        execute "UPDATE users SET timezone = 'UTC' WHERE timezone IS NULL"
      end
    end
  end
end

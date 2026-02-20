class AddExpiryFieldsToCalendars < ActiveRecord::Migration[8.1]
  def up
    # Add new columns
    add_column :calendars, :public_token_expires_at, :datetime
    add_column :calendars, :public_token_last_used_at, :datetime
    add_column :calendars, :public_token_revoked_at, :datetime
    add_column :calendars, :public_token_usage_count, :integer, default: 0, null: false

    # Add indexes for performance
    add_index :calendars, :public_token_expires_at
    add_index :calendars, :public_token_revoked_at, where: "public_token_revoked_at IS NOT NULL"

    # Migrate existing tokens to have 30-day expiry from migration date
    # This ensures backward compatibility while enabling security
    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE calendars
          SET public_token_expires_at = NOW() + INTERVAL '30 days',
              public_token_usage_count = 0
          WHERE public_token IS NOT NULL
            AND public_token_expires_at IS NULL
        SQL
      end
    end
  end

  def down
    remove_index :calendars, :public_token_expires_at
    remove_index :calendars, :public_token_revoked_at if index_exists?(:calendars, :public_token_revoked_at)

    remove_column :calendars, :public_token_usage_count
    remove_column :calendars, :public_token_revoked_at
    remove_column :calendars, :public_token_last_used_at
    remove_column :calendars, :public_token_expires_at
  end
end

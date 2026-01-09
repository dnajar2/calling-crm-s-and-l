class AddBusinessRulesToCalendars < ActiveRecord::Migration[8.1]
  def change
    # Default working hours: Monday-Friday 9 AM - 5 PM
    default_working_hours = {
      monday: { enabled: true, ranges: [{ start: "09:00", end: "17:00" }] },
      tuesday: { enabled: true, ranges: [{ start: "09:00", end: "17:00" }] },
      wednesday: { enabled: true, ranges: [{ start: "09:00", end: "17:00" }] },
      thursday: { enabled: true, ranges: [{ start: "09:00", end: "17:00" }] },
      friday: { enabled: true, ranges: [{ start: "09:00", end: "17:00" }] },
      saturday: { enabled: false, ranges: [] },
      sunday: { enabled: false, ranges: [] }
    }

    add_column :calendars, :working_hours, :jsonb, default: default_working_hours, null: false
    add_column :calendars, :slot_duration_minutes, :integer, default: 30, null: false
    add_column :calendars, :buffer_minutes, :integer, default: 0, null: false
    add_column :calendars, :min_advance_hours, :integer, default: 0, null: false
    add_column :calendars, :max_advance_days, :integer, default: 60, null: false

    # Backfill existing calendars with default values
    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE calendars 
          SET working_hours = '#{default_working_hours.to_json}'::jsonb,
              slot_duration_minutes = 30,
              buffer_minutes = 0,
              min_advance_hours = 0,
              max_advance_days = 60
          WHERE working_hours IS NULL
        SQL
      end
    end
  end
end

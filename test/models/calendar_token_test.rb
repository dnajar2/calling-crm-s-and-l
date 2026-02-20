require "test_helper"

class CalendarTokenTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @calendar = calendars(:one)
  end

  test "generates public token on create" do
    new_calendar = @user.calendars.create!(name: "Test Calendar")
    assert_not_nil new_calendar.public_token
    assert_not_nil new_calendar.public_token_expires_at
    assert_equal 0, new_calendar.public_token_usage_count
  end

  test "public token has default 30-day expiry" do
    new_calendar = @user.calendars.create!(name: "Test Calendar")
    expected_expiry = 30.days.from_now

    # Allow 1 second variance for test execution time
    assert_in_delta expected_expiry, new_calendar.public_token_expires_at, 1.second
  end

  test "public_token_active? returns true for valid token" do
    assert @calendar.public_token_active?
  end

  test "public_token_active? returns false for expired token" do
    @calendar.update!(public_token_expires_at: 1.day.ago)
    assert_not @calendar.public_token_active?
  end

  test "public_token_active? returns false for revoked token" do
    @calendar.update!(public_token_revoked_at: Time.current)
    assert_not @calendar.public_token_active?
  end

  test "public_token_expired? returns true when expired" do
    @calendar.update!(public_token_expires_at: 1.day.ago)
    assert @calendar.public_token_expired?
  end

  test "public_token_expired? returns false when not expired" do
    @calendar.update!(public_token_expires_at: 1.day.from_now)
    assert_not @calendar.public_token_expired?
  end

  test "public_token_revoked? returns true when revoked" do
    @calendar.update!(public_token_revoked_at: Time.current)
    assert @calendar.public_token_revoked?
  end

  test "public_token_expiring_soon? returns true within warning window" do
    @calendar.update!(public_token_expires_at: 5.days.from_now)
    assert @calendar.public_token_expiring_soon?
  end

  test "public_token_expiring_soon? returns false outside warning window" do
    @calendar.update!(public_token_expires_at: 10.days.from_now)
    assert_not @calendar.public_token_expiring_soon?
  end

  test "days_until_token_expires calculates correctly" do
    @calendar.update!(public_token_expires_at: 5.days.from_now)
    assert_equal 5, @calendar.days_until_token_expires
  end

  test "days_until_token_expires returns 0 for expired token" do
    @calendar.update!(public_token_expires_at: 1.day.ago)
    assert_equal 0, @calendar.days_until_token_expires
  end

  test "regenerate_public_token! creates new token" do
    old_token = @calendar.public_token
    @calendar.regenerate_public_token!

    assert_not_equal old_token, @calendar.public_token
    assert_nil @calendar.public_token_revoked_at
    assert_equal 0, @calendar.public_token_usage_count
  end

  test "regenerate_public_token! sets custom expiry" do
    @calendar.regenerate_public_token!(expiry_days: 60)
    expected_expiry = 60.days.from_now

    assert_in_delta expected_expiry, @calendar.public_token_expires_at, 1.second
  end

  test "revoke_public_token! sets revoked timestamp" do
    @calendar.revoke_public_token!
    assert_not_nil @calendar.public_token_revoked_at
    assert @calendar.public_token_revoked?
  end

  test "extend_public_token! adds days to expiry" do
    original_expiry = @calendar.public_token_expires_at
    @calendar.extend_public_token!(additional_days: 15)

    expected_expiry = original_expiry + 15.days
    assert_in_delta expected_expiry, @calendar.public_token_expires_at, 1.second
  end

  test "extend_public_token! returns false for expired token" do
    @calendar.update!(public_token_expires_at: 1.day.ago)
    result = @calendar.extend_public_token!(additional_days: 30)

    assert_not result
  end

  test "record_token_usage! increments counter and updates timestamp" do
    initial_count = @calendar.public_token_usage_count
    @calendar.record_token_usage!

    assert_equal initial_count + 1, @calendar.public_token_usage_count
    assert_not_nil @calendar.public_token_last_used_at
  end

  test "public_token_stats returns comprehensive data" do
    stats = @calendar.public_token_stats

    assert_includes stats, :token
    assert_includes stats, :status
    assert_includes stats, :total_usage_count
    assert_includes stats, :last_used_at
    assert_includes stats, :expires_at
    assert_includes stats, :days_until_expiry
    assert_includes stats, :expiring_soon
    assert_equal "active", stats[:status]
  end

  test "with_active_tokens scope includes active calendars" do
    active_calendars = Calendar.with_active_tokens
    assert_includes active_calendars, @calendar
  end

  test "with_expired_tokens scope includes expired calendars" do
    @calendar.update!(public_token_expires_at: 1.day.ago)
    expired_calendars = Calendar.with_expired_tokens

    assert_includes expired_calendars, @calendar
  end

  test "with_expiring_soon_tokens scope includes calendars expiring soon" do
    @calendar.update!(public_token_expires_at: 5.days.from_now)
    expiring_soon = Calendar.with_expiring_soon_tokens

    assert_includes expiring_soon, @calendar
  end

  test "validates uniqueness of public_token" do
    calendar1 = @user.calendars.create!(name: "Calendar 1")
    calendar2 = @user.calendars.build(name: "Calendar 2")
    calendar2.public_token = calendar1.public_token

    assert_not calendar2.valid?
    assert_includes calendar2.errors[:public_token], "has already been taken"
  end
end

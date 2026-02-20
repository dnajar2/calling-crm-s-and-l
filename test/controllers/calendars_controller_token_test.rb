require "test_helper"

class CalendarsControllerTokenTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @calendar = calendars(:one)
    @token = generate_jwt_token(@user)
  end

  # Token Management Endpoints Tests

  test "regenerate_token creates new token" do
    old_token = @calendar.public_token

    post regenerate_token_calendar_path(@calendar),
      headers: { "Authorization" => "Bearer #{@token}" }

    assert_response :success
    @calendar.reload
    assert_not_equal old_token, @calendar.public_token

    json = JSON.parse(response.body)
    assert_equal true, json["success"]
    assert_includes json, "calendar"
    assert_equal @calendar.public_token, json["calendar"]["public_token"]
  end

  test "regenerate_token with custom expiry days" do
    post regenerate_token_calendar_path(@calendar),
      params: { expiry_days: 60 },
      headers: { "Authorization" => "Bearer #{@token}" }

    assert_response :success
    @calendar.reload

    expected_expiry = 60.days.from_now
    assert_in_delta expected_expiry, @calendar.public_token_expires_at, 1.second
  end

  test "revoke_token marks token as revoked" do
    post revoke_token_calendar_path(@calendar),
      headers: { "Authorization" => "Bearer #{@token}" }

    assert_response :success
    @calendar.reload
    assert_not_nil @calendar.public_token_revoked_at
    assert @calendar.public_token_revoked?

    json = JSON.parse(response.body)
    assert_equal true, json["success"]
  end

  test "extend_token extends expiry date" do
    original_expiry = @calendar.public_token_expires_at

    post extend_token_calendar_path(@calendar),
      params: { additional_days: 15 },
      headers: { "Authorization" => "Bearer #{@token}" }

    assert_response :success
    @calendar.reload

    expected_expiry = original_expiry + 15.days
    assert_in_delta expected_expiry, @calendar.public_token_expires_at, 1.second
  end

  test "token_stats returns analytics data" do
    get token_stats_calendar_path(@calendar),
      headers: { "Authorization" => "Bearer #{@token}" }

    assert_response :success
    json = JSON.parse(response.body)

    assert_includes json, "token"
    assert_includes json, "status"
    assert_includes json, "total_usage_count"
    assert_includes json, "expires_at"
    assert_equal "active", json["status"]
  end

  # Public Endpoint Tests with Token Validation

  test "public_availability works with valid token" do
    get public_availability_calendars_path(token: @calendar.public_token)

    assert_response :success
    json = JSON.parse(response.body)
    assert_includes json, "calendar_name"
    assert_includes json, "slots"
    assert_includes json, "token_expires_at"
  end

  test "public_availability rejects expired token" do
    @calendar.update!(public_token_expires_at: 1.day.ago)

    get public_availability_calendars_path(token: @calendar.public_token)

    assert_response :forbidden
    json = JSON.parse(response.body)
    assert_equal "Token Expired", json["error"]
    assert_includes json, "message"
  end

  test "public_availability rejects revoked token" do
    @calendar.update!(public_token_revoked_at: Time.current)

    get public_availability_calendars_path(token: @calendar.public_token)

    assert_response :forbidden
    json = JSON.parse(response.body)
    assert_equal "Token Revoked", json["error"]
  end

  test "public_availability records token usage" do
    initial_count = @calendar.public_token_usage_count

    get public_availability_calendars_path(token: @calendar.public_token)

    @calendar.reload
    assert_equal initial_count + 1, @calendar.public_token_usage_count
    assert_not_nil @calendar.public_token_last_used_at
  end

  test "public_create_event works with valid token" do
    client_params = {
      name: "John Doe",
      email: "john@example.com",
      phone: "5551234567"
    }

    event_params = {
      event: {
        title: "Test Event",
        description: "Test Description",
        start_time: 1.day.from_now,
        end_time: 1.day.from_now + 1.hour,
        client: client_params
      }
    }

    post public_create_event_calendars_path(token: @calendar.public_token),
      params: event_params,
      as: :json

    assert_response :created
    json = JSON.parse(response.body)
    assert_equal true, json["success"]
    assert_includes json, "event"
    assert_includes json, "client"

    # Verify token usage was recorded
    @calendar.reload
    assert @calendar.public_token_usage_count > 0
  end

  test "public_create_event rejects expired token" do
    @calendar.update!(public_token_expires_at: 1.day.ago)

    event_params = {
      event: {
        title: "Test Event",
        start_time: 1.day.from_now,
        end_time: 1.day.from_now + 1.hour,
        client: { name: "John Doe", email: "john@example.com" }
      }
    }

    post public_create_event_calendars_path(token: @calendar.public_token),
      params: event_params,
      as: :json

    assert_response :forbidden
    json = JSON.parse(response.body)
    assert_equal "Token Expired", json["error"]
  end

  test "public_delete_last_event works with valid token" do
    # Create an event first
    event = @calendar.events.create!(
      title: "Test Event",
      start_time: 1.day.from_now,
      end_time: 1.day.from_now + 1.hour,
      client: clients(:one)
    )

    delete public_delete_last_event_calendars_path(token: @calendar.public_token)

    assert_response :success
    json = JSON.parse(response.body)
    assert_equal true, json["success"]
    assert_includes json, "deleted_event"
    assert_equal event.id, json["deleted_event"]["id"]
  end

  test "public_delete_last_event rejects expired token" do
    @calendar.update!(public_token_expires_at: 1.day.ago)

    delete public_delete_last_event_calendars_path(token: @calendar.public_token)

    assert_response :forbidden
    json = JSON.parse(response.body)
    assert_equal "Token Expired", json["error"]
  end

  # Authorization Tests

  test "token management endpoints require authentication" do
    post regenerate_token_calendar_path(@calendar)
    assert_response :unauthorized

    post revoke_token_calendar_path(@calendar)
    assert_response :unauthorized

    post extend_token_calendar_path(@calendar)
    assert_response :unauthorized

    get token_stats_calendar_path(@calendar)
    assert_response :unauthorized
  end

  private

  def generate_jwt_token(user)
    # Implement your JWT token generation logic
    # This should match your actual JWT implementation
    JWT.encode(
      { user_id: user.id, exp: 24.hours.from_now.to_i },
      Rails.application.credentials.secret_key_base
    )
  end
end

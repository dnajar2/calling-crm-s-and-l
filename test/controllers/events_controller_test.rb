require "test_helper"

class EventsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(name: "Tester", email: "t@example.com")
    @calendar = @user.calendars.create!(name: "Main")
    @client = @user.clients.create!(name: "Client A", email: "a@example.com")

    @event = @calendar.events.create!(
      client: @client,
      start_time: 1.day.from_now,
      end_time:   1.day.from_now + 30.minutes
    )
  end

  test "lists events" do
    get calendar_events_url(@calendar), as: :json
    assert_response :success
  end

  test "creates event" do
    assert_difference("@calendar.events.count") do
      post calendar_events_url(@calendar),
        params: {
          event: {
            client_id: @client.id,
            start_time: 2.days.from_now,
            end_time: 2.days.from_now + 30.minutes
          }
        },
        as: :json
    end

    assert_response :created
  end

  test "rejects overlapping event" do
    post calendar_events_url(@calendar),
      params: {
        event: {
          client_id: @client.id,
          start_time: @event.start_time + 10.minutes,
          end_time:   @event.end_time + 10.minutes
        }
      },
      as: :json

    assert_response :unprocessable_entity
  end
end

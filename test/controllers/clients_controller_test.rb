require "test_helper"

class ClientsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(name: "Test User", email: "test@example.com")
    @client = @user.clients.create!(
      name: "Client One",
      email: "client@example.com",
      phone: "123"
    )
  end

  test "lists only current user's clients" do
    other_user = User.create!(name: "Other", email: "other@example.com")
    other_user.clients.create!(name: "Other Client")

    get clients_url, as: :json
    assert_response :success

    body = JSON.parse(response.body)
    assert_equal 1, body.length
    assert_equal @client.name, body.first["name"]
  end

  test "creates a client" do
    assert_difference("@user.clients.count") do
      post clients_url,
        params: { client: { name: "New", email: "new@example.com", phone: "555" } },
        as: :json
    end

    assert_response :created
  end

  test "updates a client" do
    patch client_url(@client),
      params: { client: { name: "Updated" } },
      as: :json

    assert_response :success
    assert_equal "Updated", @client.reload.name
  end

  test "destroys a client" do
    assert_difference("Client.count", -1) do
      delete client_url(@client), as: :json
    end

    assert_response :no_content
  end
end

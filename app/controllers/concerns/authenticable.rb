module Authenticable
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_request!, unless: :skip_authentication?
    attr_reader :current_user
  end

  private

  def authenticate_request!
    token = extract_token_from_header
    return render_unauthorized("Missing token") unless token

    begin
      payload = JwtService.decode(token)
      return render_unauthorized("Invalid token type") unless payload["type"] == "access"

      @current_user = User.find_by(id: payload["user_id"])
      return render_unauthorized("User not found") unless @current_user
    rescue JwtService::TokenExpiredError
      render_unauthorized("Token expired")
    rescue JwtService::InvalidTokenError
      render_unauthorized("Invalid token")
    end
  end

  def extract_token_from_header
    auth_header = request.headers["Authorization"]
    return nil unless auth_header

    auth_header.split(" ").last if auth_header.start_with?("Bearer ")
  end

  def render_unauthorized(message = "Unauthorized")
    render json: { error: message }, status: :unauthorized
  end

  def skip_authentication?
    false
  end
end

class OauthController < ApplicationController
  skip_before_action :authenticate_request!

  # GET /auth/:provider/callback
  def callback
    auth = request.env["omniauth.auth"]

    user = User.from_omniauth(auth)

    if user.persisted?
      tokens = generate_tokens(user)

      # Redirect to frontend with tokens (adjust URL for your frontend)
      redirect_to "#{frontend_url}/auth/callback?access_token=#{tokens[:access_token]}&refresh_token=#{tokens[:refresh_token]}", allow_other_host: true
    else
      redirect_to "#{frontend_url}/auth/failure?error=authentication_failed", allow_other_host: true
    end
  end

  # GET /auth/failure
  def failure
    error = params[:message] || "Authentication failed"
    redirect_to "#{frontend_url}/auth/failure?error=#{error}", allow_other_host: true
  end

  private

  def generate_tokens(user)
    {
      access_token: JwtService.encode_access_token(user.id),
      refresh_token: JwtService.encode_refresh_token(user.id)
    }
  end

  def frontend_url
    ENV["FRONTEND_URL"] || "http://localhost:3001"
  end

  def skip_authentication?
    true
  end
end

class AuthController < ApplicationController
  skip_before_action :authenticate_request!, only: [ :register, :login, :refresh, :forgot_password, :reset_password ]

  # POST /auth/register
  def register
    user = User.new(register_params)

    if user.save
      tokens = generate_tokens(user)
      render json: {
        user: user_response(user),
        access_token: tokens[:access_token],
        refresh_token: tokens[:refresh_token]
      }, status: :created
    else
      render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # POST /auth/login
  def login
    user = User.find_by(email: login_params[:email]&.downcase&.strip)

    if user&.authenticate(login_params[:password])
      tokens = generate_tokens(user)
      render json: {
        user: user_response(user),
        access_token: tokens[:access_token],
        refresh_token: tokens[:refresh_token]
      }
    else
      render json: { error: "Invalid email or password" }, status: :unauthorized
    end
  end

  # POST /auth/refresh
  def refresh
    refresh_token = params[:refresh_token]
    return render json: { error: "Refresh token required" }, status: :bad_request unless refresh_token

    begin
      payload = JwtService.decode(refresh_token)
      return render json: { error: "Invalid token type" }, status: :unauthorized unless payload["type"] == "refresh"

      user = User.find_by(id: payload["user_id"])
      return render json: { error: "User not found" }, status: :not_found unless user

      unless JwtService.verify_refresh_token(refresh_token, user)
        return render json: { error: "Invalid refresh token" }, status: :unauthorized
      end

      # Generate new tokens
      tokens = generate_tokens(user)
      render json: {
        access_token: tokens[:access_token],
        refresh_token: tokens[:refresh_token]
      }
    rescue JwtService::TokenExpiredError
      render json: { error: "Refresh token expired" }, status: :unauthorized
    rescue JwtService::InvalidTokenError
      render json: { error: "Invalid refresh token" }, status: :unauthorized
    end
  end

  # POST /auth/logout
  def logout
    JwtService.revoke_refresh_token(current_user)
    render json: { message: "Logged out successfully" }
  end

  # POST /auth/forgot_password
  def forgot_password
    user = User.find_by(email: params[:email]&.downcase&.strip)

    if user
      user.generate_password_reset_token
      # TODO: Send password reset email
      # AuthMailer.password_reset(user).deliver_later
      render json: { message: "Password reset instructions sent to your email" }
    else
      # Don't reveal if email exists for security
      render json: { message: "Password reset instructions sent to your email" }
    end
  end

  # POST /auth/reset_password
  def reset_password
    user = User.find_by(reset_password_token: params[:token])

    if user&.password_reset_valid?
      if user.update(password: params[:password], reset_password_token: nil, reset_password_sent_at: nil)
        render json: { message: "Password reset successfully" }
      else
        render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
      end
    else
      render json: { error: "Invalid or expired reset token" }, status: :unprocessable_entity
    end
  end

  # GET /auth/me
  def me
    render json: { user: user_response(current_user) }
  end

  private

  def register_params
    params.require(:user).permit(:name, :email, :password)
  end

  def login_params
    params.require(:user).permit(:email, :password)
  end

  def generate_tokens(user)
    {
      access_token: JwtService.encode_access_token(user.id),
      refresh_token: JwtService.encode_refresh_token(user.id)
    }
  end

  def user_response(user)
    {
      id: user.id,
      name: user.name,
      email: user.email,
      email_verified: user.email_verified,
      created_at: user.created_at
    }
  end

  def skip_authentication?
    [ "register", "login", "refresh", "forgot_password", "reset_password" ].include?(action_name)
  end
end

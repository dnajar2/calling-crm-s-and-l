class AuthMailer < ApplicationMailer
  def password_reset(user)
    @user = user
    frontend_url = ENV['FRONTEND_URL']&.chomp('/') || 'http://localhost:5173'
    @reset_url = "#{frontend_url}/reset-password?token=#{user.reset_password_token}"
    
    mail(
      to: @user.email,
      subject: "Password Reset Instructions"
    )
  end
end

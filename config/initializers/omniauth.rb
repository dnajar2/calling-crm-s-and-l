# Skip OmniAuth middleware - it requires sessions which conflict with API-only mode
# For OAuth in API mode, use token-based authentication with Google OAuth 2.0
# See oauth_controller.rb for implementation details

# Note: If you need traditional OAuth flow, you'll need to:
# 1. Enable sessions in config/application.rb
# 2. Uncomment the configuration below
# 3. Set up proper CORS for frontend callbacks

# Rails.application.config.middleware.use OmniAuth::Builder do
#   provider :google_oauth2,
#            ENV["GOOGLE_CLIENT_ID"],
#            ENV["GOOGLE_CLIENT_SECRET"],
#            {
#              scope: "email,profile",
#              prompt: "select_account",
#              image_aspect_ratio: "square",
#              image_size: 50
#            }
# end
#
# OmniAuth.config.on_failure = proc { |env|
#   OauthController.action(:failure).call(env)
# }

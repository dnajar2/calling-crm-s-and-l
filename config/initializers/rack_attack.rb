class Rack::Attack
  # Throttle all requests by IP (60rpm)
  throttle("req/ip", limit: 60, period: 1.minute) do |req|
    req.ip
  end

  # Throttle login attempts by email address
  throttle("auth/login/email", limit: 5, period: 20.minutes) do |req|
    if req.path == "/auth/login" && req.post?
      req.params.dig("user", "email")&.downcase&.strip
    end
  end

  # Throttle registration attempts by IP
  throttle("auth/register/ip", limit: 3, period: 1.hour) do |req|
    if req.path == "/auth/register" && req.post?
      req.ip
    end
  end

  # Throttle password reset requests
  throttle("auth/forgot_password/email", limit: 3, period: 1.hour) do |req|
    if req.path == "/auth/forgot_password" && req.post?
      req.params["email"]&.downcase&.strip
    end
  end

  # Throttle public calendar endpoints more aggressively
  throttle("public/calendar/ip", limit: 30, period: 1.minute) do |req|
    if req.path.start_with?("/calendars/public/")
      req.ip
    end
  end

  # Throttle AI chat endpoint
  throttle("ai/chat/ip", limit: 10, period: 1.minute) do |req|
    if req.path == "/ai/chat" && req.post?
      req.ip
    end
  end

  # Custom response for throttled requests
  self.throttled_responder = lambda do |request|
    match_data = request.env["rack.attack.match_data"]
    now = match_data[:epoch_time]

    headers = {
      "RateLimit-Limit" => match_data[:limit].to_s,
      "RateLimit-Remaining" => "0",
      "RateLimit-Reset" => (now + (match_data[:period] - now % match_data[:period])).to_s,
      "Content-Type" => "application/json"
    }

    [ 429, headers, [ { error: "Rate limit exceeded. Try again later." }.to_json ] ]
  end
end

# Enable Rack::Attack
Rails.application.config.middleware.use Rack::Attack

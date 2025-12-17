class JwtService
  SECRET_KEY = Rails.application.credentials.secret_key_base || ENV.fetch("SECRET_KEY_BASE", "development_secret")
  ACCESS_TOKEN_EXPIRATION = 15.minutes
  REFRESH_TOKEN_EXPIRATION = 7.days

  class << self
    def encode_access_token(user_id)
      payload = {
        user_id: user_id,
        exp: ACCESS_TOKEN_EXPIRATION.from_now.to_i,
        type: "access"
      }
      JWT.encode(payload, SECRET_KEY, "HS256")
    end

    def encode_refresh_token(user_id)
      payload = {
        user_id: user_id,
        exp: REFRESH_TOKEN_EXPIRATION.from_now.to_i,
        type: "refresh"
      }
      token = JWT.encode(payload, SECRET_KEY, "HS256")

      # Store refresh token hash in database
      user = User.find(user_id)
      user.update(refresh_token: Digest::SHA256.hexdigest(token))

      token
    end

    def decode(token)
      begin
        decoded = JWT.decode(token, SECRET_KEY, true, { algorithm: "HS256" })
        decoded[0]
      rescue JWT::ExpiredSignature
        raise TokenExpiredError
      rescue JWT::DecodeError
        raise InvalidTokenError
      end
    end

    def verify_refresh_token(token, user)
      token_hash = Digest::SHA256.hexdigest(token)
      user.refresh_token == token_hash
    end

    def revoke_refresh_token(user)
      user.update(refresh_token: nil)
    end
  end

  class TokenExpiredError < StandardError; end
  class InvalidTokenError < StandardError; end
end

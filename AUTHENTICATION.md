# Authentication Guide

This document provides detailed information about the authentication system implemented in Callab.

## Overview

Callab uses JWT (JSON Web Tokens) for authentication with the following features:

- **JWT-based authentication** with access and refresh tokens
- **Password-based registration and login**
- **Google OAuth 2.0 support** (optional, for frontend implementations)
- **Rate limiting** to prevent abuse
- **Password reset functionality** (email integration required)
- **Secure token storage** using bcrypt password hashing

## Token Types

### Access Token
- **Lifetime**: 15 minutes
- **Purpose**: Used for all API requests
- **Header**: `Authorization: Bearer <access_token>`
- **Contains**: User ID, expiration time, token type

### Refresh Token
- **Lifetime**: 7 days
- **Purpose**: Used to obtain new access tokens
- **Storage**: Hashed in database (SHA-256)
- **Contains**: User ID, expiration time, token type

## API Endpoints

### Registration

**Endpoint**: `POST /auth/register`

**Request Body**:
```json
{
  "user": {
    "name": "John Doe",
    "email": "john@example.com",
    "password": "securepassword123"
  }
}
```

**Response** (201 Created):
```json
{
  "user": {
    "id": 1,
    "name": "John Doe",
    "email": "john@example.com",
    "email_verified": false,
    "created_at": "2025-01-01T00:00:00.000Z"
  },
  "access_token": "eyJhbGc...",
  "refresh_token": "eyJhbGc..."
}
```

**Validations**:
- Email must be valid format
- Email must be unique
- Password must be at least 8 characters
- Name is required

---

### Login

**Endpoint**: `POST /auth/login`

**Request Body**:
```json
{
  "user": {
    "email": "john@example.com",
    "password": "securepassword123"
  }
}
```

**Response** (200 OK):
```json
{
  "user": {
    "id": 1,
    "name": "John Doe",
    "email": "john@example.com",
    "email_verified": false,
    "created_at": "2025-01-01T00:00:00.000Z"
  },
  "access_token": "eyJhbGc...",
  "refresh_token": "eyJhbGc..."
}
```

**Error Response** (401 Unauthorized):
```json
{
  "error": "Invalid email or password"
}
```

---

### Refresh Token

**Endpoint**: `POST /auth/refresh`

**Request Body**:
```json
{
  "refresh_token": "eyJhbGc..."
}
```

**Response** (200 OK):
```json
{
  "access_token": "eyJhbGc...",
  "refresh_token": "eyJhbGc..."
}
```

**Error Responses**:
- `400 Bad Request`: Missing refresh token
- `401 Unauthorized`: Invalid or expired refresh token

---

### Logout

**Endpoint**: `POST /auth/logout`

**Headers**:
```
Authorization: Bearer <access_token>
```

**Response** (200 OK):
```json
{
  "message": "Logged out successfully"
}
```

**Note**: This revokes the refresh token. The access token will remain valid until expiration.

---

### Get Current User

**Endpoint**: `GET /auth/me`

**Headers**:
```
Authorization: Bearer <access_token>
```

**Response** (200 OK):
```json
{
  "user": {
    "id": 1,
    "name": "John Doe",
    "email": "john@example.com",
    "email_verified": false,
    "created_at": "2025-01-01T00:00:00.000Z"
  }
}
```

---

### Forgot Password

**Endpoint**: `POST /auth/forgot_password`

**Request Body**:
```json
{
  "email": "john@example.com"
}
```

**Response** (200 OK):
```json
{
  "message": "Password reset instructions sent to your email"
}
```

**Note**: Always returns success to prevent email enumeration. Email functionality must be configured separately.

---

### Reset Password

**Endpoint**: `POST /auth/reset_password`

**Request Body**:
```json
{
  "token": "reset_token_from_email",
  "password": "newsecurepassword123"
}
```

**Response** (200 OK):
```json
{
  "message": "Password reset successfully"
}
```

**Error Response** (422 Unprocessable Entity):
```json
{
  "error": "Invalid or expired reset token"
}
```

## Usage Examples

### Complete Authentication Flow

```bash
#!/bin/bash

# 1. Register a new user
REGISTER_RESPONSE=$(curl -s -X POST http://localhost:3000/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "user": {
      "name": "John Doe",
      "email": "john@example.com",
      "password": "securepass123"
    }
  }')

# Extract tokens
ACCESS_TOKEN=$(echo "$REGISTER_RESPONSE" | jq -r '.access_token')
REFRESH_TOKEN=$(echo "$REGISTER_RESPONSE" | jq -r '.refresh_token')

# 2. Make authenticated requests
curl -X GET http://localhost:3000/calendars \
  -H "Authorization: Bearer $ACCESS_TOKEN"

# 3. Refresh token when access token expires
NEW_TOKENS=$(curl -s -X POST http://localhost:3000/auth/refresh \
  -H "Content-Type: application/json" \
  -d "{\"refresh_token\": \"$REFRESH_TOKEN\"}")

ACCESS_TOKEN=$(echo "$NEW_TOKENS" | jq -r '.access_token')

# 4. Logout
curl -X POST http://localhost:3000/auth/logout \
  -H "Authorization: Bearer $ACCESS_TOKEN"
```

### JavaScript/TypeScript Example

```typescript
class AuthService {
  private accessToken: string | null = null;
  private refreshToken: string | null = null;

  async register(name: string, email: string, password: string) {
    const response = await fetch('http://localhost:3000/auth/register', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ user: { name, email, password } })
    });

    const data = await response.json();
    this.accessToken = data.access_token;
    this.refreshToken = data.refresh_token;

    return data.user;
  }

  async login(email: string, password: string) {
    const response = await fetch('http://localhost:3000/auth/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ user: { email, password } })
    });

    const data = await response.json();
    this.accessToken = data.access_token;
    this.refreshToken = data.refresh_token;

    return data.user;
  }

  async refreshAccessToken() {
    const response = await fetch('http://localhost:3000/auth/refresh', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ refresh_token: this.refreshToken })
    });

    const data = await response.json();
    this.accessToken = data.access_token;
    this.refreshToken = data.refresh_token;
  }

  async makeAuthenticatedRequest(url: string, options: RequestInit = {}) {
    const headers = {
      ...options.headers,
      'Authorization': `Bearer ${this.accessToken}`,
      'Content-Type': 'application/json'
    };

    let response = await fetch(url, { ...options, headers });

    // Auto-refresh if token expired
    if (response.status === 401) {
      await this.refreshAccessToken();
      headers['Authorization'] = `Bearer ${this.accessToken}`;
      response = await fetch(url, { ...options, headers });
    }

    return response.json();
  }

  async logout() {
    await fetch('http://localhost:3000/auth/logout', {
      method: 'POST',
      headers: { 'Authorization': `Bearer ${this.accessToken}` }
    });

    this.accessToken = null;
    this.refreshToken = null;
  }
}
```

## Rate Limiting

The following rate limits are enforced:

| Endpoint | Limit | Period | Identifier |
|----------|-------|--------|------------|
| All requests | 60 requests | 1 minute | IP address |
| Login | 5 attempts | 20 minutes | Email address |
| Registration | 3 attempts | 1 hour | IP address |
| Password reset | 3 requests | 1 hour | Email address |
| Public calendar | 30 requests | 1 minute | IP address |
| AI chat | 10 requests | 1 minute | IP address |

**Rate Limit Response** (429 Too Many Requests):
```json
{
  "error": "Rate limit exceeded. Try again later."
}
```

**Headers** (included in rate-limited responses):
- `RateLimit-Limit`: Maximum number of requests allowed
- `RateLimit-Remaining`: Number of requests remaining
- `RateLimit-Reset`: Unix timestamp when the limit resets

## Security Best Practices

### Token Storage

**Frontend (Browser)**:
- **Access Token**: Store in memory (React state, Vuex store, etc.)
- **Refresh Token**: Store in httpOnly cookie (recommended) or secure storage

**Mobile Apps**:
- Use secure storage (iOS Keychain, Android KeyStore)
- Never store tokens in plain text

### Token Refresh Strategy

Implement automatic token refresh:

```typescript
// Refresh token 5 minutes before expiration
const TOKEN_LIFETIME = 15 * 60 * 1000; // 15 minutes
const REFRESH_BEFORE = 5 * 60 * 1000; // 5 minutes

setTimeout(() => {
  refreshAccessToken();
}, TOKEN_LIFETIME - REFRESH_BEFORE);
```

### Password Requirements

- Minimum 8 characters
- Consider adding complexity requirements in production
- Use strong password hashing (bcrypt with cost factor 12)

### HTTPS

Always use HTTPS in production to prevent token interception.

## OAuth 2.0 Support

For frontend applications that need Google OAuth:

1. Get OAuth credentials from [Google Cloud Console](https://console.cloud.google.com/)
2. Configure environment variables:
   ```
   GOOGLE_CLIENT_ID=your_client_id
   GOOGLE_CLIENT_SECRET=your_client_secret
   FRONTEND_URL=https://your-frontend-domain.com
   ```
3. Enable sessions in `config/application.rb` (OAuth requires session support)
4. Uncomment OAuth configuration in `config/initializers/omniauth.rb`

**Note**: The default setup is API-only mode without OAuth middleware. For OAuth support, you'll need to enable sessions.

## Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `SECRET_KEY_BASE` | Secret for JWT signing | ✅ Yes |
| `GOOGLE_CLIENT_ID` | Google OAuth client ID | OAuth only |
| `GOOGLE_CLIENT_SECRET` | Google OAuth secret | OAuth only |
| `FRONTEND_URL` | Frontend URL for redirects | OAuth only |

Generate `SECRET_KEY_BASE`:
```bash
openssl rand -hex 64
```

## Protected Endpoints

All endpoints require authentication except:

**Public Endpoints** (No authentication required):
- `POST /auth/register`
- `POST /auth/login`
- `POST /auth/refresh`
- `POST /auth/forgot_password`
- `POST /auth/reset_password`
- `GET /calendars/public/:token/availability`
- `POST /calendars/public/:token/events`
- `GET /up` (health check)

**Protected Endpoints** (Require `Authorization: Bearer <token>`):
- All `/clients` endpoints
- All `/calendars` endpoints (except public)
- All `/events` endpoints
- All `/notes` endpoints
- `POST /ai/chat`
- `GET /auth/me`
- `POST /auth/logout`

## Error Handling

### Authentication Errors

**401 Unauthorized**:
```json
{
  "error": "Missing token"
}
```

```json
{
  "error": "Invalid token"
}
```

```json
{
  "error": "Token expired"
}
```

```json
{
  "error": "User not found"
}
```

### Validation Errors

**422 Unprocessable Entity**:
```json
{
  "errors": [
    "Email has already been taken",
    "Password is too short (minimum is 8 characters)"
  ]
}
```

## Testing

Run the authentication test suite:

```bash
./test_auth.sh
```

Or manually test endpoints:

```bash
# Register
curl -X POST http://localhost:3000/auth/register \
  -H "Content-Type: application/json" \
  -d '{"user":{"name":"Test","email":"test@example.com","password":"password123"}}'

# Login
curl -X POST http://localhost:3000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"user":{"email":"test@example.com","password":"password123"}}'

# Access protected endpoint
curl -X GET http://localhost:3000/calendars \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## Troubleshooting

### "Missing token" error

Ensure the `Authorization` header is set:
```
Authorization: Bearer <your_access_token>
```

### "Token expired" error

Use the refresh token endpoint to get a new access token:
```bash
curl -X POST http://localhost:3000/auth/refresh \
  -H "Content-Type: application/json" \
  -d '{"refresh_token":"YOUR_REFRESH_TOKEN"}'
```

### "Invalid token" error

- Check that the token hasn't been tampered with
- Verify `SECRET_KEY_BASE` is consistent across deployments
- Ensure the token format is correct (should start with "eyJ")

### Rate limit errors

Wait for the rate limit period to expire, or contact the API administrator to adjust limits in `config/initializers/rack_attack.rb`.

## Production Checklist

Before deploying to production:

- [ ] Set a strong `SECRET_KEY_BASE` (64+ character random string)
- [ ] Configure HTTPS/SSL
- [ ] Set up email service for password resets
- [ ] Configure CORS for frontend domains
- [ ] Review and adjust rate limits
- [ ] Enable logging and monitoring
- [ ] Set up database backups
- [ ] Configure secure session storage (if using OAuth)
- [ ] Test token expiration and refresh flows
- [ ] Implement token blacklisting for logged-out users (optional)

## Support

For issues or questions about authentication, please refer to:
- [Main README](README.md)
- [API Documentation](API_DOCUMENTATION.md)
- GitHub Issues

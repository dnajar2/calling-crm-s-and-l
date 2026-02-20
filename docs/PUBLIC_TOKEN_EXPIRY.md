# Public Token Expiry System

## Overview

The Callab public token expiry system provides enterprise-grade security for public calendar links by implementing automatic token expiration, usage tracking, rate limiting, and comprehensive token management capabilities.

## Key Features

- **Automatic Expiration**: Tokens expire after 30 days (configurable)
- **Token Lifecycle Management**: Regenerate, revoke, or extend tokens
- **Usage Analytics**: Track token usage and access patterns
- **Rate Limiting**: Prevent abuse with configurable rate limits
- **Email Notifications**: Automatic alerts before expiration
- **Backward Compatibility**: Existing tokens auto-migrated with 30-day expiry

## Architecture

### Database Schema

New fields added to `calendars` table:

```ruby
public_token_expires_at    :datetime   # Token expiration timestamp
public_token_last_used_at  :datetime   # Last access timestamp
public_token_revoked_at    :datetime   # Manual revocation timestamp
public_token_usage_count   :integer    # Total usage counter (default: 0)
```

### Token States

A public token can be in one of four states:

1. **Active**: Valid and usable
   - `public_token` is present
   - `public_token_revoked_at` is NULL
   - `public_token_expires_at` is in the future (or NULL)

2. **Expired**: Past expiration date
   - `public_token_expires_at` is in the past

3. **Revoked**: Manually disabled by user
   - `public_token_revoked_at` is set

4. **Inactive**: No token generated
   - `public_token` is NULL

## API Endpoints

### Public Endpoints (No Authentication Required)

All public endpoints automatically validate token status and record usage.

#### GET `/calendars/public/:token/availability`

Retrieve calendar availability for a specific date.

**Response - Success (200)**:
```json
{
  "calendar_name": "My Calendar",
  "timezone": "America/Los_Angeles",
  "date": "2025-01-15",
  "slots": [...],
  "token_expires_at": "2025-02-15T10:00:00Z",
  "token_expiring_soon": false
}
```

**Response - Expired Token (403)**:
```json
{
  "error": "Token Expired",
  "message": "This public link has expired. Please contact the calendar owner for a new link.",
  "expired_at": "2025-01-01T10:00:00Z",
  "support_message": "Public links are valid for 30 days from creation."
}
```

**Response - Revoked Token (403)**:
```json
{
  "error": "Token Revoked",
  "message": "This public link has been revoked by the calendar owner.",
  "support_message": "Please request a new link from the calendar owner."
}
```

**Response - Rate Limit (429)**:
```json
{
  "error": "Rate Limit Exceeded",
  "message": "Too many requests. Please try again later.",
  "retry_after": 3600
}
```

#### POST `/calendars/public/:token/events`

Create an event using the public token.

Same error responses as above for expired/revoked/rate-limited tokens.

#### DELETE `/calendars/public/:token/events/last`

Delete the most recent event (for testing).

Same error responses as above for expired/revoked/rate-limited tokens.

### Authenticated Endpoints (Require User Authentication)

#### POST `/calendars/:id/regenerate_token`

Generate a new public token, invalidating the old one.

**Request**:
```json
{
  "expiry_days": 60  // Optional, defaults to 30
}
```

**Response (200)**:
```json
{
  "success": true,
  "message": "Public token regenerated successfully",
  "calendar": {
    "id": 1,
    "name": "My Calendar",
    "public_token": "new_token_here",
    "public_token_expires_at": "2025-03-15T10:00:00Z"
  }
}
```

**Use Cases**:
- Token has been compromised
- Need to revoke all existing links
- Want a fresh start with new expiry

#### POST `/calendars/:id/revoke_token`

Immediately revoke the current token without generating a new one.

**Response (200)**:
```json
{
  "success": true,
  "message": "Public token revoked successfully"
}
```

**Use Cases**:
- Temporarily disable public access
- Security incident response
- Calendar should no longer be public

#### POST `/calendars/:id/extend_token`

Extend the expiry date of the current active token.

**Request**:
```json
{
  "additional_days": 30  // Optional, defaults to 30
}
```

**Response (200)**:
```json
{
  "success": true,
  "message": "Token expiry extended successfully",
  "new_expires_at": "2025-04-15T10:00:00Z",
  "days_until_expiry": 75
}
```

**Response - Failed (422)**:
```json
{
  "error": "Failed to extend token"
}
```

**Use Cases**:
- Token expiring soon but URL is embedded in external systems
- Want to maintain the same link for continuity
- Gradual transition to new token

**Note**: Cannot extend expired or revoked tokens. Use `regenerate_token` instead.

#### GET `/calendars/:id/token_stats`

Get comprehensive analytics about the public token.

**Response (200)**:
```json
{
  "token": "AbCdEf12...XyZ9",
  "status": "active",
  "total_usage_count": 1247,
  "last_used_at": "2025-01-14T15:30:00Z",
  "expires_at": "2025-02-15T10:00:00Z",
  "days_until_expiry": 32,
  "expiring_soon": false,
  "created_events_count": 45,
  "created_events_last_30_days": 12
}
```

**Token Status Values**:
- `active` - Token is valid and usable
- `expired` - Token has passed expiration date
- `revoked` - Token was manually revoked
- `inactive` - No token exists

## Calendar Model API

### Instance Methods

#### Token Status Checks

```ruby
calendar.public_token_active?        # => true/false
calendar.public_token_expired?       # => true/false
calendar.public_token_revoked?       # => true/false
calendar.public_token_expiring_soon? # => true/false (within 7 days)
```

#### Token Information

```ruby
calendar.days_until_token_expires    # => Integer or nil
calendar.public_token_stats          # => Hash (see API response above)
```

#### Token Management

```ruby
# Regenerate token with new expiry
calendar.regenerate_public_token!(expiry_days: 60)

# Revoke current token
calendar.revoke_public_token!

# Extend current token expiry
calendar.extend_public_token!(additional_days: 30)

# Record token usage (called automatically by controller)
calendar.record_token_usage!

# Check rate limiting
calendar.token_usage_rate_limit_exceeded? # => true/false
```

### Scopes

```ruby
Calendar.with_active_tokens         # Active, non-expired, non-revoked
Calendar.with_expired_tokens        # Tokens past expiration
Calendar.with_expiring_soon_tokens  # Expiring within 7 days
```

### Constants

```ruby
Calendar::DEFAULT_TOKEN_EXPIRY_DAYS      # 30
Calendar::TOKEN_EXPIRY_WARNING_DAYS      # 7
Calendar::MAX_TOKEN_USAGE_PER_HOUR       # 100
```

## Background Jobs

### PublicTokenMaintenanceJob

Runs daily to maintain token health and send notifications.

**Schedule**: Daily (recommended: 2 AM UTC)

**Tasks**:
1. Send expiry warning emails (7 days before expiration)
2. Auto-revoke expired tokens (optional, configurable)
3. Log token statistics

**Configuration**:
```bash
# .env
CLEANUP_EXPIRED_TOKENS=true  # Auto-revoke expired tokens
```

**Manual Execution**:
```ruby
PublicTokenMaintenanceJob.perform_now
```

## Email Notifications

### Expiry Warning Email

**Trigger**: 7 days before token expiration

**Subject**: "Your public calendar link expires in X days"

**Content**:
- Days remaining
- Expiration date
- Instructions to extend or regenerate

### Token Regenerated Email

**Trigger**: User regenerates token via API

**Subject**: "Your public calendar link has been regenerated"

**Content**:
- New token URL
- New expiration date
- Security reminder

## Security Features

### 1. Token Generation

- 32-byte cryptographically secure random tokens
- URL-safe base64 encoding
- Automatic collision detection

### 2. Rate Limiting

- Maximum 100 requests per hour per token
- Implemented at application level
- Returns HTTP 429 when exceeded

**Production Recommendation**: Use Redis-based rate limiting (e.g., `rack-attack` gem) for distributed systems.

### 3. Token Validation

All public endpoints automatically validate:
1. Token exists
2. Token not revoked
3. Token not expired
4. Rate limit not exceeded

### 4. Audit Trail

Token usage tracking provides:
- Total usage count
- Last used timestamp
- Event creation history
- Usage patterns over time

## Migration Guide

### Existing Tokens

The migration automatically:
1. Adds expiry fields to all calendars
2. Sets 30-day expiry for existing tokens
3. Initializes usage counters to 0
4. Preserves all existing tokens

**No action required** - existing integrations continue working with new 30-day expiry.

### User Communication

Recommended email to users before deployment:

```
Subject: New Security Feature: Public Link Expiration

We're enhancing security by adding automatic expiration to public calendar links.

What's Changing:
- Public links now expire after 30 days
- You'll receive email reminders 7 days before expiration
- Your existing links have been extended for 30 days from today
- You can easily regenerate, extend, or revoke links anytime

What You Need to Do:
- Nothing! Your current links continue working
- Monitor expiry notifications
- Use the dashboard to manage link expiration

Benefits:
- Enhanced security for your calendar data
- Better control over who can access your calendar
- Protection against leaked or shared links
```

## Best Practices

### For Calendar Owners

1. **Regular Review**: Check token stats monthly
2. **Timely Renewal**: Act on expiry warnings promptly
3. **Use Extensions**: Extend vs regenerate when possible (maintains URL)
4. **Monitor Usage**: Review analytics for unusual patterns
5. **Revoke When Needed**: Don't hesitate to revoke compromised tokens

### For Integration Partners

1. **Handle Expiry**: Implement graceful handling of 403 expired responses
2. **Monitor Responses**: Watch for `token_expiring_soon: true` in API responses
3. **Request Renewal**: Proactively ask users to extend expiring tokens
4. **Cache Tokens**: But respect expiry headers
5. **Implement Retry**: With exponential backoff for rate limits

### For Developers

1. **Use Scopes**: Leverage model scopes for queries
2. **Background Jobs**: Schedule `PublicTokenMaintenanceJob` daily
3. **Monitor Logs**: Watch for rate limit and expiry patterns
4. **Configure Alerts**: Set up monitoring for high error rates
5. **Test Thoroughly**: Use provided test suite

## Troubleshooting

### Common Issues

**Issue**: "Token Expired" error but I just created it
- **Solution**: Check server time sync, verify expiry date in database

**Issue**: Rate limit errors despite low usage
- **Solution**: Check for request loops, verify hourly usage count

**Issue**: Expiry emails not sending
- **Solution**: Verify `PublicTokenMaintenanceJob` is scheduled, check SMTP configuration

**Issue**: Can't extend expired token
- **Solution**: Use `regenerate_token` instead - extension only works for active tokens

### Database Queries

```sql
-- Find all active tokens
SELECT * FROM calendars
WHERE public_token IS NOT NULL
  AND public_token_revoked_at IS NULL
  AND public_token_expires_at > NOW();

-- Find tokens expiring in next 7 days
SELECT * FROM calendars
WHERE public_token_expires_at BETWEEN NOW() AND NOW() + INTERVAL '7 days';

-- Find most used tokens
SELECT id, name, public_token_usage_count
FROM calendars
ORDER BY public_token_usage_count DESC
LIMIT 10;
```

## Performance Considerations

### Database Indexes

Created automatically by migration:
- `index_calendars_on_public_token_expires_at`
- `index_calendars_on_public_token_revoked_at` (partial index)

### Optimization Tips

1. **Use Scopes**: Pre-optimized queries with proper indexes
2. **Batch Processing**: Background job processes in batches
3. **Cache Token Stats**: Consider caching stats for high-traffic calendars
4. **Rate Limiting**: Implement Redis-based rate limiting for scale

## Future Enhancements

Potential additions:

1. **IP Allowlisting**: Restrict tokens to specific IP ranges
2. **Usage Quotas**: Limit total events created per token
3. **Custom Expiry**: Per-calendar configurable expiry periods
4. **Token Scopes**: Fine-grained permissions per token
5. **Webhook Notifications**: Real-time alerts for token events
6. **Multi-token Support**: Multiple tokens per calendar with different permissions

## Support

For questions or issues:
- GitHub Issues: [callab/issues](https://github.com/yourorg/callab/issues)
- Documentation: [callab.app/docs](https://callab.app/docs)
- Email: support@callab.app

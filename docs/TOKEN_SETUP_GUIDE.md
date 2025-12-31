# Public Token Expiry - Setup Guide

## Quick Start

This guide will help you set up and configure the public token expiry system.

## Prerequisites

- Rails 8.1+
- PostgreSQL database
- Docker (if using containerized setup)

## Installation Steps

### 1. Run Migration

The migration has already been run in your Docker environment. If setting up on a new environment:

```bash
# Local development
rails db:migrate

# Docker
docker compose run app bundle exec rails db:migrate
```

### 2. Configure Environment Variables

Add to your `.env` file:

```bash
# Token cleanup configuration
CLEANUP_EXPIRED_TOKENS=true

# Email configuration (for expiry notifications)
MAILER_FROM_EMAIL=noreply@callab.app
FRONTEND_URL=https://callab.app

# SMTP settings (if not already configured)
SMTP_ADDRESS=smtp.sendgrid.net
SMTP_PORT=587
SMTP_DOMAIN=callab.app
SMTP_USERNAME=apikey
SMTP_PASSWORD=your_sendgrid_api_key
SMTP_FROM_EMAIL=noreply@callab.app
```

### 3. Schedule Background Job

Add to your scheduler (e.g., `config/schedule.rb` for Whenever gem):

```ruby
# Run token maintenance daily at 2 AM
every 1.day, at: '2:00 am' do
  runner "PublicTokenMaintenanceJob.perform_now"
end
```

Or if using Sidekiq:

```ruby
# config/initializers/sidekiq.rb
Sidekiq::Cron::Job.create(
  name: 'Public Token Maintenance',
  cron: '0 2 * * *', # Daily at 2 AM
  class: 'PublicTokenMaintenanceJob'
)
```

For development/testing, run manually:

```bash
rails runner "PublicTokenMaintenanceJob.perform_now"
```

### 4. Verify Installation

Check that everything is working:

```bash
# In Rails console
rails console

# Check existing calendars have expiry set
Calendar.where.not(public_token: nil).pluck(:public_token_expires_at)

# Should return array of datetime objects 30 days from migration date

# Test token creation
calendar = Calendar.first
calendar.public_token_stats
# Should return comprehensive stats hash

# Test token regeneration
calendar.regenerate_public_token!
calendar.public_token_expires_at
# Should be ~30 days from now
```

### 5. Test Email Delivery

```bash
rails console

calendar = Calendar.with_expiring_soon_tokens.first
PublicTokenMailer.expiry_warning(calendar).deliver_now
```

Check your email (or logs in development) for the warning message.

## Configuration Options

### Token Expiry Duration

Default is 30 days. To change globally, update the constant:

```ruby
# app/models/calendar.rb
DEFAULT_TOKEN_EXPIRY_DAYS = 60  # Change to desired days
```

Or set per-token when regenerating:

```ruby
calendar.regenerate_public_token!(expiry_days: 90)
```

### Warning Period

Default is 7 days before expiry. To change:

```ruby
# app/models/calendar.rb
TOKEN_EXPIRY_WARNING_DAYS = 14  # Warn 2 weeks before
```

### Rate Limiting

Default is 100 requests per hour per token. To change:

```ruby
# app/models/calendar.rb
MAX_TOKEN_USAGE_PER_HOUR = 200  # Increase limit
```

**Production Note**: Consider using Redis-based rate limiting (rack-attack gem) for better distributed rate limiting.

## Testing

Run the test suite:

```bash
# Run all tests
rails test

# Run only token tests
rails test test/models/calendar_token_test.rb
rails test test/controllers/calendars_controller_token_test.rb
```

## API Usage Examples

### Using cURL

```bash
# Get calendar availability (public endpoint)
curl https://callab.app/calendars/public/YOUR_TOKEN/availability

# Regenerate token (authenticated)
curl -X POST https://callab.app/calendars/1/regenerate_token \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"expiry_days": 60}'

# Get token stats (authenticated)
curl https://callab.app/calendars/1/token_stats \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"

# Extend token (authenticated)
curl -X POST https://callab.app/calendars/1/extend_token \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"additional_days": 30}'

# Revoke token (authenticated)
curl -X POST https://callab.app/calendars/1/revoke_token \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

### Using JavaScript

```javascript
// Get calendar availability (public)
fetch(`https://callab.app/calendars/public/${token}/availability`)
  .then(response => response.json())
  .then(data => {
    console.log('Availability:', data.slots);
    console.log('Token expires:', data.token_expires_at);
    if (data.token_expiring_soon) {
      console.warn('Token expiring soon!');
    }
  })
  .catch(error => {
    if (error.status === 403) {
      console.error('Token expired or revoked');
    }
  });

// Regenerate token (authenticated)
fetch('https://callab.app/calendars/1/regenerate_token', {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${jwtToken}`,
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({ expiry_days: 60 })
})
  .then(response => response.json())
  .then(data => {
    console.log('New token:', data.calendar.public_token);
    console.log('Expires:', data.calendar.public_token_expires_at);
  });
```

## Monitoring

### Key Metrics to Track

1. **Token Expiry Rate**: How many tokens expire daily
2. **Extension Rate**: How often users extend vs regenerate
3. **Revocation Rate**: Manual revocations (security incidents?)
4. **Usage Patterns**: Peak usage times and rates
5. **Email Delivery**: Warning email success rate

### Recommended Queries

```sql
-- Active tokens count
SELECT COUNT(*) FROM calendars
WHERE public_token IS NOT NULL
  AND public_token_revoked_at IS NULL
  AND public_token_expires_at > NOW();

-- Tokens expiring this week
SELECT COUNT(*) FROM calendars
WHERE public_token_expires_at BETWEEN NOW() AND NOW() + INTERVAL '7 days';

-- Average token usage
SELECT AVG(public_token_usage_count) FROM calendars
WHERE public_token IS NOT NULL;

-- Most active tokens
SELECT id, name, public_token_usage_count, public_token_last_used_at
FROM calendars
WHERE public_token IS NOT NULL
ORDER BY public_token_usage_count DESC
LIMIT 20;
```

### Rails Console Helpers

```ruby
# Get system-wide token stats
def token_stats
  {
    total_calendars: Calendar.count,
    active_tokens: Calendar.with_active_tokens.count,
    expired_tokens: Calendar.with_expired_tokens.count,
    expiring_soon: Calendar.with_expiring_soon_tokens.count,
    total_usage: Calendar.sum(:public_token_usage_count),
    avg_usage: Calendar.average(:public_token_usage_count).to_f.round(2)
  }
end

# Find tokens needing attention
def tokens_needing_attention
  {
    expiring_soon: Calendar.with_expiring_soon_tokens.pluck(:id, :name),
    expired: Calendar.with_expired_tokens.pluck(:id, :name),
    high_usage: Calendar.where("public_token_usage_count > ?", 1000).pluck(:id, :name, :public_token_usage_count)
  }
end
```

## Troubleshooting

### Issue: Migration fails with "column already exists"

**Solution**: The column was already added. Check schema version:

```bash
rails db:migrate:status
```

If migration shows "up", you're good. If stuck, manually set migration version:

```bash
rails db:migrate:version VERSION=20251231161836
```

### Issue: Existing tokens don't have expiry

**Solution**: Run this in Rails console:

```ruby
Calendar.where(public_token_expires_at: nil)
  .where.not(public_token: nil)
  .update_all("public_token_expires_at = NOW() + INTERVAL '30 days'")
```

### Issue: Background job not running

**Solution**:
1. Check if job is scheduled: `Sidekiq::Cron::Job.all` (if using Sidekiq)
2. Verify queue is running: `Sidekiq::Queue.new.size`
3. Run manually to test: `PublicTokenMaintenanceJob.perform_now`

### Issue: Emails not sending

**Solution**:
1. Check SMTP configuration in `.env`
2. Verify mailer settings: `ActionMailer::Base.delivery_method`
3. Check logs: `tail -f log/development.log`
4. Test manually: `PublicTokenMailer.expiry_warning(calendar).deliver_now`

## Rollback Procedure

If you need to rollback the migration:

```bash
# Local
rails db:rollback STEP=1

# Docker
docker compose run app bundle exec rails db:rollback STEP=1
```

This will:
- Remove expiry columns
- Remove indexes
- Preserve existing public tokens (no data loss)

## Production Deployment Checklist

- [ ] Run migration in production
- [ ] Verify all existing tokens have expiry set
- [ ] Configure environment variables
- [ ] Schedule background job (cron/Sidekiq)
- [ ] Test email delivery
- [ ] Set up monitoring/alerts
- [ ] Update user documentation
- [ ] Notify users of new expiry feature
- [ ] Monitor error rates for first 24 hours
- [ ] Review token stats after 7 days

## Next Steps

1. Read the full [documentation](PUBLIC_TOKEN_EXPIRY.md)
2. Test API endpoints in your environment
3. Integrate token expiry handling in your frontend
4. Set up monitoring and alerts
5. Schedule the background job for production

## Support

For issues or questions:
- Check the [full documentation](PUBLIC_TOKEN_EXPIRY.md)
- Review test files for usage examples
- Open an issue on GitHub
- Contact: support@callab.app

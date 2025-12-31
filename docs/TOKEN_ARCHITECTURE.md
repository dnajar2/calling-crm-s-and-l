# Public Token Expiry - Architecture Diagram

## System Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                         CLIENT APPLICATIONS                          │
│  (Web Browser, Mobile App, External Integrations, n8n, Zapier)     │
└─────────────────────┬───────────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────────────┐
│                         PUBLIC API LAYER                             │
│                                                                      │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │  Public Endpoints (No Authentication)                        │  │
│  │  • GET  /calendars/public/:token/availability               │  │
│  │  • POST /calendars/public/:token/events                     │  │
│  │  • DEL  /calendars/public/:token/events/last               │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │  Authenticated Endpoints (JWT Required)                      │  │
│  │  • POST /calendars/:id/regenerate_token                     │  │
│  │  • POST /calendars/:id/revoke_token                         │  │
│  │  • POST /calendars/:id/extend_token                         │  │
│  │  • GET  /calendars/:id/token_stats                          │  │
│  └──────────────────────────────────────────────────────────────┘  │
└─────────────────────┬───────────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    VALIDATION & MIDDLEWARE LAYER                     │
│                                                                      │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │  PublicTokenValidation Concern                               │  │
│  │  ┌────────────────────────────────────────────────────────┐ │  │
│  │  │  1. Token Exists Check                                  │ │  │
│  │  │  2. Revocation Check   (public_token_revoked_at)       │ │  │
│  │  │  3. Expiry Check       (public_token_expires_at)       │ │  │
│  │  │  4. Rate Limit Check   (MAX_TOKEN_USAGE_PER_HOUR)      │ │  │
│  │  │  5. Record Usage       (increment counter, timestamp)  │ │  │
│  │  └────────────────────────────────────────────────────────┘ │  │
│  │                                                              │  │
│  │  Error Handlers:                                             │  │
│  │  • TokenExpiredError     → 403 Forbidden                    │  │
│  │  • TokenRevokedError     → 403 Forbidden                    │  │
│  │  • RateLimitExceededError → 429 Too Many Requests           │  │
│  └──────────────────────────────────────────────────────────────┘  │
└─────────────────────┬───────────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────────────┐
│                       BUSINESS LOGIC LAYER                           │
│                                                                      │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │  Calendar Model                                               │  │
│  │                                                              │  │
│  │  Status Checks:                                              │  │
│  │  • public_token_active?                                      │  │
│  │  • public_token_expired?                                     │  │
│  │  • public_token_revoked?                                     │  │
│  │  • public_token_expiring_soon?                               │  │
│  │                                                              │  │
│  │  Token Management:                                           │  │
│  │  • regenerate_public_token!(expiry_days: 30)                │  │
│  │  • revoke_public_token!                                      │  │
│  │  • extend_public_token!(additional_days: 30)                │  │
│  │  • record_token_usage!                                       │  │
│  │                                                              │  │
│  │  Analytics:                                                  │  │
│  │  • public_token_stats                                        │  │
│  │  • days_until_token_expires                                  │  │
│  │  • token_usage_rate_limit_exceeded?                          │  │
│  │                                                              │  │
│  │  Scopes:                                                     │  │
│  │  • with_active_tokens                                        │  │
│  │  • with_expired_tokens                                       │  │
│  │  • with_expiring_soon_tokens                                 │  │
│  └──────────────────────────────────────────────────────────────┘  │
└─────────────────────┬───────────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────────────┐
│                         DATABASE LAYER                               │
│                                                                      │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │  calendars table                                             │  │
│  │  ┌────────────────────────────────────────────────────────┐ │  │
│  │  │ id                     :bigint                          │ │  │
│  │  │ user_id                :bigint   (FK)                   │ │  │
│  │  │ name                   :string                          │ │  │
│  │  │ timezone               :string                          │ │  │
│  │  │ public_token           :string   (unique index)         │ │  │
│  │  │ ──────────────────────────────────────────────────────  │ │  │
│  │  │ public_token_expires_at    :datetime  (indexed) ✨NEW  │ │  │
│  │  │ public_token_last_used_at  :datetime           ✨NEW  │ │  │
│  │  │ public_token_revoked_at    :datetime  (partial idx) ✨ │ │  │
│  │  │ public_token_usage_count   :integer  (default: 0)  ✨  │ │  │
│  │  │ ──────────────────────────────────────────────────────  │ │  │
│  │  │ created_at             :datetime                        │ │  │
│  │  │ updated_at             :datetime                        │ │  │
│  │  └────────────────────────────────────────────────────────┘ │  │
│  └──────────────────────────────────────────────────────────────┘  │
└───────────────────────────────────────────────────────────────────┘


┌─────────────────────────────────────────────────────────────────────┐
│                    BACKGROUND PROCESSING LAYER                       │
│                                                                      │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │  PublicTokenMaintenanceJob                                   │  │
│  │  (Runs Daily at 2 AM)                                        │  │
│  │  ┌────────────────────────────────────────────────────────┐ │  │
│  │  │  1. Send Expiry Warnings                                │ │  │
│  │  │     - Find tokens expiring within 7 days               │ │  │
│  │  │     - Send email to calendar owners                    │ │  │
│  │  │                                                         │ │  │
│  │  │  2. Cleanup Expired Tokens                             │ │  │
│  │  │     - Find expired tokens                              │ │  │
│  │  │     - Set revoked_at timestamp                         │ │  │
│  │  │     - Log cleanup statistics                           │ │  │
│  │  │                                                         │ │  │
│  │  │  3. Log System Statistics                              │ │  │
│  │  │     - Total calendars                                  │ │  │
│  │  │     - Active/Expired/Revoked counts                    │ │  │
│  │  │     - Usage metrics                                    │ │  │
│  │  └────────────────────────────────────────────────────────┘ │  │
│  └──────────────────────────────────────────────────────────────┘  │
└─────────────────────┬───────────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      EMAIL NOTIFICATION LAYER                        │
│                                                                      │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │  PublicTokenMailer                                           │  │
│  │  ┌────────────────────────────────────────────────────────┐ │  │
│  │  │  expiry_warning(calendar)                              │ │  │
│  │  │  • Sent 7 days before expiration                       │ │  │
│  │  │  • Includes days remaining                             │ │  │
│  │  │  • Provides extend/regenerate instructions             │ │  │
│  │  │                                                         │ │  │
│  │  │  token_regenerated(calendar)                           │ │  │
│  │  │  • Sent after token regeneration                       │ │  │
│  │  │  • Includes new token URL                              │ │  │
│  │  │  • Shows new expiration date                           │ │  │
│  │  │                                                         │ │  │
│  │  │  token_expired(calendar)                               │ │  │
│  │  │  • Sent after token expires                            │ │  │
│  │  │  • Instructions to regenerate                          │ │  │
│  │  └────────────────────────────────────────────────────────┘ │  │
│  └──────────────────────────────────────────────────────────────┘  │
└───────────────────────────────────────────────────────────────────┘
```

## Token Lifecycle State Machine

```
┌──────────────┐
│   Created    │  New calendar created
│  (30 days)   │  • public_token generated
└──────┬───────┘  • expires_at = now + 30 days
       │          • usage_count = 0
       │
       ▼
┌──────────────┐
│    Active    │  Token is valid and usable
│              │  • Can access public endpoints
│              │  • Usage tracked on each request
└──┬─────┬─────┘  • Rate limiting enforced
   │     │
   │     │ Manual action
   │     ▼
   │  ┌──────────────┐
   │  │   Revoked    │  User revoked token
   │  │              │  • revoked_at timestamp set
   │  │  [TERMINAL]  │  • All requests return 403
   │  └──────────────┘  • Cannot be un-revoked
   │
   │ Time passes (30 days)
   ▼
┌──────────────┐
│   Expiring   │  Within 7 days of expiration
│    Soon      │  • Warning email sent
│ (< 7 days)   │  • token_expiring_soon: true
└──┬───┬───┬───┘  • Still functional
   │   │   │
   │   │   │ Extend
   │   │   └──────────┐
   │   │              │
   │   │ Regenerate   ▼
   │   └────────► ┌──────────────┐
   │              │   Extended   │  Expiry date pushed out
   │              │              │  • Same token
   │              │  (Active)    │  • New expires_at
   │              └──────────────┘
   │
   │ Time passes
   ▼
┌──────────────┐
│   Expired    │  Past expiration date
│              │  • All requests return 403
│  [TERMINAL]  │  • Cannot extend (must regenerate)
└──────────────┘  • Auto-revoked by maintenance job
```

## Request Flow: Public Endpoint

```
┌─────────────────────────────────────────────────────────────────────┐
│                    CLIENT REQUEST                                    │
│  GET /calendars/public/abc123xyz.../availability?date=2025-01-15   │
└─────────────────────┬───────────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────────────┐
│  1. CalendarsController#public_availability                         │
└─────────────────────┬───────────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────────────┐
│  2. find_and_validate_public_token!(token)                          │
│     [PublicTokenValidation Concern]                                 │
└─────────────────────┬───────────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────────────┐
│  3. Calendar.find_by!(public_token: token)                          │
│     • SQL query with unique index                                   │
│     • Returns calendar or raises ActiveRecord::RecordNotFound       │
└─────────────────────┬───────────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────────────┐
│  4. Validation Checks (in order)                                    │
│     ┌───────────────────────────────────────────────────────────┐  │
│     │  a) Is token revoked?                                      │  │
│     │     if revoked_at.present?                                │  │
│     │     → raise TokenRevokedError → 403 Forbidden             │  │
│     └───────────────────────────────────────────────────────────┘  │
│     ┌───────────────────────────────────────────────────────────┐  │
│     │  b) Is token expired?                                      │  │
│     │     if expires_at <= Time.current                         │  │
│     │     → raise TokenExpiredError → 403 Forbidden             │  │
│     └───────────────────────────────────────────────────────────┘  │
│     ┌───────────────────────────────────────────────────────────┐  │
│     │  c) Rate limit exceeded?                                   │  │
│     │     if usage_count > MAX per hour                         │  │
│     │     → raise RateLimitExceededError → 429 Too Many         │  │
│     └───────────────────────────────────────────────────────────┘  │
└─────────────────────┬───────────────────────────────────────────────┘
                      │  All checks passed ✓
                      ▼
┌─────────────────────────────────────────────────────────────────────┐
│  5. Record Token Usage                                              │
│     • calendar.record_token_usage!                                  │
│     • INCREMENT public_token_usage_count                            │
│     • UPDATE public_token_last_used_at = NOW()                      │
└─────────────────────┬───────────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────────────┐
│  6. Process Business Logic                                          │
│     • CalendarAvailability.new(calendar, date).slots               │
│     • Generate availability data                                    │
└─────────────────────┬───────────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────────────┐
│  7. Return Response (200 OK)                                        │
│     {                                                               │
│       "calendar_name": "...",                                       │
│       "slots": [...],                                               │
│       "token_expires_at": "2025-02-15T10:00:00Z",                  │
│       "token_expiring_soon": false                                  │
│     }                                                               │
└─────────────────────────────────────────────────────────────────────┘
```

## Security Layers

```
┌─────────────────────────────────────────────────────────────────────┐
│  LAYER 1: Token Generation                                          │
│  • 32-byte cryptographically secure random                          │
│  • URL-safe base64 encoding                                         │
│  • Automatic collision detection                                    │
│  • Unique database constraint                                       │
└─────────────────────────────────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────────────┐
│  LAYER 2: Automatic Expiration                                      │
│  • 30-day default lifetime                                          │
│  • Configurable per-token                                           │
│  • Database-enforced via timestamp                                  │
│  • Indexed for performance                                          │
└─────────────────────────────────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────────────┐
│  LAYER 3: Manual Revocation                                         │
│  • Instant invalidation capability                                  │
│  • Cannot be un-revoked (security)                                  │
│  • Separate from expiration                                         │
│  • Audit trail via revoked_at                                       │
└─────────────────────────────────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────────────┐
│  LAYER 4: Rate Limiting                                             │
│  • 100 requests/hour default                                        │
│  • Per-token enforcement                                            │
│  • Event-based counting                                             │
│  • HTTP 429 response                                                │
└─────────────────────────────────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────────────┐
│  LAYER 5: Usage Tracking                                            │
│  • Every request logged                                             │
│  • Last used timestamp                                              │
│  • Total usage counter                                              │
│  • Analytics for anomaly detection                                  │
└─────────────────────────────────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────────────┐
│  LAYER 6: Proactive Notifications                                   │
│  • 7-day warning emails                                             │
│  • User awareness                                                   │
│  • Regeneration prompts                                             │
│  • Security incident alerts                                         │
└─────────────────────────────────────────────────────────────────────┘
```

## Performance Optimizations

```
┌─────────────────────────────────────────────────────────────────────┐
│  DATABASE INDEXES                                                    │
│  ┌───────────────────────────────────────────────────────────────┐ │
│  │  index_calendars_on_public_token                              │ │
│  │  • Type: unique btree                                         │ │
│  │  • Purpose: Fast token lookup                                 │ │
│  │  • Impact: O(log n) instead of O(n)                          │ │
│  └───────────────────────────────────────────────────────────────┘ │
│  ┌───────────────────────────────────────────────────────────────┐ │
│  │  index_calendars_on_public_token_expires_at                   │ │
│  │  • Type: btree                                                │ │
│  │  • Purpose: Fast expiry queries                               │ │
│  │  • Used by: Scopes, background job                            │ │
│  └───────────────────────────────────────────────────────────────┘ │
│  ┌───────────────────────────────────────────────────────────────┐ │
│  │  index_calendars_on_public_token_revoked_at                   │ │
│  │  • Type: partial btree (WHERE revoked_at IS NOT NULL)        │ │
│  │  • Purpose: Efficient revoked token queries                   │ │
│  │  • Impact: Smaller index, faster queries                      │ │
│  └───────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│  QUERY OPTIMIZATION                                                  │
│  ┌───────────────────────────────────────────────────────────────┐ │
│  │  Model Scopes                                                 │ │
│  │  • Pre-optimized WHERE clauses                                │ │
│  │  • Leverage indexes automatically                             │ │
│  │  • Composable for complex queries                             │ │
│  └───────────────────────────────────────────────────────────────┘ │
│  ┌───────────────────────────────────────────────────────────────┐ │
│  │  Batch Processing                                             │ │
│  │  • Background job uses find_each (batches of 1000)           │ │
│  │  • Prevents memory bloat                                      │ │
│  │  • Efficient for large datasets                               │ │
│  └───────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│  CACHING OPPORTUNITIES (Future)                                      │
│  ┌───────────────────────────────────────────────────────────────┐ │
│  │  • Token stats caching (Redis)                                │ │
│  │  • Rate limit counter (Redis)                                 │ │
│  │  • Token validation result (short TTL)                        │ │
│  └───────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────┘
```

## Scalability Considerations

### Current Implementation (Good for < 100K calendars)
- Application-level rate limiting
- PostgreSQL-based usage counting
- Daily batch processing

### Future Scaling (> 100K calendars)
- **Redis**: Rate limiting, usage counters, caching
- **Sidekiq**: Distributed background job processing
- **CDN**: Cache public availability responses
- **Read Replicas**: Separate analytics queries
- **Partitioning**: Partition calendars table by created_at

## Monitoring Dashboard Metrics

```
┌─────────────────────────────────────────────────────────────────────┐
│  TOKEN HEALTH DASHBOARD                                             │
│                                                                      │
│  Active Tokens:      45,231  ████████████████████████  (89%)       │
│  Expired Tokens:      3,421  ███                       ( 7%)       │
│  Revoked Tokens:      1,892  ██                        ( 4%)       │
│  ──────────────────────────────────────────────────────────────     │
│  Total:             50,544                                          │
│                                                                      │
│  Expiring Soon (7d):   2,145  ⚠️  Warnings sent                    │
│  High Usage (>1000):     234  📊 Review for patterns               │
│                                                                      │
│  Avg Usage/Token:       127                                         │
│  Rate Limit Hits:        45  🚫 Last 24h                           │
│  Email Delivery:     99.2%  ✅  Last 30d                           │
└─────────────────────────────────────────────────────────────────────┘
```

## Integration Points

```
External Systems ─────┐
                      │
n8n Workflows ────────┤
                      │
Zapier Automations ───┼──► Public Token API
                      │
Mobile Apps ──────────┤
                      │
Web Embeds ───────────┘


Backend Admin ────────┐
                      │
User Dashboard ───────┼──► Token Management API
                      │
Support Tools ────────┘


Email Service ────────┐
                      │
SMTP Provider ────────┼──► PublicTokenMailer
                      │
Notification Queue ───┘


Monitoring ───────────┐
                      │
Analytics ────────────┼──► Token Stats API
                      │
Alerting ─────────────┘
```

This architecture provides a robust, scalable, and secure foundation for managing public calendar token expiration in Callab.

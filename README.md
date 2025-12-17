# Callab - AI-Powered Scheduling Assistant

An intelligent scheduling API that combines traditional calendar management with AI-powered assistance using Claude and RAG (Retrieval-Augmented Generation).

## Features

- **Authentication**: JWT-based authentication with Google OAuth support
- **Client Management**: Track clients with contact information
- **Calendar & Events**: Manage multiple calendars and appointments
- **Smart Notes**: Store preferences with semantic search using pgvector embeddings
- **AI Assistant**: Claude-powered assistant with tool calling capabilities
- **RAG Context**: Automatically retrieves relevant user preferences from notes
- **Tool Calling**: AI can autonomously check availability, find clients, and create events
- **Rate Limiting**: Built-in API rate limiting with Rack::Attack
- **Public Sharing**: Token-based public calendar access for external booking

## Tech Stack

- **Backend**: Ruby on Rails 7.2 (API mode)
- **Database**: PostgreSQL with pgvector extension
- **AI Chat**: Anthropic Claude Sonnet 4.5
- **Embeddings**: Ollama with nomic-embed-text (768 dimensions)
- **Vector Search**: pgvector with cosine similarity

## Quick Start

### Prerequisites

```bash
# Install Ollama
brew install ollama  # macOS
# or visit https://ollama.ai for other platforms

# Pull the embedding model
ollama pull nomic-embed-text

# Ensure Docker Desktop is running
```

### Setup

1. **Clone and configure:**
```bash
git clone <your-repo>
cd callab

# Create .env file from example
cp .env.example .env

# Edit .env with your credentials:
# - ANTHROPIC_API_KEY (required for AI features)
# - SECRET_KEY_BASE (required for JWT authentication)
# - GOOGLE_CLIENT_ID/SECRET (optional, for OAuth)
```

2. **Start services:**
```bash
docker compose up -d
```

3. **Setup database:**
```bash
docker compose run --rm app bin/rails db:create db:migrate db:seed
```

4. **Test the API:**
```bash
# Register a user
curl -X POST http://localhost:3000/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "user": {
      "name": "John Doe",
      "email": "john@example.com",
      "password": "securepassword123"
    }
  }'

# Login and get tokens
curl -X POST http://localhost:3000/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "user": {
      "email": "john@example.com",
      "password": "securepassword123"
    }
  }'

# Use the access token for authenticated requests
export TOKEN="your_access_token_here"

# Create a note with preferences
curl -X POST http://localhost:3000/notes \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"note":{"content":"I prefer morning meetings between 9-11am"}}'

# Ask the AI assistant
curl -X POST http://localhost:3000/ai/chat \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"query":"What are my meeting preferences?"}'
```

## Documentation

📚 **[Complete API Documentation](API_DOCUMENTATION.md)** - Full endpoint reference, examples, and AI features

🔐 **[Authentication Guide](AUTHENTICATION.md)** - JWT authentication, OAuth, security best practices

## API Overview

### Authentication Endpoints

- **POST** `/auth/register` - Register a new user
- **POST** `/auth/login` - Login and receive JWT tokens
- **POST** `/auth/logout` - Logout and revoke refresh token
- **POST** `/auth/refresh` - Refresh access token
- **POST** `/auth/forgot_password` - Request password reset
- **POST** `/auth/reset_password` - Reset password with token
- **GET** `/auth/me` - Get current user info
- **GET** `/auth/google_oauth2/callback` - Google OAuth callback

### Core Endpoints (Authenticated)

- **Clients**: `/clients` - Manage client contacts
- **Calendars**: `/calendars` - Manage user calendars
- **Events**: `/events` - Manage calendar events
- **Notes**: `/notes` - Store preferences with automatic embeddings
- **AI Chat**: `/ai/chat` - Intelligent assistant with tool calling

### Public Endpoints (No Auth Required)

- **GET** `/calendars/public/:token/availability` - Check public calendar availability
- **POST** `/calendars/public/:token/events` - Book event on public calendar

### AI Assistant Tools

The AI automatically uses these tools when needed:

1. **search_notes** - Semantic search through user preferences
2. **list_availability** - Check calendar availability
3. **find_or_create_client** - Find or create client records
4. **create_event** - Create calendar events

### Example AI Interactions

```bash
# The AI will search your notes for context
curl -X POST http://localhost:3000/ai/chat \
  -H "Content-Type: application/json" \
  -d '{"query":"When should I schedule my meeting with John?"}'

# The AI will check your calendar
curl -X POST http://localhost:3000/ai/chat \
  -H "Content-Type: application/json" \
  -d '{"query":"Am I available tomorrow morning?"}'

# The AI will find/create client and create event
curl -X POST http://localhost:3000/ai/chat \
  -H "Content-Type: application/json" \
  -d '{"query":"Schedule a meeting with Sarah tomorrow at 10am"}'
```

## Development

### Run tests
```bash
docker compose run --rm app bin/rails test
```

### Rails console
```bash
docker compose run --rm app bin/rails console
```

### View routes
```bash
docker compose run --rm app bin/rails routes
```

### Check logs
```bash
docker compose logs -f app
```

## Architecture

```
┌─────────────┐
│   Client    │
└──────┬──────┘
       │
       ▼
┌─────────────────────────────────────┐
│         Rails API                   │
│  ┌──────────────────────────────┐  │
│  │   Controllers                │  │
│  │  - Clients, Events, Notes    │  │
│  │  - AI Chat                   │  │
│  └──────────┬───────────────────┘  │
│             │                       │
│  ┌──────────▼───────────────────┐  │
│  │   AI Assistant               │  │
│  │  - RAG Context Retrieval     │  │
│  │  - Tool Calling Loop         │  │
│  └──────────┬───────────────────┘  │
│             │                       │
│  ┌──────────▼───────────────────┐  │
│  │   Services                   │  │
│  │  - EmbeddingService          │  │
│  │  - AI Tools                  │  │
│  └──────────┬───────────────────┘  │
└─────────────┼───────────────────────┘
              │
     ┌────────┴─────────┐
     ▼                  ▼
┌──────────┐      ┌──────────┐
│PostgreSQL│      │  Ollama  │
│+ pgvector│      │  + API   │
└──────────┘      └──────────┘
     ▲                  ▲
     │                  │
  Stores            Generates
  - Clients         Embeddings
  - Events          (768-dim)
  - Notes
  - Embeddings
```

## How RAG Works

1. User creates notes: "I prefer morning meetings"
2. Ollama generates 768-dimensional embedding vector
3. Vector stored in PostgreSQL with pgvector
4. When user asks AI a question:
   - Query is converted to embedding
   - Semantic search finds similar notes
   - Relevant notes injected as context
   - Claude responds with awareness of preferences

## Environment Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `SECRET_KEY_BASE` | Secret key for JWT signing | - | ✅ Yes |
| `ANTHROPIC_API_KEY` | Claude API key | - | ✅ Yes |
| `OLLAMA_HOST` | Ollama server URL | `http://host.docker.internal:11434` | ✅ Yes |
| `GOOGLE_CLIENT_ID` | Google OAuth client ID | - | OAuth only |
| `GOOGLE_CLIENT_SECRET` | Google OAuth secret | - | OAuth only |
| `FRONTEND_URL` | Frontend URL for OAuth redirects | `http://localhost:3001` | OAuth only |
| `DATABASE_HOST` | PostgreSQL host | `db` | No |
| `DATABASE_USERNAME` | PostgreSQL user | `postgres` | No |
| `DATABASE_PASSWORD` | PostgreSQL password | `password` | No |
| `TWILIO_ACCOUNT_SID` | Twilio account SID | - | SMS only |
| `TWILIO_AUTH_TOKEN` | Twilio auth token | - | SMS only |
| `TWILIO_PHONE_NUMBER` | Twilio phone number | - | SMS only |

Generate a secure `SECRET_KEY_BASE`:
```bash
openssl rand -hex 64
```

## Authentication

### JWT Authentication

This API uses JWT (JSON Web Tokens) for authentication. After registration or login, you'll receive:

- **Access Token**: Short-lived (15 minutes), used for API requests
- **Refresh Token**: Long-lived (7 days), used to get new access tokens

#### Authentication Flow

1. **Register** or **Login** to receive tokens
2. Include access token in requests: `Authorization: Bearer YOUR_ACCESS_TOKEN`
3. When access token expires, use refresh token to get a new one
4. On logout, refresh token is revoked

#### Rate Limiting

The API implements rate limiting to prevent abuse:

- **General requests**: 60 requests/minute per IP
- **Login attempts**: 5 attempts per 20 minutes per email
- **Registration**: 3 attempts per hour per IP
- **Password reset**: 3 requests per hour per email
- **Public calendar**: 30 requests/minute per IP
- **AI chat**: 10 requests/minute per IP

### Google OAuth

To enable Google OAuth login:

1. Create a project in [Google Cloud Console](https://console.cloud.google.com/)
2. Enable Google+ API
3. Create OAuth 2.0 credentials
4. Set authorized redirect URI: `http://your-domain/auth/google_oauth2/callback`
5. Add `GOOGLE_CLIENT_ID` and `GOOGLE_CLIENT_SECRET` to `.env`

Users can then authenticate via: `GET /auth/google_oauth2`

## Production Considerations

Before deploying to production:

- [ ] Configure CORS for frontend apps
- [ ] Add monitoring and error tracking
- [ ] Move embedding generation to background jobs
- [ ] Add API versioning (/api/v1)
- [ ] Implement pagination for list endpoints
- [ ] Add database query optimization
- [ ] Set up CI/CD pipeline
- [ ] Configure environment-specific settings
- [ ] Set up email service for password resets
- [ ] Add SSL/TLS certificates
- [ ] Configure secure session management

## License
<!-- TDOD  -->
-- [Add your license]

## Contributing
<!-- TDOD  -->
[Add contribution guidelines]

## Support

For issues and questions, please open an issue on GitHub.

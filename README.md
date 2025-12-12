# Callab - AI-Powered Scheduling Assistant

An intelligent scheduling API that combines traditional calendar management with AI-powered assistance using Claude and RAG (Retrieval-Augmented Generation).

## Features

- **Client Management**: Track clients with contact information
- **Calendar & Events**: Manage multiple calendars and appointments
- **Smart Notes**: Store preferences with semantic search using pgvector embeddings
- **AI Assistant**: Claude-powered assistant with tool calling capabilities
- **RAG Context**: Automatically retrieves relevant user preferences from notes
- **Tool Calling**: AI can autonomously check availability, find clients, and create events

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

# Create .env file
echo "ANTHROPIC_API_KEY=your_api_key_here" > .env
echo "OLLAMA_HOST=http://host.docker.internal:11434" >> .env
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
# Create a note with preferences
curl -X POST http://localhost:3000/notes \
  -H "Content-Type: application/json" \
  -d '{"note":{"content":"I prefer morning meetings between 9-11am"}}'

# Ask the AI assistant
curl -X POST http://localhost:3000/ai/chat \
  -H "Content-Type: application/json" \
  -d '{"query":"What are my meeting preferences?"}'
```

## Documentation

📚 **[Complete API Documentation](API_DOCUMENTATION.md)** - Full endpoint reference, examples, and AI features

## API Overview

### Core Endpoints

- **Clients**: `/clients` - Manage client contacts
- **Calendars**: `/calendars` - Manage user calendars
- **Events**: `/events` - Manage calendar events
- **Notes**: `/notes` - Store preferences with automatic embeddings
- **AI Chat**: `/ai/chat` - Intelligent assistant with tool calling

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

| Variable | Description | Default |
|----------|-------------|---------|
| `ANTHROPIC_API_KEY` | Claude API key | Required |
| `OLLAMA_HOST` | Ollama server URL | `http://host.docker.internal:11434` |
| `DATABASE_HOST` | PostgreSQL host | `db` |
| `DATABASE_USERNAME` | PostgreSQL user | `postgres` |
| `DATABASE_PASSWORD` | PostgreSQL password | `password` |

## Production Considerations

Before deploying to production:

- [ ] Add proper authentication (JWT, OAuth)
- [ ] Implement API rate limiting
- [ ] Configure CORS for frontend apps
- [ ] Add monitoring and error tracking
- [ ] Move embedding generation to background jobs
- [ ] Add API versioning (/api/v1)
- [ ] Implement pagination for list endpoints
- [ ] Add database query optimization
- [ ] Set up CI/CD pipeline
- [ ] Configure environment-specific settings

## License

[Add your license]

## Contributing

[Add contribution guidelines]

## Support

For issues and questions, please open an issue on GitHub.

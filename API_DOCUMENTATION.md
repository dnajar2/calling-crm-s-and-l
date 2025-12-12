# Callab API Documentation

Callab is an AI-powered scheduling assistant API that helps manage clients, calendars, events, and notes with intelligent context-aware responses.

## Table of Contents

- [Overview](#overview)
- [Setup](#setup)
- [Authentication](#authentication)
- [Endpoints](#endpoints)
  - [Clients](#clients)
  - [Calendars](#calendars)
  - [Events](#events)
  - [Notes](#notes)
  - [AI Assistant](#ai-assistant)
- [AI Features](#ai-features)
- [Error Handling](#error-handling)

## Overview

Callab combines traditional calendar management with AI capabilities:

- **Client Management**: Track clients with contact information
- **Calendar & Events**: Manage multiple calendars and appointments
- **Notes with RAG**: Store preferences with semantic search using pgvector embeddings
- **AI Assistant**: Claude-powered assistant with tool calling for intelligent scheduling

**Tech Stack:**
- Ruby on Rails 7.2 (API mode)
- PostgreSQL with pgvector extension
- Anthropic Claude Sonnet 4.5 (chat)
- Ollama with nomic-embed-text (embeddings)

## Setup

### Prerequisites

```bash
# Required services
- Docker & Docker Compose
- Ollama running locally (for embeddings)
```

### Environment Variables

Create a `.env` file:

```env
ANTHROPIC_API_KEY=your_anthropic_api_key
OLLAMA_HOST=http://host.docker.internal:11434
```

### Installation

```bash
# Pull Ollama embedding model
ollama pull nomic-embed-text

# Start services
docker compose up -d

# Setup database
docker compose run --rm app bin/rails db:create db:migrate db:seed
```

## Authentication

Currently uses a simple `current_user` helper that returns `User.first`. This is suitable for single-user development but should be replaced with proper authentication (JWT, OAuth, etc.) in production.

All endpoints require a user to be present in the database.

## Endpoints

### Clients

Manage client contacts.

#### List All Clients

```http
GET /clients
```

**Response:**
```json
[
  {
    "id": 1,
    "name": "John Wick",
    "email": "john@example.com",
    "phone": "555-1212",
    "created_at": "2025-12-11T00:00:00.000Z",
    "updated_at": "2025-12-11T00:00:00.000Z"
  }
]
```

#### Get Client

```http
GET /clients/:id
```

**Response:**
```json
{
  "id": 1,
  "name": "John Wick",
  "email": "john@example.com",
  "phone": "555-1212",
  "created_at": "2025-12-11T00:00:00.000Z",
  "updated_at": "2025-12-11T00:00:00.000Z"
}
```

#### Create Client

```http
POST /clients
Content-Type: application/json

{
  "client": {
    "name": "John Wick",
    "email": "john@example.com",
    "phone": "555-1212"
  }
}
```

**Response:**
```json
{
  "id": 1,
  "name": "John Wick",
  "email": "john@example.com",
  "phone": "555-1212",
  "created_at": "2025-12-11T00:00:00.000Z",
  "updated_at": "2025-12-11T00:00:00.000Z"
}
```

**Status Codes:**
- `201 Created`: Client created successfully
- `422 Unprocessable Entity`: Validation errors

#### Update Client

```http
PATCH /clients/:id
Content-Type: application/json

{
  "client": {
    "phone": "555-9999"
  }
}
```

**Response:**
```json
{
  "id": 1,
  "name": "John Wick",
  "email": "john@example.com",
  "phone": "555-9999",
  "created_at": "2025-12-11T00:00:00.000Z",
  "updated_at": "2025-12-11T01:00:00.000Z"
}
```

#### Delete Client

```http
DELETE /clients/:id
```

**Response:**
- `204 No Content`: Client deleted successfully

---

### Calendars

Manage user calendars.

#### List Calendars

```http
GET /calendars
```

**Response:**
```json
[
  {
    "id": 1,
    "name": "Work Calendar",
    "timezone": "America/New_York",
    "user_id": 1,
    "created_at": "2025-12-11T00:00:00.000Z",
    "updated_at": "2025-12-11T00:00:00.000Z"
  }
]
```

#### Get Calendar

```http
GET /calendars/:id
```

#### Create Calendar

```http
POST /calendars
Content-Type: application/json

{
  "calendar": {
    "name": "Work Calendar",
    "timezone": "America/New_York"
  }
}
```

#### Update Calendar

```http
PATCH /calendars/:id
Content-Type: application/json

{
  "calendar": {
    "name": "Personal Calendar"
  }
}
```

#### Delete Calendar

```http
DELETE /calendars/:id
```

**Response:**
- `204 No Content`

---

### Events

Manage calendar events and appointments.

#### List Calendar Events

```http
GET /calendars/:calendar_id/events
```

**Response:**
```json
[
  {
    "id": 1,
    "calendar_id": 1,
    "client_id": 1,
    "title": "Client Meeting",
    "description": "Discuss project requirements",
    "start_time": "2025-12-11T10:00:00.000Z",
    "end_time": "2025-12-11T11:00:00.000Z",
    "created_at": "2025-12-11T00:00:00.000Z",
    "updated_at": "2025-12-11T00:00:00.000Z"
  }
]
```

#### Get Event

```http
GET /events/:id
```

**Response:**
```json
{
  "id": 1,
  "calendar_id": 1,
  "client_id": 1,
  "title": "Client Meeting",
  "description": "Discuss project requirements",
  "start_time": "2025-12-11T10:00:00.000Z",
  "end_time": "2025-12-11T11:00:00.000Z",
  "created_at": "2025-12-11T00:00:00.000Z",
  "updated_at": "2025-12-11T00:00:00.000Z"
}
```

#### Create Event

```http
POST /calendars/:calendar_id/events
Content-Type: application/json

{
  "event": {
    "client_id": 1,
    "title": "Client Meeting",
    "description": "Discuss project requirements",
    "start_time": "2025-12-11T10:00:00Z",
    "end_time": "2025-12-11T11:00:00Z"
  }
}
```

**Response:**
```json
{
  "id": 1,
  "calendar_id": 1,
  "client_id": 1,
  "title": "Client Meeting",
  "description": "Discuss project requirements",
  "start_time": "2025-12-11T10:00:00.000Z",
  "end_time": "2025-12-11T11:00:00.000Z",
  "created_at": "2025-12-11T00:00:00.000Z",
  "updated_at": "2025-12-11T00:00:00.000Z"
}
```

**Status Codes:**
- `201 Created`: Event created successfully
- `422 Unprocessable Entity`: Validation errors

#### Update Event

```http
PATCH /events/:id
Content-Type: application/json

{
  "event": {
    "title": "Updated Meeting Title"
  }
}
```

#### Delete Event

```http
DELETE /events/:id
```

**Response:**
- `204 No Content`

---

### Notes

Store and search notes with semantic embeddings for AI context.

#### List Notes

```http
GET /notes
```

**Response:**
```json
[
  {
    "id": 1,
    "user_id": 1,
    "content": "I prefer morning meetings between 9-11am on weekdays",
    "embedding": [0.665, 0.269, -4.426, ...],  // 768-dimensional vector
    "created_at": "2025-12-11T00:00:00.000Z",
    "updated_at": "2025-12-11T00:00:00.000Z"
  }
]
```

#### Get Note

```http
GET /notes/:id
```

#### Create Note

```http
POST /notes
Content-Type: application/json

{
  "note": {
    "content": "I prefer morning meetings between 9-11am on weekdays"
  }
}
```

**Response:**
```json
{
  "id": 1,
  "user_id": 1,
  "content": "I prefer morning meetings between 9-11am on weekdays",
  "embedding": [0.665, 0.269, -4.426, ...],
  "created_at": "2025-12-11T00:00:00.000Z",
  "updated_at": "2025-12-11T00:00:00.000Z"
}
```

**Note:** Embeddings are automatically generated using Ollama's nomic-embed-text model when the note is created or updated.

#### Update Note

```http
PATCH /notes/:id
Content-Type: application/json

{
  "note": {
    "content": "Updated preference text"
  }
}
```

**Note:** Updating the content will regenerate the embedding.

#### Delete Note

```http
DELETE /notes/:id
```

**Response:**
- `204 No Content`

#### Search Notes (Semantic Search)

```http
GET /notes/search?query=meeting%20preferences
```

**Parameters:**
- `query` (required): Search query text

**Response:**
```json
{
  "query": "meeting preferences",
  "results": [
    {
      "id": 1,
      "user_id": 1,
      "content": "I prefer morning meetings between 9-11am on weekdays",
      "embedding": [0.665, 0.269, ...],
      "created_at": "2025-12-11T00:00:00.000Z",
      "updated_at": "2025-12-11T00:00:00.000Z",
      "neighbor_distance": 0.23  // Cosine distance (lower = more similar)
    }
  ]
}
```

**Note:** Uses pgvector's cosine similarity to find semantically similar notes.

---

### AI Assistant

Intelligent scheduling assistant powered by Claude with tool calling and RAG.

#### Chat with AI Assistant

```http
POST /ai/chat
Content-Type: application/json

{
  "query": "What are my meeting preferences?"
}
```

**Response:**
```json
{
  "output": "Based on your notes, you prefer morning meetings between 9-11am on weekdays. You also want to avoid booking meetings after 3pm unless they are urgent."
}
```

**Example Queries:**

1. **Ask about preferences:**
```json
{
  "query": "What are my meeting preferences?"
}
```

2. **Check availability:**
```json
{
  "query": "Am I available tomorrow morning?"
}
```

3. **Create events:**
```json
{
  "query": "Schedule a meeting with John Wick tomorrow at 10am"
}
```

4. **Find or create clients:**
```json
{
  "query": "Do I have a client named Sarah in my system?"
}
```

**How It Works:**

The AI assistant automatically:
1. **Searches notes** for relevant context using semantic search
2. **Calls tools** as needed:
   - `search_notes`: Find relevant user preferences
   - `list_availability`: Check calendar availability
   - `find_or_create_client`: Find or create client records
   - `create_event`: Create calendar events
3. **Responds intelligently** based on context and tool results

**Example Flow:**

```
User: "Schedule a meeting with John tomorrow at 10am"

AI Process:
1. Searches notes for preferences about scheduling
2. Calls find_or_create_client("John")
3. Calls list_availability("2025-12-12")
4. Calls create_event(...) if time is available
5. Responds with confirmation
```

---

## AI Features

### Tool Calling

The AI assistant has access to the following tools:

#### 1. search_notes
Searches through user notes using semantic search.

**Input:**
```json
{
  "query": "meeting preferences",
  "limit": 5  // optional, default: 5
}
```

**Output:**
```json
{
  "query": "meeting preferences",
  "results_count": 2,
  "notes": [...],
  "message": "Found 2 relevant note(s)"
}
```

#### 2. list_availability
Lists available time slots for scheduling.

**Input:**
```json
{
  "start_date": "2025-12-11",
  "end_date": "2025-12-11",  // optional
  "calendar_id": 1  // optional
}
```

**Output:**
```json
{
  "calendar_name": "Work Calendar",
  "date_range": "2025-12-11 to 2025-12-11",
  "busy_slots": [
    {
      "start": "2025-12-11T10:00:00Z",
      "end": "2025-12-11T11:00:00Z",
      "title": "Client Meeting"
    }
  ],
  "message": "1 event(s) scheduled"
}
```

#### 3. find_or_create_client
Finds an existing client or creates a new one.

**Input:**
```json
{
  "name": "John Wick",
  "email": "john@example.com",  // optional
  "phone": "555-1212"  // optional
}
```

**Output:**
```json
{
  "found": true,
  "client": {
    "id": 1,
    "name": "John Wick",
    "email": "john@example.com",
    "phone": "555-1212"
  },
  "message": "Found existing client"
}
```

#### 4. create_event
Creates a new calendar event.

**Input:**
```json
{
  "client_id": 1,
  "title": "Client Meeting",
  "description": "Discuss project",  // optional
  "start_time": "2025-12-11T10:00:00Z",
  "end_time": "2025-12-11T11:00:00Z",
  "calendar_id": 1  // optional
}
```

**Output:**
```json
{
  "success": true,
  "event": {
    "id": 1,
    "title": "Client Meeting",
    "client": "John Wick",
    "start_time": "2025-12-11T10:00:00Z",
    "end_time": "2025-12-11T11:00:00Z"
  },
  "message": "Event created successfully"
}
```

### RAG (Retrieval-Augmented Generation)

The AI assistant uses RAG to provide context-aware responses:

1. **Automatic Context Retrieval**: Before responding, the AI searches your notes for relevant context
2. **Semantic Search**: Uses pgvector cosine similarity to find the most relevant notes
3. **Context Injection**: Relevant notes are injected into the AI's system prompt
4. **Preference-Aware**: Remembers preferences like "avoid meetings after 3pm"

**Example:**

```
User creates notes:
- "I prefer morning meetings between 9-11am"
- "Avoid booking after 3pm unless urgent"

User asks: "When should I schedule my meeting with John?"

AI responds: "Based on your preferences for morning meetings between 9-11am,
I recommend scheduling between those hours. I'll avoid times after 3pm as you've
indicated those should only be used for urgent matters."
```

---

## Error Handling

### Standard Error Response

```json
{
  "status": 500,
  "error": "Internal Server Error",
  "exception": "#<SomeError: error message>",
  "traces": {
    "Application Trace": [...],
    "Framework Trace": [...],
    "Full Trace": [...]
  }
}
```

### Common Status Codes

- `200 OK`: Request successful
- `201 Created`: Resource created successfully
- `204 No Content`: Resource deleted successfully
- `404 Not Found`: Resource not found
- `422 Unprocessable Entity`: Validation errors
- `500 Internal Server Error`: Server error

### Validation Errors

```json
{
  "errors": [
    "Name can't be blank",
    "Email is invalid"
  ]
}
```

---

## Development

### Running Tests

```bash
docker compose run --rm app bin/rails test
```

### Checking Routes

```bash
docker compose run --rm app bin/rails routes
```

### Database Console

```bash
docker compose run --rm app bin/rails dbconsole
```

### Rails Console

```bash
docker compose run --rm app bin/rails console
```

---

## Architecture

### Database Schema

**Users**
- `id`, `name`, `email`

**Clients**
- `id`, `user_id`, `name`, `email`, `phone`

**Calendars**
- `id`, `user_id`, `name`, `timezone`

**Events**
- `id`, `calendar_id`, `client_id`, `title`, `description`, `start_time`, `end_time`

**Notes**
- `id`, `user_id`, `content`, `embedding` (vector[768])

### Services

**EmbeddingService**
- Generates 768-dimensional vectors using Ollama's nomic-embed-text model

**Ai::AiAssistant**
- Main AI orchestrator
- Handles tool calling loop
- Manages RAG context retrieval

**Ai::Tools::**
- `BaseTool`: Abstract base class for tools
- `SearchNotes`: Semantic search through notes
- `ListAvailability`: Check calendar availability
- `FindOrCreateClient`: Client lookup/creation
- `CreateEvent`: Event creation

---

## Production Considerations

Before deploying to production, consider:

1. **Authentication**: Replace `current_user` with proper auth (JWT, Devise, etc.)
2. **API Rate Limiting**: Add rate limiting to prevent abuse
3. **CORS**: Configure CORS for frontend applications
4. **Environment Variables**: Secure API keys and credentials
5. **Monitoring**: Add logging and error tracking (Sentry, etc.)
6. **Caching**: Add Redis caching for embeddings and responses
7. **Background Jobs**: Move embedding generation to background jobs (Sidekiq)
8. **API Versioning**: Version your API (e.g., `/api/v1/clients`)
9. **Pagination**: Add pagination to list endpoints
10. **Database Indexes**: Optimize queries with proper indexes

---

## License

[Add your license here]

## Support

[Add support contact information]

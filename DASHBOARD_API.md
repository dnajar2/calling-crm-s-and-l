# Dashboard API Documentation

API endpoints to support the dashboard frontend with statistics, today's schedule, upcoming events, and recent clients.

## Endpoints Overview

- `GET /events/dashboard` - Dashboard statistics
- `GET /events/today` - Today's events in schedule format
- `GET /events/upcoming` - Upcoming future events
- `GET /clients/recent` - Recently updated clients

## 1. Dashboard Statistics

**GET /events/dashboard**

Returns event counts and statistics for dashboard cards.

**Response:**
```json
{
  "today_events": 3,
  "this_week_events": 4,
  "total_clients": 6,
  "growth_percentage": 12
}
```

## 2. Today's Schedule

**GET /events/today**

Returns all events scheduled for today in chronological order.

**Response:**
```json
{
  "date": "Friday, January 09, 2026",
  "timezone": "Pacific Time (US & Canada)",
  "events": [
    {
      "id": 1,
      "title": "Client Meeting - Q4 Review",
      "client_name": "John Smith",
      "start_time_formatted": "10:00 AM",
      "end_time_formatted": "11:00 AM",
      "time_range": "10:00 AM - 11:00 AM"
    }
  ]
}
```

## 3. Upcoming Events

**GET /events/upcoming**

Returns upcoming events (max 10) with relative date labels.

**Response:**
```json
{
  "timezone": "Pacific Time (US & Canada)",
  "events": [
    {
      "id": 3,
      "title": "Team Standup",
      "client_name": "John Smith",
      "date_label": "Jan",
      "day_label": "10",
      "relative_label": "Tomorrow",
      "full_date_time": "Tomorrow • 09:00 AM"
    }
  ]
}
```

## 4. Recent Clients

**GET /clients/recent**

Returns 6 most recently updated clients.

**Response:**
```json
[
  {
    "id": 1,
    "name": "John Smith",
    "email": "john.smith@example.com",
    "phone": "+19168004763",
    "initial": "J"
  }
]
```

## Frontend Integration

All endpoints respect user timezone and return times in the user's configured timezone.

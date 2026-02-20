# Calendar Business Rules Documentation

## Overview

Callab now includes comprehensive business rules for calendar scheduling, allowing fine-grained control over availability, appointment scheduling, and time management.

## Features

### 1. Working Hours Configuration

Define custom working hours for each day of the week with support for multiple time ranges per day.

**Default Settings:**
- Monday-Friday: 9:00 AM - 5:00 PM
- Saturday-Sunday: Disabled

**Structure:**
```json
{
  "working_hours": {
    "monday": {
      "enabled": true,
      "ranges": [
        { "start": "09:00", "end": "12:00" },
        { "start": "13:00", "end": "17:00" }
      ]
    },
    "tuesday": {
      "enabled": true,
      "ranges": [{ "start": "09:00", "end": "17:00" }]
    },
    "wednesday": { "enabled": true, "ranges": [...] },
    "thursday": { "enabled": true, "ranges": [...] },
    "friday": { "enabled": true, "ranges": [...] },
    "saturday": { "enabled": false, "ranges": [] },
    "sunday": { "enabled": false, "ranges": [] }
  }
}
```

### 2. Appointment Duration

Configure the length of appointment slots.

**Valid Values:** 15, 30, 45, 60, 90, 120 minutes
**Default:** 30 minutes

### 3. Buffer Time

Add buffer time between appointments to prevent back-to-back scheduling.

**Valid Range:** 0-120 minutes
**Default:** 0 minutes (no buffer)

**Example:** With 15-minute buffer:
- Event 1: 10:00 AM - 10:30 AM
- Buffer: 10:30 AM - 10:45 AM (unavailable)
- Event 2: 10:45 AM - 11:15 AM (earliest next slot)

### 4. Advance Booking Windows

Control how far in advance appointments can be booked.

**Minimum Advance Notice:**
- Prevents last-minute bookings
- Default: 0 hours (immediate booking allowed)
- Example: 24 hours = must book at least 1 day ahead

**Maximum Advance Booking:**
- Limits how far into the future bookings can be made
- Valid Range: 1-365 days
- Default: 60 days

### 5. Blockout Dates

Block specific dates or date ranges from availability.

**Features:**
- Single date blockouts
- Date range blockouts
- Recurring blockouts (weekly or monthly)
- Optional reason/notes

**Types:**
- **One-time:** Blocks specific date range
- **Weekly:** Blocks same day of week (e.g., every Monday)
- **Monthly:** Blocks same day of month (e.g., 15th of every month)

---

## API Endpoints

### Calendar Settings

#### Update Calendar Settings

```http
PATCH /calendars/:id
Content-Type: application/json

{
  "calendar": {
    "name": "Work Calendar",
    "slot_duration_minutes": 45,
    "buffer_minutes": 15,
    "min_advance_hours": 24,
    "max_advance_days": 90,
    "working_hours": {
      "monday": {
        "enabled": true,
        "ranges": [
          { "start": "09:00", "end": "12:00" },
          { "start": "13:00", "end": "17:00" }
        ]
      },
      "tuesday": {
        "enabled": true,
        "ranges": [{ "start": "09:00", "end": "17:00" }]
      },
      "wednesday": {
        "enabled": true,
        "ranges": [{ "start": "09:00", "end": "17:00" }]
      },
      "thursday": {
        "enabled": true,
        "ranges": [{ "start": "09:00", "end": "17:00" }]
      },
      "friday": {
        "enabled": true,
        "ranges": [{ "start": "09:00", "end": "17:00" }]
      },
      "saturday": { "enabled": false, "ranges": [] },
      "sunday": { "enabled": false, "ranges": [] }
    }
  }
}
```

**Response:**
```json
{
  "id": 1,
  "name": "Work Calendar",
  "timezone": "Pacific Time (US & Canada)",
  "is_primary": true,
  "slot_duration_minutes": 45,
  "buffer_minutes": 15,
  "min_advance_hours": 24,
  "max_advance_days": 90,
  "working_hours": { ... },
  "created_at": "2026-01-08T00:00:00.000Z",
  "updated_at": "2026-01-08T12:00:00.000Z"
}
```

---

### Blockout Dates

#### List Blockouts

```http
GET /calendars/:calendar_id/blockouts
```

**Response:**
```json
[
  {
    "id": 1,
    "calendar_id": 1,
    "start_date": "2026-01-15",
    "end_date": "2026-01-15",
    "reason": "Holiday",
    "recurring": null,
    "created_at": "2026-01-08T00:00:00.000Z",
    "updated_at": "2026-01-08T00:00:00.000Z"
  },
  {
    "id": 2,
    "calendar_id": 1,
    "start_date": "2026-01-20",
    "end_date": "2026-01-27",
    "reason": "Vacation",
    "recurring": null,
    "created_at": "2026-01-08T00:00:00.000Z",
    "updated_at": "2026-01-08T00:00:00.000Z"
  },
  {
    "id": 3,
    "calendar_id": 1,
    "start_date": "2026-01-06",
    "end_date": "2026-12-31",
    "reason": "No Mondays",
    "recurring": "weekly",
    "created_at": "2026-01-08T00:00:00.000Z",
    "updated_at": "2026-01-08T00:00:00.000Z"
  }
]
```

#### Create Blockout

```http
POST /calendars/:calendar_id/blockouts
Content-Type: application/json

{
  "blockout": {
    "start_date": "2026-02-14",
    "end_date": "2026-02-14",
    "reason": "Valentine's Day - Office Closed",
    "recurring": null
  }
}
```

**Recurring Weekly Example:**
```json
{
  "blockout": {
    "start_date": "2026-01-06",
    "end_date": "2026-12-31",
    "reason": "No appointments on Mondays",
    "recurring": "weekly"
  }
}
```

**Recurring Monthly Example:**
```json
{
  "blockout": {
    "start_date": "2026-01-15",
    "end_date": "2026-12-31",
    "reason": "Monthly team meeting on 15th",
    "recurring": "monthly"
  }
}
```

**Response:**
```json
{
  "id": 4,
  "calendar_id": 1,
  "start_date": "2026-02-14",
  "end_date": "2026-02-14",
  "reason": "Valentine's Day - Office Closed",
  "recurring": null,
  "created_at": "2026-01-08T12:00:00.000Z",
  "updated_at": "2026-01-08T12:00:00.000Z"
}
```

#### Get Blockout

```http
GET /calendars/:calendar_id/blockouts/:id
```

#### Update Blockout

```http
PATCH /calendars/:calendar_id/blockouts/:id
Content-Type: application/json

{
  "blockout": {
    "reason": "Updated reason",
    "end_date": "2026-02-15"
  }
}
```

#### Delete Blockout

```http
DELETE /calendars/:calendar_id/blockouts/:id
```

**Response:** `204 No Content`

---

## Availability Calculation

The `/calendars/:id/availability?date=YYYY-MM-DD` and `/calendars/public/:token/availability?date=YYYY-MM-DD` endpoints now respect all business rules:

### Rules Applied (in order):

1. **Date Validation**
   - Check if date is blocked by any blockout
   - Check if date is within min/max advance booking window

2. **Day of Week Check**
   - Verify the day is enabled in working_hours
   - Get configured time ranges for that day

3. **Time Slot Generation**
   - Generate slots based on `slot_duration_minutes`
   - Only within configured working hours ranges

4. **Conflict Detection**
   - Check for existing events
   - Apply `buffer_minutes` before and after existing events
   - Remove overlapping slots

5. **Past Time Filtering**
   - Remove slots that have already passed
   - Respect user's timezone

### Example Request

```http
GET /calendars/public/abc123.../availability?date=2026-01-15
```

**Response:**
```json
{
  "calendar_name": "Work Calendar",
  "date": "2026-01-15",
  "timezone": "Pacific Time (US & Canada)",
  "settings": {
    "slot_duration_minutes": 30,
    "buffer_minutes": 15
  },
  "available_slots": [
    "2026-01-15T09:00:00-08:00",
    "2026-01-15T09:30:00-08:00",
    "2026-01-15T10:00:00-08:00",
    "2026-01-15T14:00:00-08:00",
    "2026-01-15T14:30:00-08:00",
    "2026-01-15T15:00:00-08:00"
  ]
}
```

**Empty Response (Blocked Date):**
```json
{
  "calendar_name": "Work Calendar",
  "date": "2026-01-20",
  "timezone": "Pacific Time (US & Canada)",
  "available_slots": [],
  "message": "Date is blocked or outside booking window"
}
```

---

## Validation Rules

### Working Hours
- Must include all 7 days of the week
- Each day must have `enabled` (boolean) and `ranges` (array)
- Each range must have `start` and `end` in "HH:MM" format
- Times must be valid 24-hour format

### Slot Duration
- Must be one of: 15, 30, 45, 60, 90, 120 minutes

### Buffer Minutes
- Must be between 0 and 120 minutes

### Advance Booking
- `min_advance_hours`: Must be >= 0
- `max_advance_days`: Must be between 1 and 365 days

### Blockouts
- `start_date` and `end_date` are required
- `end_date` must be >= `start_date`
- `recurring` must be null, "weekly", or "monthly"

---

## Use Cases

### 1. Standard Business Hours
```json
{
  "slot_duration_minutes": 30,
  "buffer_minutes": 0,
  "min_advance_hours": 0,
  "max_advance_days": 60,
  "working_hours": {
    "monday": { "enabled": true, "ranges": [{"start": "09:00", "end": "17:00"}] },
    "tuesday": { "enabled": true, "ranges": [{"start": "09:00", "end": "17:00"}] },
    "wednesday": { "enabled": true, "ranges": [{"start": "09:00", "end": "17:00"}] },
    "thursday": { "enabled": true, "ranges": [{"start": "09:00", "end": "17:00"}] },
    "friday": { "enabled": true, "ranges": [{"start": "09:00", "end": "17:00"}] },
    "saturday": { "enabled": false, "ranges": [] },
    "sunday": { "enabled": false, "ranges": [] }
  }
}
```

### 2. Lunch Break Schedule
```json
{
  "working_hours": {
    "monday": {
      "enabled": true,
      "ranges": [
        {"start": "09:00", "end": "12:00"},
        {"start": "13:00", "end": "17:00"}
      ]
    }
  }
}
```

### 3. Weekend Availability
```json
{
  "working_hours": {
    "saturday": {
      "enabled": true,
      "ranges": [{"start": "10:00", "end": "14:00"}]
    },
    "sunday": {
      "enabled": true,
      "ranges": [{"start": "10:00", "end": "14:00"}]
    }
  }
}
```

### 4. Require 24-Hour Notice
```json
{
  "min_advance_hours": 24,
  "max_advance_days": 30
}
```

### 5. Buffer Time Between Appointments
```json
{
  "slot_duration_minutes": 60,
  "buffer_minutes": 15
}
```
This creates 60-minute appointments with 15-minute breaks between them.

### 6. Block Vacation Period
```http
POST /calendars/1/blockouts
{
  "blockout": {
    "start_date": "2026-07-01",
    "end_date": "2026-07-14",
    "reason": "Summer Vacation"
  }
}
```

### 7. Block Every Friday
```http
POST /calendars/1/blockouts
{
  "blockout": {
    "start_date": "2026-01-02",
    "end_date": "2026-12-31",
    "reason": "No Friday appointments",
    "recurring": "weekly"
  }
}
```

---

## Migration Notes

All existing calendars have been automatically configured with default business rules:
- **Working Hours:** Monday-Friday, 9 AM - 5 PM
- **Slot Duration:** 30 minutes
- **Buffer Time:** 0 minutes
- **Min Advance:** 0 hours (immediate booking)
- **Max Advance:** 60 days

You can update these settings via the API to match your specific needs.

---

## Best Practices

1. **Set Realistic Buffer Times**
   - Allow time for preparation and notes between appointments
   - Recommended: 10-15 minutes for most use cases

2. **Use Minimum Advance Notice**
   - Prevents last-minute bookings
   - Gives you time to prepare
   - Recommended: 2-24 hours depending on service type

3. **Limit Maximum Advance Booking**
   - Prevents booking too far into uncertain future
   - Recommended: 30-90 days

4. **Leverage Recurring Blockouts**
   - Block regular team meetings
   - Block days you never work
   - More efficient than creating individual blockouts

5. **Multiple Time Ranges**
   - Use for lunch breaks
   - Use for split shifts
   - Provides flexibility while maintaining boundaries

---

## Timezone Handling

All business rules respect the user's configured timezone:
- Working hours are interpreted in user's timezone
- Availability slots are returned in user's timezone
- Blockout dates are timezone-aware
- Event times are stored in UTC but displayed in user's timezone

**Example:**
- User timezone: `Pacific Time (US & Canada)`
- Working hours: 9:00 AM - 5:00 PM
- Availability returned: `2026-01-15T09:00:00-08:00` (PST)
- Stored in database: `2026-01-15T17:00:00Z` (UTC)

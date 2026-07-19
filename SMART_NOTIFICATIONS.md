# Gender-Aware Smart Push Notifications

Smart reminders are sent through the OneSignal integration that already ships in the app. Each user is addressed based on the gender saved on their profile ("Please sir, drink water." / "Please madam, make sure to drink water."), with a neutral fallback when gender is unknown.

## How it works

1. When the app loads the profile, it calls `OneSignal.login(user_id)` and tags the device with the user's gender (`lib/features/profile/presentation/providers/profile_providers.dart`). On sign-out or account deletion the device is unlinked.
2. The backend endpoint `POST /api/notifications/smart` looks up all verified users, buckets them by gender, and sends the matching message via the OneSignal REST API in the background.

## Setup (one step)

Set the OneSignal REST API key in the backend environment:

```
ONESIGNAL_REST_API_KEY=<your key from OneSignal dashboard → Settings → Keys & IDs>
```

`ONESIGNAL_APP_ID` defaults to the app ID already used in `main.dart`; override via env if it changes.

## Sending a reminder

```
POST /api/notifications/smart
{
  "reminder_type": "drink_water",   // or "move", "log_meal"
  "target_users": "all",            // or pass "emails": ["a@b.com"]
  "admin_key": "<ADMIN_API_KEY>"
}
```

## Scheduling

Call the endpoint from any cron scheduler to build the reminder plan, e.g.:

```
0 10,15 * * *  curl -X POST .../api/notifications/smart -d '{"reminder_type":"drink_water",...}'
0 17 * * *     curl -X POST .../api/notifications/smart -d '{"reminder_type":"move",...}'
0 20 * * *     curl -X POST .../api/notifications/smart -d '{"reminder_type":"log_meal",...}'
```

New reminder types: add an entry to `SMART_MESSAGES` in `backend/routes/notifications.py`.

---

# Personalized Nutrition Notifications (v2)

`backend/services/smart_nutrition_service.py` runs automatically at fixed local times each day
(default 10:00, 12:00, 14:00, 16:00, 18:00, 20:00; APScheduler in `main.py`) and sends each active user at most ONE
personalized push based on today's `DailyStats` vs their targets, addressed by
first name.

## Rules (priority order, local time)

| Rule | When | Message |
|---|---|---|
| `overeat` | calories > 110% of budget | "Mohamed, you've eaten 2600 kcal — 400 over budget. A workout would balance it out." |
| `no_food` | 10:00-14:00, nothing logged | "The morning is almost over and you haven't logged anything yet…" |
| `protein_evening` | ≥ 18:00, protein < 75% of target | "Only 40 g of protein to go — prepare a high-protein dinner!" |
| `day_win` | ≥ 18:00, protein hit & calories within budget | "Amazing work! You hit 130 g of protein…" |
| `on_track` | 12:00-18:00, 35-75% of calorie budget eaten | "Good job Mohamed! You've eaten 80 g of protein — only 40 g left…" |

## Anti-spam
- Quiet hours: nothing before 10:00 or after 22:00 local.
- Each rule fires max once per user per day; hard cap 3 pushes/user/day.
- Audience: users with `DailyStats` activity in the last 7 days. During the
  `no_food` window (11:00–14:00) every verified non-banned user is also
  considered, so people who never logged still get the missed-meal reminder.
- Dedup state in Redis (`smartnotif:*` keys, 36h TTL); in-memory fallback.
- Scheduler runs once immediately on API startup, then every
  `SMART_NOTIF_INTERVAL_HOURS`.

## Config (env)
```
ONESIGNAL_REST_API_KEY=...        # required, scheduler won't start without it
SMART_NOTIF_ENABLED=true          # set false to disable the scheduler
SMART_NOTIF_LOCAL_HOURS=10,12,14,16,18,20  # local times the check runs each day
SMART_NOTIF_TZ_OFFSET_MIN=60      # user base timezone offset from UTC, minutes
```

## Manual trigger (testing)
```
POST /api/notifications/nutrition-check
{ "admin_key": "<ADMIN_API_KEY>" }
```
Response includes `checked`, `sent`, and a per-rule `breakdown`.

Note: pushes are sent one API call per user (content is personalized). Fine up
to tens of thousands of users per run. A future upgrade: store each user's
`tz_offset` from the app instead of the global `SMART_NOTIF_TZ_OFFSET_MIN`.

---

# Body Photo Evening Reminder

`backend/services/progress_reminder_service.py` runs once each evening (default
20:00 local; scheduled alongside the nutrition scheduler in `main.py`). For each
recently-active user it checks whether all four guided body-photo angles
(front, left, right, back) have been captured for TODAY. If any are missing it
sends a single OneSignal nudge addressed by first name, e.g.:

  "Mohamed, you still have 3 of today's 4 body shots to take. Snap them before
   bed so your timeline stays consistent!"

## Behaviour
- Fires at most once per user per day (Redis dedup key `progressphoto:reminder:*`,
  in-memory fallback).
- Skips users who already completed all four poses today.
- Audience: users with `DailyStats` activity in the last 7 days (never spams
  dormant accounts).

## Config (env)
```
PROGRESS_PHOTO_REMINDER_ENABLED=true   # set false to disable
PROGRESS_PHOTO_REMINDER_HOUR=20        # local hour to send the nudge
PROGRESS_TZ_OFFSET_MIN=60              # optional; defaults to SMART_NOTIF_TZ_OFFSET_MIN
```
Requires `ONESIGNAL_REST_API_KEY` (same key as the other reminders).

## Manual trigger (testing)
```
POST /api/notifications/progress-photo-check
{ "admin_key": "<ADMIN_API_KEY>" }
```
Response includes `checked`, `sent`, `already_complete`, and a failures sample.

The pose is stored per photo (`progress_photos.pose` = front|left|right|back).
Re-taking a pose the same day overwrites the previous shot, so counts stay clean.

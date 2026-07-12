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

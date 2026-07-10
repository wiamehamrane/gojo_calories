# GojoCalories Admin Panel

Admin dashboard for managing the GojoCalories platform at **admin.gojocalories.com**.

## Features

- **Dashboard** — Platform overview (users, subscriptions, content stats)
- **Users** — Search, view, ban/unban, grant/revoke Pro, delete
- **Subscriptions** — View active subscribers by source (Apple, Google, Stripe)
- **Food Logs** — Browse and moderate food entries
- **Exercises** — View exercise logs
- **Events** — Manage community events
- **Posts / Memories / Groups** — Content moderation
- **Referrals & Withdrawals** — Approve payout requests
- **Notifications** — Send bulk emails to users

## Design

The admin panel matches the GojoCalories mobile app design system:
- Inter font, teal primary (`#00B4CC` / `#007D8F`)
- iOS-style cards with 20px border radius
- Light theme with `#F2F2F7` background

## Local Development

### 1. Create an admin user

```bash
cd backend
python scripts/create_admin.py admin@gojocalories.com YourPassword "Admin Name"
```

Or promote an existing user:

```bash
python scripts/create_admin.py existing@email.com --promote
```

### 2. Start the backend

```bash
./scripts/start-local-backend.sh
```

### 3. Start the admin panel

```bash
cd admin
cp .env.example .env.local
# Set NEXT_PUBLIC_API_URL=http://localhost:5000/api for local backend
npm install
npm run dev
```

Open http://localhost:3001 and sign in with your admin credentials.

## Production Deployment (AWS)

### Prerequisites

1. Deploy the API first (admin routes are part of the backend)
2. Add `https://admin.gojocalories.com` to the `ALLOWED_ORIGINS` SSM secret
3. Create your first admin user on production:

```bash
# SSH into ECS task or run locally against prod DB
python backend/scripts/create_admin.py admin@gojocalories.com SecurePassword
```

### Deploy admin panel

```bash
chmod +x scripts/deploy-admin.sh
./scripts/deploy-admin.sh
```

This builds the Next.js Docker image, pushes to ECR, and deploys via AWS Copilot to `admin.gojocalories.com`.

### First-time Copilot setup

If the admin service doesn't exist yet:

```bash
copilot svc init \
  --name admin \
  --svc-type "Load Balanced Web Service" \
  --dockerfile admin/Dockerfile \
  --port 3000
```

Then deploy with `./scripts/deploy-admin.sh`.

## API Endpoints

All admin endpoints are under `/api/admin/` and require a JWT from an admin user:

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/admin/auth/login` | POST | Admin login |
| `/admin/auth/me` | GET | Current admin |
| `/admin/dashboard` | GET | Platform stats |
| `/admin/users` | GET | List users |
| `/admin/users/{id}` | GET/PATCH/DELETE | User management |
| `/admin/subscriptions` | GET | Active subscriptions |
| `/admin/subscriptions/{id}` | PATCH | Update subscription |
| `/admin/food-logs` | GET | Food logs |
| `/admin/events` | GET/DELETE | Events |
| `/admin/posts` | GET/DELETE | Posts |
| `/admin/memories` | GET/DELETE | Memories |
| `/admin/groups` | GET/DELETE | Groups |
| `/admin/referrals` | GET | Referral history |
| `/admin/withdrawals` | GET/PATCH | Payout requests |
| `/admin/notifications/send` | POST | Bulk email |

## Security

- Only users with `is_admin=true` can access admin endpoints
- Banned users cannot authenticate
- Admin JWT uses the same signing key as the mobile app
- Keep admin credentials secure; use strong passwords

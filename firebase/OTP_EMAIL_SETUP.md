# OTP email via Firebase — setup

Your backend keeps generating and verifying the 6-digit code. This adds a
Firebase Cloud Function (`sendOtpEmail`) that **delivers the code email**, and a
flag that switches the backend from AWS SES to Firebase. SES stays as the
fallback (`EMAIL_PROVIDER=ses`).

```
register/resend → backend generates code → backend POSTs {email, code}
   → Firebase sendOtpEmail function → SMTP provider → user's inbox
verify-otp → backend checks the code (unchanged)
```

## Prerequisites
- A Firebase project on the **Blaze (pay-as-you-go) plan** — required for a
  function to make outbound SMTP connections. (Free tier blocks external network.)
- An SMTP email provider: **SendGrid**, Mailgun, Postmark, or Gmail app-password.
  Firebase does not send email itself; the function relays through this provider.
- Node.js 20 and the Firebase CLI: `npm i -g firebase-tools`, then `firebase login`.

## 1. Point at your project
Edit `firebase/.firebaserc` and replace `REPLACE_WITH_YOUR_FIREBASE_PROJECT_ID`
with your Firebase project id (or run `firebase use --add`).

## 2. Non-sensitive SMTP config
```
cd firebase/functions
cp .env.example .env
# edit .env → SMTP_HOST, SMTP_PORT, SMTP_FROM for your provider
```

## 3. Secrets (sensitive)
Pick any strong random string for the shared secret; the backend must send the
same value.
```
cd firebase
firebase functions:secrets:set SMTP_USER          # e.g. "apikey" for SendGrid
firebase functions:secrets:set SMTP_PASS          # the SMTP password / API key
firebase functions:secrets:set OTP_SHARED_SECRET  # a long random string you choose
```

## 4. Install deps & deploy
```
cd firebase/functions && npm install
cd .. && firebase deploy --only functions
```
Copy the deployed URL from the output, e.g.
`https://us-central1-<project>.cloudfunctions.net/sendOtpEmail`.

## 5. Point the backend at Firebase
Set these environment variables on the API server (ECS task / `.env`):
```
EMAIL_PROVIDER=firebase
FIREBASE_OTP_FUNCTION_URL=https://us-central1-<project>.cloudfunctions.net/sendOtpEmail
FIREBASE_OTP_SHARED_SECRET=<the same value you set for OTP_SHARED_SECRET>
```
Redeploy / restart the backend. No code change or DB change is needed —
`email_service.send_verification_code_email_or_raise` now routes through Firebase.

## 6. Test
1. Register a new account in the app.
2. The 6-digit code arrives from your SMTP sender (check the function logs:
   `firebase functions:log`).
3. Enter it on the verify screen — `/api/auth/verify-otp` confirms it as before.

## Rollback
Set `EMAIL_PROVIDER=ses` (or unset it) on the backend and restart. Everything
reverts to AWS SES; the function can stay deployed, unused.

## Notes
- **Deliverability:** verify your sending domain with the SMTP provider (SPF +
  DKIM) so codes don't land in spam. This is the real fix for the SES sandbox
  problem — the provider you choose here, not Firebase itself, determines inbox
  placement.
- **Security:** the function rejects any request without the matching
  `x-otp-secret` header, so only your backend can trigger emails.
- **Cost:** Blaze has a generous free monthly allotment; OTP email volume is
  tiny, so expect ~\$0.

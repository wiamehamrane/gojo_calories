# Subscription Setup Guide

This guide covers everything you need to configure in **AWS**, **App Store Connect**, **Google Play Console**, and **Stripe** after deploying the new pricing system.

## Pricing overview

| Plan | Price | Product ID |
|------|-------|------------|
| Monthly | $5.99/mo | `gojo_pro_monthly` |
| 6-Month | $14.99 every 6 months | `gojo_pro_six_month` |
| Yearly | $19.99/yr | `gojo_pro_yearly` |
| Clan add-on (monthly) | $1.99/mo per member | `gojo_clan_addon_monthly` |
| Clan add-on (6-month) | $3.99 per member | `gojo_clan_addon_six_month` |
| Clan add-on (yearly) | $6.99/yr per member | `gojo_clan_addon_yearly` |

**Referral offer:** Referred users pay **60%** for the **first 2 billing periods** (configured server-side, not hardcoded in the app).

---

## 1. AWS (SSM Parameter Store)

Add these secrets/parameters under `/copilot/gojocalories/prod/secrets/` (or your environment path):

### Stripe Price IDs (required for web checkout)

Create products/prices in [Stripe Dashboard](https://dashboard.stripe.com/products), then store the **Price ID** (starts with `price_`):

| SSM Parameter | Example value | Stripe config |
|---------------|---------------|---------------|
| `STRIPE_PRICE_MONTHLY` | `price_xxx` | $5.99 / month recurring |
| `STRIPE_PRICE_SIX_MONTH` | `price_xxx` | $14.99 / 6 months recurring |
| `STRIPE_PRICE_YEARLY` | `price_xxx` | $19.99 / year recurring |
| `STRIPE_PRICE_CLAN_ADDON_MONTHLY` | `price_xxx` | $1.99 / month recurring |
| `STRIPE_PRICE_CLAN_ADDON_SIX_MONTH` | `price_xxx` | $3.99 / 6 months recurring |
| `STRIPE_PRICE_CLAN_ADDON_YEARLY` | `price_xxx` | $6.99 / year recurring |

### Referral coupon (Stripe web checkout)

1. In Stripe → **Products → Coupons**, create a coupon:
   - **Percent off:** `40` (= user pays 60%)
   - **Duration:** Repeating
   - **Duration in months:** `2`

2. Store the coupon ID:

| SSM Parameter | Example value |
|---------------|---------------|
| `STRIPE_REFERRAL_COUPON_ID` | `REFERRAL60` or `coupon_xxx` |

### Optional pricing overrides (defaults are correct)

| SSM Parameter | Default |
|---------------|---------|
| `PLAN_MONTHLY_CENTS` | `599` |
| `PLAN_SIX_MONTH_CENTS` | `1499` |
| `PLAN_YEARLY_CENTS` | `1999` |
| `CLAN_ADDON_MONTHLY_CENTS` | `199` |
| `CLAN_ADDON_SIX_MONTH_CENTS` | `399` |
| `CLAN_ADDON_YEARLY_CENTS` | `699` |
| `CLAN_MAX_MEMBERS` | `5` |
| `REFERRAL_PAY_PERCENT` | `60` |
| `REFERRAL_DURATION_PERIODS` | `2` |

### Add to Copilot manifest (optional)

In `copilot/api/manifest.yml`, add new secrets under `secrets:`:

```yaml
  STRIPE_PRICE_MONTHLY: /copilot/${COPILOT_APPLICATION_NAME}/${COPILOT_ENVIRONMENT_NAME}/secrets/STRIPE_PRICE_MONTHLY
  STRIPE_PRICE_SIX_MONTH: /copilot/${COPILOT_APPLICATION_NAME}/${COPILOT_ENVIRONMENT_NAME}/secrets/STRIPE_PRICE_SIX_MONTH
  STRIPE_PRICE_YEARLY: /copilot/${COPILOT_APPLICATION_NAME}/${COPILOT_ENVIRONMENT_NAME}/secrets/STRIPE_PRICE_YEARLY
  STRIPE_REFERRAL_COUPON_ID: /copilot/${COPILOT_APPLICATION_NAME}/${COPILOT_ENVIRONMENT_NAME}/secrets/STRIPE_REFERRAL_COUPON_ID
```

Then set values via AWS CLI:

```bash
aws ssm put-parameter --name "/copilot/gojocalories/prod/secrets/STRIPE_PRICE_MONTHLY" --value "price_xxx" --type SecureString --overwrite
```

### Deploy

```bash
./scripts/deploy.sh          # Backend API
./scripts/deploy-admin.sh    # Admin panel (if changed)
```

Database tables (`clans`, `clan_members`, `clan_invites`) are created automatically on API startup.

---

## 2. App Store Connect

### Create subscription group: **Gojo Pro**

Add these **auto-renewable subscriptions** (exact Product IDs):

| Product ID | Price | Duration |
|------------|-------|----------|
| `gojo_pro_monthly` | $5.99 | 1 month |
| `gojo_pro_six_month` | $14.99 | 6 months |
| `gojo_pro_yearly` | $19.99 | 1 year |

### Create subscription group: **Gojo Clan Add-ons**

| Product ID | Price | Duration |
|------------|-------|----------|
| `gojo_clan_addon_monthly` | $1.99 | 1 month |
| `gojo_clan_addon_six_month` | $3.99 | 6 months |
| `gojo_clan_addon_yearly` | $6.99 | 1 year |

### Required steps

1. **Agreements** → Paid Apps agreement must be **Active**
2. Link all 6 subscriptions to your app version (App → Version → In-App Purchases)
3. Add **App Store Server Notifications v2** URL:
   ```
   https://api.gojocalories.com/api/payments/apple/webhook
   ```
4. Ensure `APPLE_SHARED_SECRET` is set in AWS SSM (already configured)
5. For local Xcode testing, use `ios/GojoCalories.storekit` (already updated)

### Referral discount on iOS

Apple does not allow dynamic discounts from your backend. Options:

- **Current implementation:** App shows referral prices from API; after IAP purchase the backend extends access to approximate the 60% savings
- **Alternative (optional):** Create **Promotional Offers** in App Store Connect for referred users (requires offer codes or subscription offer signatures)

### TestFlight testing

- Use a **Sandbox Apple ID** (Settings → Developer → Sandbox Account)
- New products can take up to **24 hours** to appear after linking to an app version

---

## 3. Google Play Console

Package: `com.gojocalories.gojocalories`

### Create subscriptions (same Product IDs)

| Product ID | Price | Billing period |
|------------|-------|----------------|
| `gojo_pro_monthly` | $5.99 | Monthly |
| `gojo_pro_six_month` | $14.99 | Every 6 months |
| `gojo_pro_yearly` | $19.99 | Yearly |
| `gojo_clan_addon_monthly` | $1.99 | Monthly |
| `gojo_clan_addon_six_month` | $3.99 | Every 6 months |
| `gojo_clan_addon_yearly` | $6.99 | Yearly |

### Required steps

1. Activate all subscriptions in at least one testing track (Internal testing)
2. Add license testers under **Settings → License testing**
3. Upload a signed build to Internal testing
4. Configure **Real-time developer notifications** (Pub/Sub) pointing to:
   ```
   https://api.gojocalories.com/api/payments/google/webhook
   ```
5. Ensure `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` is set in AWS SSM

---

## 4. How it works in the app

### Paywall
- App calls `GET /api/payments/catalog` for plan names, taglines, badges, and referral pricing
- Actual charge amounts come from App Store / Google Play (`product.price`)
- No prices are hardcoded in Flutter

### Referrals
- Each user gets a code + link: `https://gojocalories.com/join?ref=ABC123`
- New users who sign up with a referral code get the 60%-for-2-periods offer
- **Stripe:** automatic coupon at checkout
- **IAP:** backend extends subscription duration to approximate the discount

### Clan (family plan)
1. Subscriber goes to **Profile → Clan Plan**
2. Invites family member by email → share link copied
3. Member signs up and accepts invite
4. Owner purchases the matching **clan add-on** subscription in the app
5. Member gets Pro access without paying full price

---

## 5. API endpoints (new)

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/payments/catalog` | Server-driven plan catalog |
| GET | `/api/clan/me` | Current clan status |
| POST | `/api/clan/invite` | Invite family member |
| POST | `/api/clan/accept` | Accept clan invite |
| DELETE | `/api/clan/members/{id}` | Remove member |

---

## 6. Checklist

- [ ] Create 6 Stripe prices + referral coupon
- [ ] Add Stripe Price IDs + coupon ID to AWS SSM
- [ ] Create 6 subscriptions in App Store Connect
- [ ] Create 6 subscriptions in Google Play Console
- [ ] Link IAP products to app versions
- [ ] Deploy backend (`./scripts/deploy.sh`)
- [ ] Upload new app build to TestFlight / Internal testing
- [ ] Test: subscribe → invite clan member → purchase add-on
- [ ] Test: sign up with referral link → verify discounted pricing on paywall

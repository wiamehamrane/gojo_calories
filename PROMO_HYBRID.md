# Hybrid promo codes

Gojo supports three promo types. All codes are created in the **admin panel** (or via Apple ASC API batch) so redemptions can be attributed to influencers.

| Type | Where the code is created | User experience | Access |
|------|---------------------------|-----------------|--------|
| **Internal** | Admin only | Enter code in app → instant Pro | Backend `grant_subscription(source=promo)` |
| **Apple** | App Store Connect (+ admin register) | App opens Apple redemption sheet → real IAP subscription | Apple IAP verify + `finalize_pending_promo` |
| **Google** | Google Play Console (+ admin register) | App opens `play.google.com/redeem?code=...` | Google IAP verify + `finalize_pending_promo` |

## Internal codes (e.g. WIAM10)

1. Admin → Influencer → **Internal — instant free grant**
2. Optional custom code or auto-generated
3. User enters code during onboarding or Profile → Redeem promo
4. Backend grants Pro immediately

## Apple offer codes

1. App Store Connect → your app → Subscriptions → **Offer Codes**
2. Create a custom or one-time offer linked to `gojo_pro_monthly`, `gojo_pro_six_month`, or `gojo_pro_yearly`
3. Admin → Influencer → **Apple — offer / promo code** → paste exact code + plan
4. User redeems in app → Apple sheet → completes subscription → app verifies IAP
5. Backend links purchase to influencer via `users.pending_promo_code_id`

### Optional: ASC API batch generation

Set on the backend:

- `APPLE_ASC_KEY_ID`
- `APPLE_ASC_ISSUER_ID`
- `APPLE_ASC_PRIVATE_KEY`
- `APPLE_ASC_OFFER_CODE_ID_MONTHLY` (and/or `_SIX_MONTH`, `_YEARLY`)

Admin → **Generate Apple batch** creates codes in ASC and registers them automatically.

## Google Play promo codes

Google does **not** expose a public API to create promo codes. Create them manually:

1. Google Play Console → Monetization → **Promo codes**
2. Link to the matching subscription product
3. Admin → Influencer → **Google Play — promo code** → paste exact code + plan
4. User taps redeem in app → opens Play Store redeem URL
5. After subscribing, app verifies purchase; backend finalizes promo attribution

## API

- `POST /api/payments/resolve-promo` — lookup + instructions (no side effects)
- `POST /api/payments/redeem-promo` — internal grants instantly; apple/google set pending + return store instructions

## Flutter

- `PromoRedeemFlow.redeem()` calls backend
- **Internal** → home / success snackbar
- **Apple** → `presentCodeRedemptionSheet()` + restore purchases
- **Google** → `url_launcher` to Play redeem URL

After store redemption, user should subscribe or tap **Restore purchases** on the paywall so IAP verify runs and influencer credit is recorded.

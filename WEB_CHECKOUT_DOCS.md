# Secure Web Checkout Documentation for GojoCalories

To securely handle payments on your own domain (`gojocalories.com`), you have two primary options using Stripe. Your current backend (`backend/routes/payments.py`) is already doing the heavy lifting, so adding a secure web checkout is straightforward.

## Option 1: Embedded Stripe Elements (Recommended)

This method embeds the payment form directly on your website (e.g., `https://gojocalories.com/checkout`). It is highly secure because credit card data never touches your server; it goes directly from the user's browser to Stripe's servers.

### How it works with your existing backend
Your backend route `/api/payments/create-checkout-session` is actually perfectly configured for this. 
1. It creates an initial incomplete subscription.
2. It expands `pending_setup_intent` and returns the `setupIntent` client secret.

### Web Frontend Implementation Steps
1. **Install Stripe JS**: If using React/Next.js, install `@stripe/react-stripe-js` and `@stripe/stripe-js`. If pure HTML/JS, include `<script src="https://js.stripe.com/v3/"></script>`.
2. **Call Backend**: Your web app calls your backend's `/create-checkout-session` endpoint.
3. **Initialize Elements**: Pass the `publishableKey` to `loadStripe()` and pass the returned `setupIntent` client secret to the `<Elements>` provider.
4. **Render Form**: Use the `<PaymentElement />` (Stripe's pre-built UI component) which automatically handles formatting, validation, and localizing the payment form.
5. **Submit**: When the user clicks "Pay", call `stripe.confirmSetup({ elements, confirmParams: { return_url: "https://gojocalories.com/success" } })`. 
6. **Security & Webhooks**: Stripe will redirect to the return URL. In the background, Stripe hits your existing webhook (`/api/payments/webhook`) with the `setup_intent.succeeded` event, which attaches the payment method and activates the subscription.

**Security Benefit**: You maintain full control over the UI, the domain stays exactly as `gojocalories.com`, and you are granted PCI SAQ A compliance automatically.

---

## Option 2: Stripe Checkout with Custom Domain

Stripe Checkout is a Stripe-hosted payment page. Normally, users are redirected to `checkout.stripe.com`. However, you can configure Stripe to use your domain, such as `pay.gojocalories.com` or `checkout.gojocalories.com`.

### Setup Steps in Stripe Dashboard
1. Go to your **Stripe Dashboard** > **Settings** (gear icon) > **Custom Domains**.
2. Click **Add your domain**.
3. Choose a subdomain (e.g., `pay.gojocalories.com`).
4. Stripe will provide you with DNS records (CNAME). Add these to your DNS provider (e.g., Route 53, Cloudflare, Namecheap).
5. Once verified, all your Stripe Checkout sessions will use your custom domain.

### Backend Changes Required
Currently, your `/create-checkout-session` endpoint uses Stripe's lower-level Subscriptions API for the mobile app (returning Ephemeral Keys and Setup Intents). 
To use Stripe Checkout, you would need to create a slightly different flow for the web (or modify the existing one based on the client):
```python
# Example of what the backend would return for Stripe Checkout
session = stripe.checkout.Session.create(
    customer=user.stripe_customer_id,
    payment_method_types=['card'],
    line_items=[{
        'price': price_id,
        'quantity': 1,
    }],
    mode='subscription',
    subscription_data={
        'trial_period_days': 3,
    },
    success_url='https://gojocalories.com/success?session_id={CHECKOUT_SESSION_ID}',
    cancel_url='https://gojocalories.com/cancel',
)
return {"url": session.url} # Redirect the web user to this URL
```

---

## TLS/SSL and Security Checklist
Regardless of the option you choose, processing payments on your domain requires that the connection is secure:
1. **HTTPS is Mandatory**: Ensure `https://gojocalories.com` is served via SSL/TLS. Your AWS Application Load Balancer setup with ACM (noted in past conversations) covers this perfectly.
2. **Never log card details**: By using Stripe Elements or Stripe Checkout, card details are never submitted to your backend form handlers, maintaining top-tier security.
3. **Webhook Signatures**: You already have signature verification built into your webhook route, which prevents bad actors from spoofing successful payment events.

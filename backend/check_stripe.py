import stripe
import os
from dotenv import load_dotenv

load_dotenv()
stripe.api_key = os.getenv("STRIPE_SECRET_KEY")

try:
    print("Fetching last 10 Setup Intents from Stripe...")
    sis = stripe.SetupIntent.list(limit=10)
    for si in sis.data:
        print(f"SetupIntent {si.id}")
        print(f"  Status: {si.status}")
        print(f"  Customer: {si.customer}")
        print(f"  PaymentMethod: {si.payment_method}")
        print(f"  Usage: {si.usage}")
        print("---")
except Exception as e:
    print("Error:", e)

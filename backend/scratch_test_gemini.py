import os
from google import genai
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

api_key = os.getenv("GEMINI_API_KEY")

if not api_key:
    print("GEMINI_API_KEY is not set!")
    exit(1)

client = genai.Client(api_key=api_key)

models_to_test = [
    'gemini-1.5-flash',
    'gemini-2.0-flash',
    'gemini-2.5-flash-lite',
    'gemini-3.1-flash-lite'
]

for model in models_to_test:
    try:
        print(f"\nTesting model: {model}")
        response = client.models.generate_content(
            model=model,
            contents="Hello, identify yourself and confirm you are working."
        )
        print(f"Success! Response: {response.text[:100]}...")
    except Exception as e:
        print(f"Failed for {model}: {e}")

import os
from dotenv import load_dotenv
import google.generativeai as genai
import traceback

load_dotenv(dotenv_path="/home/zelghourfi/Documents/gojocalories/backend/.env")
key = os.getenv("GEMINI_API_KEY")
print("Key exists:", bool(key))
genai.configure(api_key=key)

try:
    models = genai.list_models()
    count = 0
    for m in models:
        count += 1
        if "generateContent" in m.supported_generation_methods:
            print(m.name)
    print("Total models:", count)
except Exception as e:
    traceback.print_exc()

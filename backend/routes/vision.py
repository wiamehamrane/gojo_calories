from fastapi import APIRouter, UploadFile, File, HTTPException, Depends
from google import genai
import os
from dotenv import load_dotenv
import json
from PIL import Image
import io
from security import get_current_user_id
from pydantic import BaseModel

load_dotenv()
client = genai.Client(api_key=os.getenv("GEMINI_API_KEY"))

router = APIRouter()

@router.post("/analyze")
async def analyze_food_image(file: UploadFile = File(...), current_user_id: int = Depends(get_current_user_id)):
    try:
        # Read image
        contents = await file.read()
        image = Image.open(io.BytesIO(contents))
        
        # Proper prompt asking for strict JSON
        prompt = """
        Analyze this food image. Identify the overarching meal or food item.
        Respond ONLY with a JSON object. No markdown formatting, no backticks, no explanations. 
        Format strictly like this:
        {"name": "Food Name", "calories": 500, "protein": 20, "carbs": 50, "fat": 15}
        """
        
        response = client.models.generate_content(
            model='gemini-2.0-flash',
            contents=[prompt, image]
        )
        
        # Extract response text and parse JSON
        raw_text = response.text
        text = raw_text.replace('```json', '').replace('```', '').strip()
        data = json.loads(text)
        
        # Upload to S3
        from s3_utils import upload_image_to_s3
        s3_url = upload_image_to_s3(contents, file.content_type)
        
        # Save to DB
        from models import FoodLog
        from database import get_db
        from routes.stats import log_macro
        
        with next(get_db()) as db:
            log = FoodLog(user_id=current_user_id, name=data.get('name', 'Unknown'), image_url=s3_url, calories=data.get('calories', 0), protein=data.get('protein', 0), carbs=data.get('carbs', 0), fat=data.get('fat', 0))
            db.add(log)
            db.commit()
            
            # Automatically update the user's daily progress
            log_macro(calories=log.calories, protein=log.protein, carbs=log.carbs, fat=log.fat, db=db, current_user_id=current_user_id)

        return data
        
    except json.JSONDecodeError as je:
        print(f"JSON Parsing Error: {je}")
        print(f"Raw model output was: {raw_text}")
        raise HTTPException(status_code=500, detail="Failed to parse AI output into JSON.")
    except Exception as e:
        print(f"Error analyzing image: {e}")
        raise HTTPException(status_code=500, detail=str(e))

class TextQuery(BaseModel):
    query: str

@router.post("/analyze/text")
async def analyze_food_text(body: TextQuery, current_user_id: int = Depends(get_current_user_id)):
    try:
        prompt = f"""
        Estimate the nutritional macros for the following food item or meal description: "{body.query}"
        Respond ONLY with a JSON object. No markdown formatting, no backticks, no explanations. 
        Format strictly like this:
        {{"name": "Food Name", "calories": 500, "protein": 20, "carbs": 50, "fat": 15}}
        """
        
        response = client.models.generate_content(
            model='gemini-2.0-flash',
            contents=prompt
        )
        raw_text = response.text
        text = raw_text.replace('```json', '').replace('```', '').strip()
        data = json.loads(text)
        
        from models import FoodLog
        from database import get_db
        from routes.stats import log_macro
        
        with next(get_db()) as db:
            log = FoodLog(
                user_id=current_user_id, 
                name=data.get('name', body.query), 
                image_url=None, 
                calories=data.get('calories', 0), 
                protein=data.get('protein', 0), 
                carbs=data.get('carbs', 0), 
                fat=data.get('fat', 0)
            )
            db.add(log)
            db.commit()
            
            # Automatically update the user's daily progress
            log_macro(calories=log.calories, protein=log.protein, carbs=log.carbs, fat=log.fat, db=db, current_user_id=current_user_id)

        return data
        
    except json.JSONDecodeError as je:
        print(f"JSON Parsing Error: {je}")
        print(f"Raw model output was: {raw_text}")
        raise HTTPException(status_code=500, detail="Failed to parse AI output into JSON.")
    except Exception as e:
        print(f"Error analyzing text: {e}")
        raise HTTPException(status_code=500, detail=str(e))

from fastapi import APIRouter, UploadFile, File, HTTPException, Depends, Query
from google import genai
import os
from typing import Optional
from dotenv import load_dotenv
import json
from PIL import Image
import io
from security import get_current_user_id
from pydantic import BaseModel
import logging
import datetime

logger = logging.getLogger(__name__)

load_dotenv()

_GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
if not _GEMINI_API_KEY:
    logger.error("GEMINI_API_KEY is not set! Vision AI endpoints will fail.")

_FOODDATA_API_KEY = os.getenv("FOODDATA_CENTRAL_API_KEY")
if not _FOODDATA_API_KEY:
    logger.error("FOODDATA_CENTRAL_API_KEY is not set! USDA food search will fail.")

try:
    client = genai.Client(api_key=_GEMINI_API_KEY)
    logger.info("Gemini client initialised successfully.")
except Exception as _e:
    logger.error(f"Failed to initialise Gemini client: {_e}")
    client = None

router = APIRouter()


def _resolve_local_date(local_date: Optional[str]) -> datetime.date:
    """Return the user's local date if provided, else fall back to UTC today."""
    if local_date:
        try:
            return datetime.datetime.strptime(local_date, "%Y-%m-%d").date()
        except ValueError:
            pass
    return datetime.datetime.utcnow().date()


@router.post("/analyze")
async def analyze_food_image(
    file: UploadFile = File(...),
    local_date: Optional[str] = Query(None, description="User's local date YYYY-MM-DD"),
    current_user_id: int = Depends(get_current_user_id),
):
    try:
        if client is None:
            raise HTTPException(status_code=503, detail="Vision AI is unavailable: GEMINI_API_KEY is not configured on the server.")

        # Read image
        contents = await file.read()
        image = Image.open(io.BytesIO(contents))
        
        # Proper prompt asking for strict JSON
        prompt = """
        Analyze this food image. Identify the overarching meal or food item and its individual ingredients.
        Respond ONLY with a JSON object. No markdown formatting, no backticks, no explanations.
        Format strictly like this:
        {"name_en": "Food Name English", "name_fr": "Nom de l'aliment en français", "name_ar": "اسم الطعام بالعربية", "calories": 500, "protein": 20, "carbs": 50, "fat": 15, "ingredients": [{"name": "Ingredient", "amount": "1.5 cups", "calories": 45}, {"name": "Ingredient 2", "amount": "2 tbsp", "calories": 60}]}
        Include 3 to 8 realistic, specific ingredients with accurate amounts and calorie estimates.
        """

        
        logger.info(f"Calling Gemini vision for user {current_user_id}")
        response = client.models.generate_content(
            model='gemini-2.5-flash',
            contents=[prompt, image]
        )
        
        # Extract response text and parse JSON
        raw_text = response.text
        text = raw_text.replace('```json', '').replace('```', '').strip()
        data = json.loads(text)
        
        # Upload to S3 (non-fatal — if it fails we just skip the image URL)
        s3_url = None
        try:
            from s3_utils import upload_image_to_s3
            s3_url = upload_image_to_s3(contents, file.content_type or 'image/jpeg')
        except Exception as s3_err:
            print(f"S3 upload skipped: {s3_err}")
        
        # Save to DB using a single session
        from models import FoodLog, DailyStats, User
        from database import get_db
        
        today = _resolve_local_date(local_date)

        with next(get_db()) as db:
            # 1. Insert food log
            log = FoodLog(
                user_id=current_user_id,
                name=data.get('name_en', data.get('name', 'Unknown')),
                name_en=data.get('name_en'),
                name_fr=data.get('name_fr'),
                name_ar=data.get('name_ar'),
                image_url=s3_url,
                calories=int(data.get('calories', 0)),
                protein=int(data.get('protein', 0)),
                carbs=int(data.get('carbs', 0)),
                fat=int(data.get('fat', 0)),
                ingredients=data.get('ingredients'),
            )
            db.add(log)
            db.flush()  # get log.id without committing yet

            # 2. Update (or create) the user's local-date DailyStats in the same session
            stat = db.query(DailyStats).filter(
                DailyStats.user_id == current_user_id,
                DailyStats.date >= datetime.datetime.combine(today, datetime.time.min),
                DailyStats.date < datetime.datetime.combine(today + datetime.timedelta(days=1), datetime.time.min),
            ).first()

            if stat is None:
                # Bootstrap from user profile
                user = db.query(User).filter(User.id == current_user_id).first()
                weight = (user.current_weight or 70.0) if user else 70.0
                goal_wt = (user.goal_weight or 70.0) if user else 70.0
                age = (user.age or 30) if user else 30
                bmr = (10 * weight) + (6.25 * 170) - (5 * age) + 5
                budget = int(bmr * 1.2)
                if goal_wt < weight - 1.0:
                    budget -= 500
                elif goal_wt > weight + 1.0:
                    budget += 500
                protein_t = int(weight * 2.0)
                fat_t = int((budget * 0.25) / 9)
                carbs_t = max(int((budget - protein_t * 4 - fat_t * 9) / 4), 0)
                stat = DailyStats(
                    user_id=current_user_id,
                    date=datetime.datetime.combine(today, datetime.time.min),
                    calorie_budget=budget,
                    protein_target=protein_t,
                    carbs_target=carbs_t,
                    fat_target=fat_t,
                    calories_consumed=0,
                    protein_consumed=0,
                    carbs_consumed=0,
                    fat_consumed=0,
                )
                db.add(stat)
                db.flush()

            stat.calories_consumed += log.calories
            stat.protein_consumed += log.protein
            stat.carbs_consumed += log.carbs
            stat.fat_consumed += log.fat
            db.commit()

        # Invalidate Redis cache so next stats call is fresh
        try:
            from redis_client import redis_db
            redis_db.delete(f"stats_{current_user_id}")
            redis_db.delete(f"stats_{current_user_id}_{today.isoformat()}")
            redis_db.delete(f"stats_{current_user_id}_latest")
        except Exception:
            pass

        if s3_url:
            data['image_url'] = s3_url
        data['log_id'] = log.id
        data['created_at'] = log.created_at.isoformat() + "Z"
        return data
        
    except json.JSONDecodeError as je:
        print(f"JSON Parsing Error: {je}")
        print(f"Raw model output was: {raw_text}")
        raise HTTPException(status_code=422, detail="AI could not parse the food in this image. Please try a clearer photo.")
    except HTTPException:
        raise
    except Exception as e:
        err_str = str(e).lower()
        if 'quota' in err_str or 'resource_exhausted' in err_str or '429' in err_str:
            print(f"Gemini quota exceeded: {e}")
            raise HTTPException(status_code=503, detail="AI service is temporarily unavailable due to high demand. Please try again in a few minutes.")
        print(f"Error analyzing image: {e}")
        raise HTTPException(status_code=500, detail=f"Analysis failed: {str(e)}")


class TextQuery(BaseModel):
    query: str

@router.post("/analyze/text")
async def analyze_food_text(body: TextQuery, current_user_id: int = Depends(get_current_user_id)):
    try:
        if client is None:
            raise HTTPException(status_code=503, detail="Vision AI is unavailable: GEMINI_API_KEY is not configured on the server.")

        prompt = f"""
        Estimate the nutritional macros for the following food item or meal description: "{body.query}"
        Respond ONLY with a JSON object. No markdown formatting, no backticks, no explanations. 
        Format strictly like this:
        {{"name_en": "Food Name English", "name_fr": "Nom de l'aliment en français", "name_ar": "اسم الطعام بالعربية", "calories": 500, "protein": 20, "carbs": 50, "fat": 15}}
        """
        
        logger.info(f"Calling Gemini text analysis for user {current_user_id}: {body.query!r}")
        response = client.models.generate_content(
            model='gemini-2.5-flash',
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
                name=data.get('name_en', body.query), 
                name_en=data.get('name_en'),
                name_fr=data.get('name_fr'),
                name_ar=data.get('name_ar'),
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


class LogItemModel(BaseModel):
    name: str  # Primary name (usually English)
    name_en: Optional[str] = None
    name_fr: Optional[str] = None
    name_ar: Optional[str] = None
    image_url: Optional[str] = None
    calories: int
    protein: int
    carbs: int
    fat: int


@router.post("/analyze/log")
async def log_food_item(
    body: LogItemModel,
    local_date: Optional[str] = Query(None, description="User's local date YYYY-MM-DD"),
    current_user_id: int = Depends(get_current_user_id),
):
    """Saves a food log and updates daily stats using exact pre-determined macros (e.g. from a barcode scan)."""
    from models import FoodLog
    from database import get_db
    from routes.stats import _log_macro_with_date

    try:
        today = _resolve_local_date(local_date)
        with next(get_db()) as db:
            log = FoodLog(
                user_id=current_user_id,
                name=body.name,
                name_en=body.name_en or body.name,
                name_fr=body.name_fr,
                name_ar=body.name_ar,
                image_url=body.image_url,
                calories=body.calories,
                protein=body.protein,
                carbs=body.carbs,
                fat=body.fat,
            )
            db.add(log)
            db.commit()

            # Automatically update the user's daily progress using the local date
            _log_macro_with_date(
                calories=log.calories,
                protein=log.protein,
                carbs=log.carbs,
                fat=log.fat,
                db=db,
                current_user_id=current_user_id,
                local_date=today,
            )

        return {"status": "success", "message": "Log created successfully"}
    except Exception as e:
        print(f"Error logging explicit item: {e}")
        raise HTTPException(status_code=500, detail="Failed to log the item to history.")


@router.get("/barcode/{barcode}")
async def get_barcode_nutrition(barcode: str, current_user_id: int = Depends(get_current_user_id)):
    """Fetches nutritional data for a given barcode from Open Food Facts."""
    import httpx
    
    url = f"https://world.openfoodfacts.org/api/v2/product/{barcode}.json"
    
    try:
        async with httpx.AsyncClient(headers={"User-Agent": "GojoCalories/1.0 (https://gojocalories.com)"}) as http:
            response = await http.get(url, timeout=10.0)
            
        if response.status_code != 200:
            raise HTTPException(status_code=502, detail="Failed to fetch data from nutrition provider.")
            
        product_data = response.json()
        if product_data.get('status') == 0 or 'product' not in product_data:
            raise HTTPException(status_code=404, detail="Product not found in barcode database.")
            
        product = product_data['product']
        nutriments = product.get('nutriments', {})
        
        def get_num(key: str) -> int:
            for suffix in ['_100g', '_serving', '_value', '']:
                k = f"{key}{suffix}"
                if k in nutriments:
                    try:
                        return int(round(float(nutriments[k])))
                    except (ValueError, TypeError):
                        pass
            return 0

        raw_name = product.get('product_name', '')
        brand = product.get('brands', '')
        
        name = raw_name
        if brand and brand not in raw_name:
            name = f"{raw_name} ({brand})"
        if not name:
            name = "Scanned Product"

        calories = get_num('energy-kcal')
        if calories == 0:
            kj = get_num('energy-kj') or get_num('energy')
            if kj > 0:
                calories = int(round(kj / 4.184))

        return {
            "name": name,
            "calories": calories,
            "protein": get_num('proteins'),
            "carbs": get_num('carbohydrates'),
            "fat": get_num('fat'),
            "brand": brand,
            "image_url": product.get('image_url')
        }
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Barcode lookup error: {e}")
        raise HTTPException(status_code=500, detail="Internal error during barcode lookup.")


@router.get("/ingredients/{food_name}")
async def get_food_ingredients(
    food_name: str,
    current_user_id: int = Depends(get_current_user_id),
):
    """Uses Gemini to return a detailed ingredient breakdown for a given food item."""
    if client is None:
        raise HTTPException(status_code=503, detail="Vision AI unavailable.")

    prompt = f"""
    For the food item "{food_name}", provide a detailed ingredient breakdown with estimated portion sizes and calories.
    Respond ONLY with a JSON object. No markdown, no backticks, no explanations.
    Format exactly like this:
    {{"ingredients": [{{"name": "Ingredient Name", "amount": "1.5 cups", "calories": 45}}, ...]}}
    Include 3 to 8 ingredients. Be realistic and specific.
    """

    try:
        response = client.models.generate_content(
            model='gemini-2.5-flash',
            contents=prompt,
        )
        raw_text = response.text
        text = raw_text.replace('```json', '').replace('```', '').strip()
        data = json.loads(text)
        return data
    except json.JSONDecodeError:
        raise HTTPException(status_code=422, detail="AI could not generate ingredient data.")
    except Exception as e:
        err_str = str(e).lower()
        if 'quota' in err_str or '429' in err_str:
            raise HTTPException(status_code=503, detail="AI service temporarily unavailable.")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/search")
async def search_food(query: str, current_user_id: int = Depends(get_current_user_id)):
    """Searches FoodData Central for a given query."""
    if not _FOODDATA_API_KEY:
        raise HTTPException(status_code=503, detail="FoodData Central API key not configured on the server.")
    
    import httpx
    url = "https://api.nal.usda.gov/fdc/v1/foods/search"
    params = {
        "api_key": _FOODDATA_API_KEY,
        "query": query,
        "pageSize": 10,
        "pageNumber": 1
    }
    
    try:
        async with httpx.AsyncClient(headers={"User-Agent": "GojoCalories/1.0 (https://gojocalories.com)"}) as http:
            response = await http.get(url, params=params, timeout=10.0)
            
        if response.status_code != 200:
            raise HTTPException(status_code=502, detail="Failed to fetch from FoodData Central.")
            
        data = response.json()
        foods = data.get("foods", [])
        
        results = []
        for f in foods:
            nutrients = f.get("foodNutrients", [])
            
            def get_nut(id_str):
                for n in nutrients:
                    if str(n.get("nutrientNumber")) == id_str or str(n.get("nutrientId")) == id_str:
                        return int(round(n.get("value", 0)))
                return 0
                
            cal = get_nut("1008")
            protein = get_nut("1003")
            carbs = get_nut("1005")
            fat = get_nut("1004")
            
            results.append({
                "name": f.get("description", "Unknown Food").title(),
                "brand": f.get("brandOwner", ""),
                "calories": cal,
                "protein": protein,
                "carbs": carbs,
                "fat": fat,
                "serving_size": f"{f.get('servingSize', 100)} {f.get('servingSizeUnit', 'g')}" if f.get('servingSize') else "100 g"
            })
            
        return {"results": results}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"FDC lookup error: {e}")
        raise HTTPException(status_code=500, detail="Internal error during FDC lookup.")

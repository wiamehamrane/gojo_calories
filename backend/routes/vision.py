from fastapi import APIRouter, UploadFile, File, HTTPException, Depends, Query, Request
from s3_utils import resolve_media_url
import os
from typing import Optional, Any, List
from dotenv import load_dotenv
import json
import base64
from PIL import Image
import io
from openai import OpenAI, OpenAIError, RateLimitError
from security import get_current_user_id
from pydantic import BaseModel
import logging
import datetime

logger = logging.getLogger(__name__)

load_dotenv()

_OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")
_OPENAI_MODEL = os.getenv("OPENAI_MODEL", "gpt-5.4-mini")
if not _OPENAI_API_KEY:
    logger.error("OPENAI_API_KEY is not set! Vision AI endpoints will fail.")

_FOODDATA_API_KEY = os.getenv("FOODDATA_CENTRAL_API_KEY")
if not _FOODDATA_API_KEY:
    logger.error("FOODDATA_CENTRAL_API_KEY is not set! USDA food search will fail.")

try:
    client = OpenAI(api_key=_OPENAI_API_KEY) if _OPENAI_API_KEY else None
    if client:
        logger.info("OpenAI client initialised successfully (model=%s).", _OPENAI_MODEL)
except Exception as _e:
    logger.error(f"Failed to initialise OpenAI client: {_e}")
    client = None

router = APIRouter()


def _strip_json_fences(text: str) -> str:
    return text.replace("```json", "").replace("```", "").strip()


def _generate_food_json(prompt: str, image_bytes: Optional[bytes] = None, mime_type: str = "image/jpeg") -> dict:
    if client is None:
        raise HTTPException(
            status_code=503,
            detail="Vision AI is unavailable: OPENAI_API_KEY is not configured on the server.",
        )

    content: list[dict[str, Any]] = [{"type": "text", "text": prompt}]
    if image_bytes is not None:
        encoded = base64.standard_b64encode(image_bytes).decode("utf-8")
        content.append(
            {
                "type": "image_url",
                "image_url": {"url": f"data:{mime_type};base64,{encoded}"},
            }
        )

    try:
        response = client.chat.completions.create(
            model=_OPENAI_MODEL,
            messages=[{"role": "user", "content": content}],
            response_format={"type": "json_object"},
        )
    except RateLimitError as e:
        logger.warning("OpenAI rate limit exceeded: %s", e)
        raise HTTPException(
            status_code=503,
            detail="AI service is temporarily unavailable due to high demand. Please try again in a few minutes.",
        ) from e
    except OpenAIError as e:
        logger.error("OpenAI API error: %s", e)
        raise HTTPException(status_code=503, detail="AI service is temporarily unavailable.") from e

    raw_text = response.choices[0].message.content or ""
    text = _strip_json_fences(raw_text)
    try:
        return json.loads(text), raw_text
    except json.JSONDecodeError as je:
        logger.error("JSON parse error: %s | raw=%s", je, raw_text[:500])
        raise HTTPException(
            status_code=422,
            detail="AI could not parse the food data. Please try again.",
        ) from je


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
    request: Request,
    file: UploadFile = File(...),
    local_date: Optional[str] = Query(None, description="User's local date YYYY-MM-DD"),
    current_user_id: str = Depends(get_current_user_id),
):
    try:
        # Read image
        contents = await file.read()
        Image.open(io.BytesIO(contents))  # validate image
        
        # Proper prompt asking for strict JSON
        prompt = """
        You are a nutrition estimation expert analyzing a food photo for a calorie-tracking app.

TASK:
1. Identify the overarching meal/dish shown in the image.
2. Break it down into 3–8 individual visible ingredients or components.
3. Estimate realistic portion sizes based on visual cues (plate size, utensils, hand/reference objects if visible).
4. Estimate calories and macros per ingredient, then sum them for the total (do not estimate the total independently — it must equal the sum of ingredient calories, within rounding).

RULES:
- Base portion estimates on what is visibly on the plate, not a "standard serving."
- If the image is ambiguous (multiple items, partially hidden food, unclear cooking method), make your best single estimate — do not ask for clarification or hedge.
- If the image contains no food, or is too unclear to analyze, return {"error": "no_food_detected"} instead of the schema below.
- Use standard household units for amounts (cups, tbsp, oz, g, pieces) — pick whichever is most natural for that ingredient.
- Round calories to the nearest 5, protein/carbs/fat to the nearest 1g.
- Provide translations that are natural/commonly used food terms in each language, not literal word-for-word translations.

OUTPUT FORMAT:
Respond with ONLY a raw JSON object. No markdown, no code fences, no backticks, no explanations, no text before or after the JSON.

Schema:
{"name_en": "Food Name English", "name_fr": "Nom de l'aliment en français", "name_ar": "اسم الطعام بالعربية", "calories": 500, "protein": 20, "carbs": 50, "fat": 15, "ingredients": [{"name": "Ingredient", "amount": "1.5 cups", "calories": 45, "protein": 3, "carbs": 5, "fat": 1}, {"name": "Ingredient 2", "amount": "2 tbsp", "calories": 60, "protein": 1, "carbs": 2, "fat": 6}]}
        """

        mime_type = file.content_type or "image/jpeg"
        logger.info(f"Calling OpenAI vision for user {current_user_id}")
        data, raw_text = _generate_food_json(prompt, image_bytes=contents, mime_type=mime_type)
        
        # Upload to S3 (non-fatal — if it fails we just skip the image URL)
        s3_url = None
        try:
            from s3_utils import upload_image_to_s3_key
            logger.info(f"Uploading vision scan image to S3 for user {current_user_id}")
            # Store the stable S3 key; presigned URLs are generated on read
            # so food images never expire or vanish on redeploy.
            s3_url = upload_image_to_s3_key(contents, file.content_type or 'image/jpeg', prefix="food_logs/")
        except Exception as s3_err:
            logger.error(f"S3 upload error in vision scan: {s3_err}")
        
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
            
            logger.info(f"Created FoodLog {log.id} for user {current_user_id}. S3 URL: {s3_url}")

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
            
            # Capture data while session is still active
            log_id = log.id
            log_created_at = log.created_at.isoformat() + "Z"

        # Invalidate Redis cache so next stats call is fresh
        try:
            from redis_client import redis_db
            redis_db.delete(f"stats_{current_user_id}")
            redis_db.delete(f"stats_{current_user_id}_{today.isoformat()}")
            redis_db.delete(f"stats_{current_user_id}_latest")
        except Exception:
            pass

        from s3_utils import resolve_media_url
        data['image_url'] = resolve_media_url(s3_url)
        if s3_url and s3_url.startswith('/'):
            # Convert relative path to absolute URL
            base_url = str(request.base_url).rstrip('/')
            data['image_url'] = f"{base_url}{s3_url}"

        data['log_id'] = log_id
        data['created_at'] = log_created_at
        return data
        
    except HTTPException:
        raise
    except Exception as e:
        print(f"Error analyzing image: {e}")
        raise HTTPException(status_code=500, detail=f"Analysis failed: {str(e)}")


class TextQuery(BaseModel):
    query: str

@router.post("/analyze/text")
async def analyze_food_text(body: TextQuery, current_user_id: str = Depends(get_current_user_id)):
    try:
        prompt = f"""
        Estimate the nutritional macros for the following food item or meal description: "{body.query}"
        Respond ONLY with a JSON object. No markdown formatting, no backticks, no explanations. 
        Format strictly like this:
        {{"name_en": "Food Name English", "name_fr": "Nom de l'aliment en français", "name_ar": "اسم الطعام بالعربية", "calories": 500, "protein": 20, "carbs": 50, "fat": 15}}
        """
        
        logger.info(f"Calling OpenAI text analysis for user {current_user_id}: {body.query!r}")
        data, raw_text = _generate_food_json(prompt)
        
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
        
    except HTTPException:
        raise
    except Exception as e:
        print(f"Error analyzing text: {e}")
        raise HTTPException(status_code=500, detail=str(e))


class FixRequest(BaseModel):
    log_id: str
    prompt: str

@router.post("/analyze/fix")
async def fix_food_log(body: FixRequest, current_user_id: str = Depends(get_current_user_id)):
    from models import FoodLog, DailyStats
    from database import get_db
    
    try:
        with next(get_db()) as db:
            log = db.query(FoodLog).filter(FoodLog.id == body.log_id, FoodLog.user_id == current_user_id).first()
            if not log:
                raise HTTPException(status_code=404, detail="Food log not found.")
            
            old_data = {
                "name_en": log.name_en,
                "name_fr": log.name_fr,
                "name_ar": log.name_ar,
                "calories": log.calories,
                "protein": log.protein,
                "carbs": log.carbs,
                "fat": log.fat,
                "ingredients": log.ingredients
            }
            
            prompt = f"""
            Here is the current JSON data for a food log:
            {json.dumps(old_data)}
            
            The user wants to fix or adjust it with this instruction: "{body.prompt}"
            
            Update the nutritional macros and ingredients accordingly.
            Respond ONLY with a JSON object. No markdown formatting, no backticks.
            Format strictly like this:
            {{"name_en": "...", "name_fr": "...", "name_ar": "...", "calories": 500, "protein": 20, "carbs": 50, "fat": 15, "ingredients": [...]}}
            """
            
            data, raw_text = _generate_food_json(prompt)
            
            diff_cal = int(data.get('calories', 0)) - log.calories
            diff_pro = int(data.get('protein', 0)) - log.protein
            diff_carbs = int(data.get('carbs', 0)) - log.carbs
            diff_fat = int(data.get('fat', 0)) - log.fat
            
            log.name = data.get('name_en', log.name)
            log.name_en = data.get('name_en')
            log.name_fr = data.get('name_fr')
            log.name_ar = data.get('name_ar')
            log.calories = int(data.get('calories', 0))
            log.protein = int(data.get('protein', 0))
            log.carbs = int(data.get('carbs', 0))
            log.fat = int(data.get('fat', 0))
            log.ingredients = data.get('ingredients')
            
            # Update stats
            log_date = log.created_at.date()
            stat = db.query(DailyStats).filter(
                DailyStats.user_id == current_user_id,
                DailyStats.date >= datetime.datetime.combine(log_date, datetime.time.min),
                DailyStats.date < datetime.datetime.combine(log_date + datetime.timedelta(days=1), datetime.time.min),
            ).first()
            
            if stat:
                stat.calories_consumed += diff_cal
                stat.protein_consumed += diff_pro
                stat.carbs_consumed += diff_carbs
                stat.fat_consumed += diff_fat
                
            db.commit()
            
            # Invalidate Redis cache
            try:
                from redis_client import redis_db
                redis_db.delete(f"stats_{current_user_id}")
                redis_db.delete(f"stats_{current_user_id}_{log_date.isoformat()}")
                redis_db.delete(f"stats_{current_user_id}_latest")
            except Exception:
                pass
            
            from s3_utils import resolve_media_url
            data['log_id'] = log.id
            data['image_url'] = resolve_media_url(log.image_url)
            data['created_at'] = log.created_at.isoformat() + "Z"
            return data
            
    except HTTPException:
        raise
    except Exception as e:
        print(f"Error fixing log: {e}")
        raise HTTPException(status_code=500, detail=str(e))

class LogItemModel(BaseModel):
    name: str  # Primary name (usually English)
    name_en: Optional[str] = None
    name_fr: Optional[str] = None
    name_ar: Optional[str] = None
    image_url: Optional[str] = None
    ingredients: Optional[Any] = None
    calories: int
    protein: int
    carbs: int
    fat: int


@router.post("/analyze/log")
async def log_food_item(
    body: LogItemModel,
    local_date: Optional[str] = Query(None, description="User's local date YYYY-MM-DD"),
    current_user_id: str = Depends(get_current_user_id),
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
                ingredients=body.ingredients,
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
async def get_barcode_nutrition(barcode: str, current_user_id: str = Depends(get_current_user_id)):
    """Fetches nutritional data for a given barcode from Open Food Facts."""
    import httpx
    
    url = f"https://world.openfoodfacts.org/api/v2/product/{barcode}.json"
    
    try:
        headers = {
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36"
        }
        async with httpx.AsyncClient(headers=headers) as http:
            response = await http.get(url, timeout=10.0)
            
        if response.status_code != 200:
            raise HTTPException(status_code=502, detail="Failed to fetch data from nutrition provider.")
            
        product_data = response.json()
        if product_data.get('status') == 0 or 'product' not in product_data:
            raise HTTPException(status_code=404, detail="Product not found in barcode database.")
            
        product = product_data['product']
        nutriments = product.get('nutriments', {})
        
        def get_num(key: str) -> int:
            # Try to get 100g values first as they are most standard
            for suffix in ['_100g', '_serving', '_value', '']:
                k = f"{key}{suffix}"
                if k in nutriments:
                    try:
                        return int(round(float(nutriments[k])))
                    except (ValueError, TypeError):
                        pass
            return 0

        # Extract names in different languages
        name_en = product.get('product_name_en') or product.get('product_name')
        name_fr = product.get('product_name_fr') or product.get('product_name')
        name_ar = product.get('product_name_ar')
        brand = product.get('brands', '')
        
        # Fallback logic for name
        primary_name = name_en or name_fr or "Scanned Product"
        if brand and brand.lower() not in primary_name.lower():
            primary_name = f"{primary_name} ({brand})"

        calories = get_num('energy-kcal')
        if calories == 0:
            kj = get_num('energy-kj') or get_num('energy')
            if kj > 0:
                calories = int(round(kj / 4.184))

        # Better ingredients parsing
        ingredients_raw = product.get('ingredients_text_en') or product.get('ingredients_text_fr') or product.get('ingredients_text') or ""
        ingredients_list = []
        if ingredients_raw:
            # Simple cleaning and splitting
            cleaned = ingredients_raw.replace('(', ',').replace(')', ',').replace('[', ',').replace(']', ',').replace('*', '')
            parts = [p.strip() for p in cleaned.split(',') if p.strip() and len(p.strip()) > 1]
            # Deduplicate while preserving order
            seen = set()
            for p in parts:
                p_cap = p.capitalize()
                if p_cap not in seen:
                    ingredients_list.append({"name": p_cap, "amount": "", "calories": 0})
                    seen.add(p_cap)
                if len(ingredients_list) >= 15:
                    break

        # Robust image extraction
        image_url = (
            product.get('image_small_url') or 
            product.get('image_front_small_url') or 
            product.get('image_url') or
            product.get('image_front_url')
        )

        return {
            "name": primary_name,
            "name_en": name_en,
            "name_fr": name_fr,
            "name_ar": name_ar,
            "calories": calories,
            "protein": get_num('proteins'),
            "carbs": get_num('carbohydrates'),
            "fat": get_num('fat'),
            "brand": brand,
            "image_url": image_url,
            "ingredients": ingredients_list
        }
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Barcode lookup error: {e}")
        raise HTTPException(status_code=500, detail="Internal error during barcode lookup.")


@router.get("/ingredients/{food_name}")
async def get_food_ingredients(
    food_name: str,
    current_user_id: str = Depends(get_current_user_id),
):
    """Uses OpenAI to return a detailed ingredient breakdown for a given food item."""
    prompt = f"""
    For the food item "{food_name}", provide a detailed ingredient breakdown with estimated portion sizes and calories.
    Respond ONLY with a JSON object. No markdown, no backticks, no explanations.
    Format exactly like this:
    {{"ingredients": [{{"name": "Ingredient Name", "amount": "1.5 cups", "calories": 45}}, ...]}}
    Include 3 to 8 ingredients. Be realistic and specific.
    """

    try:
        data, _raw_text = _generate_food_json(prompt)
        return data
    except HTTPException:
        raise
    except Exception as e:
        logger.error("Ingredient lookup error: %s", e)
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/search")
async def search_food(query: str, current_user_id: str = Depends(get_current_user_id)):
    """Searches Open Food Facts for a given query (better for branded products with images)."""
    import httpx
    
    # Open Food Facts search API
    url = "https://world.openfoodfacts.org/cgi/search.pl"
    params = {
        "search_terms": query,
        "json": 1,
        "page_size": 20,
        # Requesting more fields to ensure we get ingredients and all possible images
        "fields": "product_name,product_name_en,product_name_fr,product_name_ar,brands,image_small_url,image_url,image_front_small_url,image_front_url,nutriments,id,code,ingredients_text,ingredients_text_en,ingredients_text_fr"
    }
    
    try:
        headers = {
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36"
        }
        async with httpx.AsyncClient(headers=headers) as http:
            response = await http.get(url, params=params, timeout=10.0)
            
        if response.status_code != 200:
            logger.warning(f"OFF Search failed with status {response.status_code}. Falling back to USDA.")
            return await _search_usda_fallback(query)
            
        data = response.json()
        products = data.get("products", [])
        
        results = []
        for p in products:
            nutriments = p.get('nutriments', {})
            
            def get_num(key: str) -> int:
                for suffix in ['_100g', '_serving', '_value', '']:
                    k = f"{key}{suffix}"
                    if k in nutriments:
                        try:
                            return int(round(float(nutriments[k])))
                        except (ValueError, TypeError):
                            pass
                return 0

            # Name logic
            name_en = p.get('product_name_en') or p.get('product_name')
            name_fr = p.get('product_name_fr')
            name_ar = p.get('product_name_ar')
            brand = p.get('brands', '')
            
            primary_name = name_en or name_fr or name_ar or "Unknown Product"
            if brand and brand.lower() not in primary_name.lower():
                primary_name = f"{primary_name} ({brand})"

            calories = get_num('energy-kcal')
            if calories == 0:
                kj = get_num('energy-kj') or get_num('energy')
                if kj > 0:
                    calories = int(round(kj / 4.184))

            # Robust image extraction
            image_url = (
                p.get('image_small_url') or 
                p.get('image_front_small_url') or 
                p.get('image_url') or
                p.get('image_front_url')
            )

            # Ingredients extraction
            ingredients = (
                p.get('ingredients_text_en') or 
                p.get('ingredients_text') or 
                p.get('ingredients_text_fr') or
                ""
            )

            results.append({
                "name": primary_name.title(),
                "name_en": name_en,
                "name_fr": name_fr,
                "name_ar": name_ar,
                "brand": brand,
                "image_url": image_url,
                "ingredients": ingredients,
                "calories": calories,
                "protein": get_num('proteins'),
                "carbs": get_num('carbohydrates'),
                "fat": get_num('fat'),
                "serving_size": "100 g"
            })
            
        return {"results": results}
    except Exception as e:
        logger.error(f"OFF search error: {e}")
        # Final fallback
        return await _search_usda_fallback(query)

async def _search_usda_fallback(query: str):
    """Fallback to USDA FDC if Open Food Facts fails."""
    import httpx
    if not _FOODDATA_API_KEY:
        return {"results": []}
    
    url = "https://api.nal.usda.gov/fdc/v1/foods/search"
    params = {"api_key": _FOODDATA_API_KEY, "query": query, "pageSize": 10}
    
    try:
        async with httpx.AsyncClient() as http:
            response = await http.get(url, params=params, timeout=5.0)
        if response.status_code != 200:
            return {"results": []}
            
        data = response.json()
        results = []
        for f in data.get("foods", []):
            nutrients = f.get("foodNutrients", [])
            def get_nut(id_str):
                for n in nutrients:
                    if str(n.get("nutrientNumber")) == id_str: return int(round(n.get("value", 0)))
                return 0
            results.append({
                "name": f.get("description", "Unknown").title(),
                "brand": f.get("brandOwner", ""),
                "calories": get_nut("1008"),
                "protein": get_nut("1003"),
                "carbs": get_nut("1005"),
                "fat": get_nut("1004"),
                "serving_size": "100 g"
            })
        return {"results": results}
    except Exception:
        return {"results": []}

@router.get("/saved")
async def get_saved_foods(
    current_user_id: str = Depends(get_current_user_id),
):
    """Returns the list of foods saved by the user to their library."""
    from models import SavedFood
    from database import get_db
    from sqlalchemy.orm import Session
    
    with next(get_db()) as db:
        foods = db.query(SavedFood).filter(SavedFood.user_id == current_user_id).order_by(SavedFood.created_at.desc()).all()
        res = []
        for f in foods:
            res.append({
                "id": f.id,
                "name": f.name,
                "name_en": f.name_en,
                "name_fr": f.name_fr,
                "name_ar": f.name_ar,
                "image_url": resolve_media_url(f.image_url),
                "calories": f.calories,
                "protein": f.protein,
                "carbs": f.carbs,
                "fat": f.fat,
                "ingredients": f.ingredients,
                "created_at": f.created_at.isoformat() if f.created_at else None
            })
        return res

@router.post("/saved")
async def save_food_item(
    body: LogItemModel,
    current_user_id: str = Depends(get_current_user_id),
):
    """Saves a food item to the user's personal library."""
    from models import SavedFood
    from database import get_db
    
    with next(get_db()) as db:
        # Check if already exists to avoid duplicates (optional, based on name and macros)
        # For now, just allow saving.
        saved = SavedFood(
            user_id=current_user_id,
            name=body.name,
            name_en=body.name_en or body.name,
            name_fr=body.name_fr,
            name_ar=body.name_ar,
            image_url=body.image_url,
            ingredients=body.ingredients,
            calories=body.calories,
            protein=body.protein,
            carbs=body.carbs,
            fat=body.fat,
        )
        db.add(saved)
        db.commit()
        return {"status": "success", "id": saved.id}

@router.delete("/saved/{food_id}")
async def delete_saved_food(
    food_id: str,
    current_user_id: str = Depends(get_current_user_id),
):
    """Removes a food item from the user's personal library."""
    from models import SavedFood
    from database import get_db
    
    with next(get_db()) as db:
        food = db.query(SavedFood).filter(SavedFood.id == food_id, SavedFood.user_id == current_user_id).first()
        if not food:
            raise HTTPException(status_code=404, detail="Saved food not found.")
        db.delete(food)
        db.commit()
        return {"status": "success"}

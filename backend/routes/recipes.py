from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from typing import List, Optional, Any
import datetime
from database import get_db
from models import Recipe
from security import get_current_user_id

router = APIRouter()

class RecipeCreate(BaseModel):
    name: str
    ingredients: list
    instructions: Optional[str] = None
    is_public: bool = False

class RecipeResponse(BaseModel):
    id: str
    user_id: str
    name: str
    ingredients: list
    instructions: Optional[str]
    is_public: bool
    created_at: datetime.datetime

@router.post("/", response_model=RecipeResponse)
def create_recipe(recipe: RecipeCreate, current_user_id: str = Depends(get_current_user_id)):
    with next(get_db()) as db:
        new_recipe = Recipe(
            user_id=current_user_id,
            name=recipe.name,
            ingredients=recipe.ingredients,
            instructions=recipe.instructions,
            is_public=recipe.is_public
        )
        db.add(new_recipe)
        db.commit()
        db.refresh(new_recipe)
        return new_recipe

@router.get("/my", response_model=List[RecipeResponse])
def get_my_recipes(current_user_id: str = Depends(get_current_user_id)):
    with next(get_db()) as db:
        recipes = db.query(Recipe).filter(Recipe.user_id == current_user_id).order_by(Recipe.created_at.desc()).all()
        return recipes

@router.get("/public", response_model=List[RecipeResponse])
def get_public_recipes():
    with next(get_db()) as db:
        recipes = db.query(Recipe).filter(Recipe.is_public == True).order_by(Recipe.created_at.desc()).all()
        return recipes

@router.delete("/{recipe_id}")
def delete_recipe(recipe_id: str, current_user_id: str = Depends(get_current_user_id)):
    with next(get_db()) as db:
        recipe = db.query(Recipe).filter(Recipe.id == recipe_id, Recipe.user_id == current_user_id).first()
        if not recipe:
            raise HTTPException(status_code=404, detail="Recipe not found")
        db.delete(recipe)
        db.commit()
        return {"status": "success"}

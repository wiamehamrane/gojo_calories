from typing import Optional

def calculate_daily_targets(
    weight_kg: float,
    height_cm: float,
    age: int,
    gender: str,
    activity_level: str,
    goal_weight_kg: float
):
    """
    Calculates calorie budget and macro targets using Mifflin-St Jeor equation.
    
    gender: "male" | "female"
    activity_level: "sedentary" | "light" | "moderate" | "active" | "very_active"
    """
    # 1. BMR (Basal Metabolic Rate)
    # Men: (10 × weight) + (6.25 × height) - (5 × age) + 5
    # Women: (10 × weight) + (6.25 × height) - (5 × age) - 161
    bmr = (10 * weight_kg) + (6.25 * height_cm) - (5 * age)
    if gender.lower() == "female":
        bmr -= 161
    else:
        bmr += 5
        
    # 2. TDEE (Total Daily Energy Expenditure)
    multipliers = {
        "sedentary": 1.2,
        "light": 1.375,
        "moderate": 1.55,
        "active": 1.725,
        "very_active": 1.9
    }
    multiplier = multipliers.get(activity_level.lower(), 1.2)
    tdee = bmr * multiplier
    
    # 3. Goal Adjustment
    calorie_budget = int(tdee)
    if goal_weight_kg < weight_kg - 1.0:
        calorie_budget -= 500  # Cut
    elif goal_weight_kg > weight_kg + 1.0:
        calorie_budget += 500  # Bulk
        
    # 4. Macros
    # Protein: 2.0g per kg of body weight
    protein_target = int(weight_kg * 2.0)
    # Fat: 25% of calorie budget
    fat_target = int((calorie_budget * 0.25) / 9)
    # Carbs: Remainder
    carbs_target = int((calorie_budget - (protein_target * 4) - (fat_target * 9)) / 4)
    if carbs_target < 0:
        carbs_target = 0
        
    return {
        "calorie_budget": calorie_budget,
        "protein_target": protein_target,
        "carbs_target": carbs_target,
        "fat_target": fat_target
    }

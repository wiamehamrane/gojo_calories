import httpx
import asyncio
import json

async def test_barcode(barcode):
    url = f"https://world.openfoodfacts.org/api/v2/product/{barcode}.json"
    async with httpx.AsyncClient() as client:
        response = await client.get(url)
        data = response.json()
        
    product = data.get('product', {})
    if not product:
        print(f"Barcode {barcode} NOT FOUND")
        return

    nutriments = product.get('nutriments', {})
    
    def get_num(key):
        for suffix in ['_100g', '_serving', '_value', '']:
            k = f"{key}{suffix}"
            if k in nutriments:
                return nutriments[k]
        return 0

    name_en = product.get('product_name_en') or product.get('product_name')
    name_fr = product.get('product_name_fr') or product.get('product_name')
    name_ar = product.get('product_name_ar')
    
    if not name_en and not name_fr:
        print(f"Available keys for {barcode}: {list(product.keys())[:20]}")

    print(f"Barcode: {barcode}")
    print(f"Name EN: {name_en}")
    print(f"Name FR: {name_fr}")
    print(f"Name AR: {name_ar}")
    print(f"Calories: {get_num('energy-kcal')}")
    print(f"Proteins: {get_num('proteins')}")
    print(f"Carbs: {get_num('carbohydrates')}")
    print(f"Fat: {get_num('fat')}")
    print(f"Image: {product.get('image_front_url') or product.get('image_url')}")

if __name__ == "__main__":
    # Nutella
    asyncio.run(test_barcode("3017620422003"))
    # Another product (Evian)
    asyncio.run(test_barcode("3068320115033"))

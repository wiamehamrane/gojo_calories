import requests

url = "http://127.0.0.1:5000/api/food/analyze"
with open("test.jpg", "wb") as f:
    f.write(requests.get("https://picsum.photos/200").content)
    
with open("test.jpg", "rb") as f:
    files = {"file": f}
    response = requests.post(url, files=files)
    print(response.json())

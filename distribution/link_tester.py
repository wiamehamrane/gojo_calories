import csv
import requests
import re

def check_url(url):
    if not url or url.strip() == '':
        return "Empty"
    
    if not url.startswith('http'):
        url = 'https://' + url
        
    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/115.0.0.0 Safari/537.36',
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
        'Accept-Language': 'en-US,en;q=0.5',
    }
    
    try:
        response = requests.get(url, headers=headers, timeout=10, allow_redirects=True)
        if response.status_code < 400:
            return f"Working ({response.status_code})"
        elif response.status_code == 403 or response.status_code == 429:
             # Some sites block bots with 403 or rate limit
             return f"Blocked ({response.status_code})"
        else:
            return f"Failed ({response.status_code})"
    except requests.exceptions.RequestException as e:
        return f"Error ({type(e).__name__})"

def check_email(email):
    if not email or email.strip() == '':
        return "Empty"
    regex = r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,7}\b'
    if re.fullmatch(regex, email.strip()):
        return "Valid format"
    else:
        return "Invalid format"

def test_file(file_path, num_rows=5):
    print(f"Testing {file_path} (First {num_rows} rows)")
    with open(file_path, mode='r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for i, row in enumerate(reader):
            if i >= num_rows:
                break
            
            website = row.get('Website', '')
            facebook = row.get('Facebook', '')
            instagram = row.get('Instagram', '')
            twitter = row.get('Twitter', '')
            email = row.get('Email', '')
            
            print(f"--- Row {i+1}: {row.get('Business Name', 'Unknown')} ---")
            if website: print(f"  Website: {website} -> {check_url(website)}")
            if facebook: print(f"  Facebook: {facebook} -> {check_url(facebook)}")
            if instagram: print(f"  Instagram: {instagram} -> {check_url(instagram)}")
            if twitter: print(f"  Twitter: {twitter} -> {check_url(twitter)}")
            if email: print(f"  Email: {email} -> {check_email(email)}")

if __name__ == "__main__":
    test_file_path = "/home/zelghourfi/Downloads/10k Leads - Fitness.csv"
    test_file(test_file_path, num_rows=5)

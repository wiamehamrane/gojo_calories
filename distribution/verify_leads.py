import csv
import requests
import re
import concurrent.futures
import time
import argparse
import sys
import os

from requests.adapters import HTTPAdapter
from requests.packages.urllib3.util.retry import Retry

def get_session():
    # Setup connection pooling and retries
    session = requests.Session()
    retry = Retry(connect=3, backoff_factor=0.5)
    adapter = HTTPAdapter(max_retries=retry, pool_connections=50, pool_maxsize=50)
    session.mount('http://', adapter)
    session.mount('https://', adapter)
    session.headers.update({
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/115.0.0.0 Safari/537.36',
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
        'Accept-Language': 'en-US,en;q=0.5',
    })
    return session

def check_url(session, url, platform=""):
    if not url or url.strip() == '':
        return "Empty"
    
    url = url.strip()
    if not url.startswith('http'):
        url = 'https://' + url
        
    try:
        response = session.get(url, timeout=15, allow_redirects=True)
        code = response.status_code
        if code < 400:
            return f"Working ({code})"
        elif code in [403, 429]:
            return f"Blocked ({code})"
        elif code == 400 and (platform == 'facebook' or 'facebook.com' in url):
            return f"Blocked by Facebook ({code})"
        else:
            return f"Failed ({code})"
    except requests.exceptions.Timeout:
        return "Timeout"
    except requests.exceptions.ConnectionError:
        return "Connection Error"
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

def process_row_task(index, row, session):
    website = row.get('Website', '')
    facebook = row.get('Facebook', '')
    instagram = row.get('Instagram', '')
    twitter = row.get('Twitter', '')
    email = row.get('Email', '')
    
    row['Website Status'] = check_url(session, website)
    row['Facebook Status'] = check_url(session, facebook, 'facebook')
    row['Instagram Status'] = check_url(session, instagram)
    row['Twitter Status'] = check_url(session, twitter)
    row['Email Status'] = check_email(email)
    
    return index, row

def main():
    parser = argparse.ArgumentParser(description="Verify links in Lead CSV files")
    parser.add_argument("input_csv", help="Path to input CSV file")
    parser.add_argument("--output", help="Path to output CSV file", default="")
    parser.add_argument("--test", type=int, help="Number of rows to test", default=0)
    parser.add_argument("--workers", type=int, help="Number of concurrent workers", default=10)
    args = parser.parse_args()
    
    input_file = args.input_csv
    if not os.path.exists(input_file):
        print(f"Error: Input file '{input_file}' not found.")
        sys.exit(1)
        
    output_file = args.output
    if not output_file:
        base, ext = os.path.splitext(input_file)
        output_file = f"{base}_verified{ext}"
        
    print(f"Reading from {input_file}")
    print(f"Writing to {output_file}")
    
    rows = []
    fieldnames = []
    with open(input_file, mode='r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        fieldnames = reader.fieldnames + ['Website Status', 'Facebook Status', 'Instagram Status', 'Twitter Status', 'Email Status']
        for i, row in enumerate(reader):
            if args.test and i >= args.test:
                break
            rows.append(row)
            
    total_rows = len(rows)
    print(f"Processing {total_rows} rows with {args.workers} concurrent workers...")
    
    session = get_session()
    
    processed_results = []
    start_time = time.time()
    
    with concurrent.futures.ThreadPoolExecutor(max_workers=args.workers) as executor:
        futures = {executor.submit(process_row_task, i, row, session): i for i, row in enumerate(rows)}
        
        completed = 0
        for future in concurrent.futures.as_completed(futures):
            processed_results.append(future.result())
            completed += 1
            if completed % 10 == 0 or completed == total_rows:
                elapsed = time.time() - start_time
                rate = completed / elapsed
                print(f"Completed {completed}/{total_rows} ({rate:.1f} rows/sec)")
                
    # Sort results to maintain original row order
    processed_results.sort(key=lambda x: x[0])
    ordered_rows = [res[1] for res in processed_results]
    
    with open(output_file, mode='w', encoding='utf-8', newline='') as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(ordered_rows)
        
    print(f"Finished! Results saved to {output_file}")

if __name__ == "__main__":
    main()

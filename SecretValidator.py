import asyncio
import aiohttp
import aiofiles
import re
import argparse
import os
from datetime import datetime
from tqdm.asyncio import tqdm_asyncio

# Regex patterns based on justsecrets.txt
SECRET_PATTERNS = {
    'heroku': r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    'square_access_token': r'^EAAA[0-9A-Za-z_-]{60,}$',
    'stripe': r'^sk_live_[0-9A-Za-z]{24,}$',
    'google_api': r'^AIzaSy[0-9A-Za-z_-]{33}$',
    'possible_creds': r'(?i)(?:password|api_key|token|key)[=:]([0-9A-Za-z_-]{20,})'
}

# API endpoints and headers
SERVICE_APIS = {
    'heroku': {
        'url': 'https://api.heroku.com/account',
        'headers': lambda key: {
            'Authorization': f'Bearer {key}',
            'Accept': 'application/vnd.heroku+json; version=3',
            'User-Agent': 'SecretValidator/1.0'
        }
    },
    'square_access_token': {
        'url': 'https://connect.squareup.com/v2/locations',
        'headers': lambda key: {
            'Authorization': f'Bearer {key}',
            'User-Agent': 'SecretValidator/1.0'
        }
    },
    'stripe': {
        'url': 'https://api.stripe.com/v1/charges',
        'headers': lambda key: {
            'Authorization': f'Bearer {key}',
            'User-Agent': 'SecretValidator/1.0'
        }
    },
    'google_api': {
        'url': 'https://maps.googleapis.com/maps/api/geocode/json?address=1600+Amphitheatre+Parkway,+Mountain+View,+CA&key={key}',
        'headers': lambda key: {'User-Agent': 'SecretValidator/1.0'}
    }
}

# Filter out obvious test/dummy keys
INVALID_PATTERNS = [
    r'^0{8}-0{4}-0{4}-0{4}-0{12}$', 
    r'^f{8}-f{4}-f{4}-f{4}-f{12}$', 
    r'^EAAA[0A]{60,}$'  
]

async def test_key(session, key, service, semaphore, output_files, log_file, valid_counts, tested_counts, log_level):
    async with semaphore:
        try:
            api_config = SERVICE_APIS.get(service, {})
            if not api_config:
                if log_level in ['ERROR', 'DEBUG']:
                    async with aiofiles.open(log_file, 'a') as f:
                        await f.write(f"[{datetime.now()}] [ERROR] No API config for service: {service}\n")
                return

            url = api_config['url'].format(key=key) if '{key}' in api_config['url'] else api_config['url']
            headers = api_config['headers'](key.strip())

            async with session.get(url, headers=headers, timeout=15) as response:
                tested_counts[service] += 1
                if 200 <= response.status < 300:
                    result = await response.json()
                    if service == 'google_api' and 'error_message' in result:
                        if log_level in ['INFO', 'DEBUG']:
                            async with aiofiles.open(log_file, 'a') as f:
                                await f.write(f"[{datetime.now()}] [-] Invalid {service} key: {key} | Error: {result['error_message']}\n")
                        return
                    valid_counts[service] += 1
                    print(f"[+] Valid {service} key: {key}")
                    print(result)
                    async with aiofiles.open(output_files[service], 'a') as f:
                        await f.write(f"{key}\n")
                else:
                    if log_level in ['INFO', 'DEBUG']:
                        async with aiofiles.open(log_file, 'a') as f:
                            await f.write(f"[{datetime.now()}] [-] Invalid {service} key: {key} | Status: {response.status}\n")
        except Exception as e:
            if log_level in ['ERROR', 'DEBUG']:
                async with aiofiles.open(log_file, 'a') as f:
                    await f.write(f"[{datetime.now()}] [ERROR] {service} key: {key} | Error: {str(e)}\n")

async def validate_secrets(input_file, output_dir, max_concurrent=10, log_level='INFO'):
    os.makedirs(output_dir, exist_ok=True)
    log_file = os.path.join(output_dir, 'secret_validator.log')
    output_files = {service: os.path.join(output_dir, f'valid_{service}.txt') for service in SERVICE_APIS}
    valid_counts = {service: 0 for service in SERVICE_APIS}
    tested_counts = {service: 0 for service in SERVICE_APIS}

    # Initialize output files
    for file in output_files.values():
        async with aiofiles.open(file, 'a'):
            pass

    # Read secrets
    try:
        async with aiofiles.open(input_file, 'r', encoding='utf-8') as f:
            lines = [line async for line in f]
        if log_level in ['INFO', 'DEBUG']:
            print(f"[DEBUG] Read {len(lines)} lines from {input_file}")
        secrets = []
        secret_types = {}
        for line in lines:
            line = line.strip()
            if not line:
                continue
            # Handle tab or ' -> ' delimiters
            if '\t->\t' in line:
                parts = line.split('\t->\t')
                secret_type, secret = parts[0], parts[-1]
            elif ' -> ' in line:
                parts = line.split(' -> ')
                secret_type, secret = parts[0], parts[-1]
            else:
                continue
            # Skip obvious test keys
            if any(re.fullmatch(pattern, secret) for pattern in INVALID_PATTERNS):
                if log_level in ['INFO', 'DEBUG']:
                    async with aiofiles.open(log_file, 'a') as f:
                        await f.write(f"[{datetime.now()}] [INFO] Skipped test key: {secret_type} -> {secret}\n")
                continue
            secrets.append(secret)
            secret_types[secret] = secret_type
        if log_level in ['INFO', 'DEBUG']:
            print(f"[INFO] Loaded {len(secrets)} secrets from {input_file}")
    except FileNotFoundError:
        print(f"[ERROR] File '{input_file}' not found.")
        return
    except Exception as e:
        print(f"[ERROR] Reading {input_file}: {str(e)}")
        return

    # Deduplicate secrets
    unique_secrets = list(dict.fromkeys(secrets))
    if log_level in ['INFO', 'DEBUG']:
        print(f"[INFO] Deduplicated to {len(unique_secrets)} unique secrets")

    semaphore = asyncio.Semaphore(max_concurrent)
    async with aiohttp.ClientSession() as session:
        tasks = []
        unmatched = []
        for key in unique_secrets:
            matched = False
            for service, pattern in SECRET_PATTERNS.items():
                match = re.fullmatch(pattern, key)
                if match or (service == 'possible_creds' and re.search(pattern, key, re.IGNORECASE)):
                    if log_level in ['INFO', 'DEBUG']:
                        print(f"[DEBUG] Testing key: {key} for service: {service}")
                    tasks.append(test_key(session, key, service, semaphore, output_files, log_file, valid_counts, tested_counts, log_level))
                    matched = True
            if not matched:
                unmatched.append((secret_types.get(key, 'unknown'), key))
        if unmatched and log_level in ['INFO', 'DEBUG']:
            async with aiofiles.open(log_file, 'a') as f:
                for secret_type, key in unmatched:
                    await f.write(f"[{datetime.now()}] [INFO] Unmatched secret: {secret_type} -> {key}\n")

        # Run tasks with progress bar
        await tqdm_asyncio.gather(*tasks, desc="Validating secrets")

    # Print summary
    print("\n[SUMMARY]")
    for service in SERVICE_APIS:
        print(f"{service}: {valid_counts[service]} valid keys (tested {tested_counts[service]})")
    print(f"Unmatched secrets: {len(unmatched)}")

    # Suggest manual validation for promising unmatched secrets
    if unmatched and log_level in ['INFO', 'DEBUG']:
        promising = [(t, k) for t, k in unmatched if 'ksQHNbojQ2skuAUXK6CvNzUnZQTMdU2F' in k]
        if promising:
            print("\n[PROMISING UNMATCHED SECRETS]")
            for secret_type, key in promising:
                print(f"{secret_type} -> {key}")

def main():
    parser = argparse.ArgumentParser(description="Validate secrets from a file against multiple APIs.")
    parser.add_argument('-i', '--input', required=True, help="File containing secrets (one per line)")
    parser.add_argument('-o', '--output-dir', default='results', help="Directory to store valid secret files")
    parser.add_argument('-r', '--rate', type=int, default=10, help="Maximum concurrent requests")
    parser.add_argument('--log-level', choices=['DEBUG', 'INFO', 'ERROR'], default='INFO', help="Logging level")
    args = parser.parse_args()

    asyncio.run(validate_secrets(args.input, args.output_dir, args.rate, args.log_level))

if __name__ == "__main__":
    main()

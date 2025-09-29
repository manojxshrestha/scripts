import requests
import os

# Ask the user to enter the input file path
file_path = input("Enter the path containing JS links: ").strip()

# Check if the file exists
if not os.path.isfile(file_path):
    print(f"[!] File not found: {file_path}")
    exit(1)

# Create output directory
os.makedirs("js_files", exist_ok=True)

# Process the file
with open(file_path, "r", encoding="utf-8") as f:
    for i, url in enumerate(f):
        url = url.strip()
        if not url:
            continue  
        try:
            res = requests.get(url, timeout=10)
            res.raise_for_status()  
            with open(f"js_files/js_{i}.js", "w", encoding="utf-8") as f_out:
                f_out.write(res.text)
            print(f"[+] Saved: {url}")
        except Exception as e:
            print(f"[-] Failed: {url} | {e}")

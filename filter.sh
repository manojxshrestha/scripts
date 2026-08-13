#!/bin/bash
input_file="merged-crawl.txt"
temp_file="temp-crawledurls.txt"
output_file="crawledurls.txt"
param_file="param-urls.txt"

# Check if input file exists
if [ ! -f "$input_file" ]; then
    echo "Error: Input file '$input_file' not found in the current directory."
    exit 1
fi

# Prompt user for domain
read -p "Enter domain to filter (e.g., example.com): " domain

if [ -z "$domain" ]; then
    echo "No domain entered. Exiting."
    exit 1
fi

# Escape dots for regex
escaped_domain=$(printf '%s\n' "$domain" | sed 's/\./\\./g')

# Step 1: Filter domain URLs to temp file
grep -E -i "https?://([a-zA-Z0-9.-]+\.)?$escaped_domain([/:?#]|$)" "$input_file" | sort -u > "$temp_file"
echo "[*] Domain-filtered URLs: $(wc -l < "$temp_file")"

# Step 2: Liveness check — KEEP original URLs (no redirect following),
#         KEEP WAF/403/401/429/5xx as alive, DROP only 404s and connection errors (via -fc 404,000).
httpx -silent \
  -no-color \
  -threads 100 \
  -timeout 15 \
  -retries 2 \
  -fc 404,000 \
  -sc -cl < "$temp_file" | awk '{print $1}' | sort -u > "$output_file"

echo "[+] Clean URLs saved to $output_file: $(wc -l < "$output_file")"

# Step 4: Extract param URLs in the same pass (the reason we fixed this)
grep "?" "$output_file" | grep -v '__cf_chl' | sort -u > "$param_file"
echo "[+] Param URLs (no __cf_chl noise) saved to $param_file: $(wc -l < "$param_file")"
echo ""

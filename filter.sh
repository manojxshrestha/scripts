#!/bin/bash

input_file="merged-crawl.txt"
temp_file="temp-crawledurls.txt"
output_file="crawledurls.txt"

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

echo "Filtered URLs saved to $temp_file"

# Step 2: Check liveness with all status codes + show status/size
httpx -silent -follow-redirects -no-color -threads 100 -timeout 5 -sc -cl < "$temp_file" > "${output_file}.tmp"

# Overwrite temp file with httpx results (has status + size for manual review)
mv "${output_file}.tmp" "$temp_file"

# Strip to just URLs for automation tools
awk '{print $1}' "$temp_file" > "$output_file"

echo "Detailed results (with status codes) saved to $temp_file"
echo "Clean URLs (for automation) saved to $output_file"

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

# Step 2: Check liveness and output only live URLs to final file
httpx -silent -follow-redirects -no-color -threads 100 -timeout 5 -mc 200,201,202,204,301,302,303,307,308 < "$temp_file" > "$output_file"

# Optional: remove temp file if you don't need it
# rm "$temp_file"

echo "Live URLs only saved to $output_file"

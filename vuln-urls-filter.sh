#!/bin/bash

input_file="livepaths.txt"
output_files=(
  "idorurls.txt"
  "sqliurls.txt"
  "xssurls.txt"
  "lfiurls.txt"
  "secretsurls.txt"
  "adminpanelsurls.txt"
)

# Check if input file exists
[ ! -f "$input_file" ] && { echo "Error: $input_file not found"; exit 1; }

# Clear output files
for file in "${output_files[@]}"; do
  > "$file"
done

# Filter URLs
grep -Eio 'https?://[^ ]*(id=|user_id=|groupId=|isAdmin=)[^ ]*' "$input_file" >> idorurls.txt
grep -Eio 'https?://[^ ]*(id=|itemid=|menuid=)[^ ]*' "$input_file" >> sqliurls.txt
grep -Eio 'https?://[^ ]*(menuid=|name=|search=|query=|q=|keyword=)[^ ]*' "$input_file" >> xssurls.txt
grep -Eio 'https?://[^ ]*(file=|path=|page=|template=|include=)[^ ]*' "$input_file" >> lfiurls.txt
grep -Eio 'https?://[^ ]*(\.env$|\.bak$|\.sql$|\.config$|\.conf$|/backup/|/database/|\.db$)[^ ]*' "$input_file" >> secretsurls.txt
grep -Eio 'https?://[^ ]*(/admin/|/login/|/dashboard/|/cp/|/controlpanel/|/wp-admin/)[^ ]*' "$input_file" >> adminpanelsurls.txt

# Print summary
echo "Filtering complete. Results:"
for file in "${output_files[@]}"; do
  count=$(wc -l < "$file")
  echo "$file: $count URLs"
done

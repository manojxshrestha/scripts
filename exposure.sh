#!/bin/bash

# Hidden API Discovery Script (IDOR/PII/Misconfig Scanner)
# Author: manojxshrestha

# Colors
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m'

# Prompt for domain
read -p "🔗 Enter the target domain (e.g. https://example.com or example.com): " domain
# Normalize domain input
domain=$(echo "$domain" | sed 's|https\?://||;s:/$::')  # Remove protocol and trailing slash
domain_host="$domain"
# Ensure domain_host is a valid domain
if [[ ! "$domain_host" =~ ^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
  echo -e "${RED}[!] Error: Invalid domain format. Please enter a valid domain (e.g., monash.edu).${NC}"
  exit 1
fi
domain=$(echo "https://$domain_host")  # Rebuild full domain with https
echo -e "${BLUE}[*] Using domain host: $domain_host${NC}"

# Output directory
RESULT_DIR="results"
mkdir -p "$RESULT_DIR"

# Output files (inside results/)
DOMAIN_URLS="$RESULT_DIR/domain-urls.txt" # All URLs for the target domain, excluding static file extensions
SUSPICIOUS_ENDPOINTS="$RESULT_DIR/suspicious-endpoints.txt" # Accessible URLs matching suspicious patterns (e.g., /api, .env, id=)
ABSOLUTE_URLS="$RESULT_DIR/absolute-urls.txt" #Same as suspicious-endpoints.txt but with relative paths converted to absolute URLs (typically identical)
MISCONFIG_VALID_ENDPOINTS="$RESULT_DIR/misconfig-valid-endpoints.txt" #Accessible URLs with HTTP status codes, for manual testing
POTENTIAL_VULN_URLS="$RESULT_DIR/potential-vuln-urls.txt" #Accessible URLs with their matched patterns, highlighting potential vulnerabilities

LINK_RESULTS="linkresults.txt"  # Source JS analysis file

# Check if linkresults.txt exists
if [ ! -f "$LINK_RESULTS" ]; then
  echo -e "${RED}[!] Error: $LINK_RESULTS not found. Please ensure the file exists.${NC}"
  exit 1
fi

# Clean up
rm -f "$DOMAIN_URLS" "$SUSPICIOUS_ENDPOINTS" "$ABSOLUTE_URLS" "$MISCONFIG_VALID_ENDPOINTS" "$POTENTIAL_VULN_URLS"

# File extensions to filter out
FILTER_EXTENSIONS="\.png|\.svg|\.jpg|\.jpeg|\.gif|\.css|\.js|\.woff|\.woff2|\.ttf|\.ico|\.pdf|\.txt|\.html|\.htm"
echo -e "${BLUE}[*] Filtering out URLs with extensions: .png, .svg, .jpg, .jpeg, .gif, .css, .js, .woff, .woff2, .ttf, .ico, .pdf, .txt, .html, .htm${NC}"

echo -e "${BLUE}[*] Extracting URLs for domain $domain_host from $LINK_RESULTS...${NC}"
# Extract URLs matching the target domain or its subdomains, excluding filtered extensions
grep -Eo "https?://([a-zA-Z0-9.-]+\.)*${domain_host}(:[0-9]+)?[^\"'[:space:]]*[^${FILTER_EXTENSIONS}]" "$LINK_RESULTS" > "$DOMAIN_URLS"
if [ ! -s "$DOMAIN_URLS" ]; then
  echo -e "${YELLOW}[!] Warning: No URLs matching $domain_host found in $LINK_RESULTS${NC}"
fi
sort -u "$DOMAIN_URLS" -o "$DOMAIN_URLS"
echo -e "${GREEN}[+] Saved extracted URLs to: $DOMAIN_URLS${NC}"

# Define suspicious path patterns (extended)
PATTERNS=(
  "/account" "/user" "/profile" "/admin" "/dashboard" "/panel" "/cp" "/controlpanel" "/wp-admin" "/adminer"
  "/subscribe" "/reset" "/validate" "/debug" "/test" "/api" "/internal" "/HelpApi"
  "/auth" "/login" "/logout" "/register" "/signup" "/forgot" "/change" "/settings"
  "/update" "/delete" "/remove" "/config" "/private" "/data" "/info" "/details"
  "/token" "/session" "/access" "/secure" "/vault"
  "\.env" "\.bak" "\.sql" "\.config" "\.conf" "backup" "config\." "database\." "db\."
  "phpinfo" "server-status" "info\.php"
  "[?&]id=" "[?&]user_id=" "[?&]isAdmin=" "[?&]menuid=" "[?&]groupId=" "[?&]file=" "[?&]path="
)

echo -e "${BLUE}[*] Filtering suspicious in-scope paths and parameters...${NC}"
: > "$SUSPICIOUS_ENDPOINTS"  # Clear the file
: > "$POTENTIAL_VULN_URLS"  # Clear the findings file
for pattern in "${PATTERNS[@]}"; do
  grep -i "$pattern" "$DOMAIN_URLS" >> "$SUSPICIOUS_ENDPOINTS"
  # Also extract to potential-vuln-urls.txt for specific matches
  grep -i "$pattern" "$DOMAIN_URLS" | awk -v pat="$pattern" '{print $0 " (Pattern: " pat ")"}' >> "$POTENTIAL_VULN_URLS"
done

# If no matches found, try expanded patterns
if [ ! -s "$SUSPICIOUS_ENDPOINTS" ]; then
  echo -e "${YELLOW}[!] No matches found for initial patterns. Trying expanded patterns (/v1, /v2, query=)...${NC}"
  EXPANDED_PATTERNS=("/v1" "/v2" "[?&]query=")
  for pattern in "${EXPANDED_PATTERNS[@]}"; do
    grep -i "$pattern" "$DOMAIN_URLS" >> "$SUSPICIOUS_ENDPOINTS"
    grep -i "$pattern" "$DOMAIN_URLS" | awk -v pat="$pattern" '{print $0 " (Pattern: " pat ")"}' >> "$POTENTIAL_VULN_URLS"
  done
fi

sort -u "$SUSPICIOUS_ENDPOINTS" -o "$SUSPICIOUS_ENDPOINTS"
echo -e "${GREEN}[+] Suspicious endpoints saved to: $SUSPICIOUS_ENDPOINTS${NC}"
if [ -s "$POTENTIAL_VULN_URLS" ]; then
  echo -e "${GREEN}[+] Potential vulnerable URLs with patterns saved to: $POTENTIAL_VULN_URLS${NC}"
else
  echo -e "${YELLOW}[!] No findings matched the patterns${NC}"
fi

echo -e "${BLUE}[*] Rebuilding full URLs if any are just relative paths...${NC}"
: > "$ABSOLUTE_URLS"  
while read -r line; do
  if [[ "$line" =~ ^https?:// ]]; then
    echo "$line" >> "$ABSOLUTE_URLS"
  else
    echo "$domain$line" >> "$ABSOLUTE_URLS"
  fi
done < "$SUSPICIOUS_ENDPOINTS"

sort -u "$ABSOLUTE_URLS" -o "$ABSOLUTE_URLS"
echo -e "${GREEN}[+] Absolute URLs saved to: $ABSOLUTE_URLS${NC}"

echo -e "${BLUE}[*] Checking which URLs are alive (using httpx)...${NC}"
if ! command -v httpx >/dev/null 2>&1; then
  echo -e "${RED}[!] Error: httpx is not installed. Please install httpx to proceed.${NC}"
  exit 1
fi
if [ -s "$ABSOLUTE_URLS" ]; then
  cat "$ABSOLUTE_URLS" | httpx -silent -status-code -mc 200,403,401,500 -rl 10 > "$MISCONFIG_VALID_ENDPOINTS"
  echo -e "${GREEN}[✓] Live/valid endpoints saved to: $MISCONFIG_VALID_ENDPOINTS${NC}"
else
  echo -e "${YELLOW}[!] Warning: No URLs to check with httpx (empty $ABSOLUTE_URLS)${NC}"
fi
echo -e "${YELLOW}[🔥] Review $POTENTIAL_VULN_URLS and $MISCONFIG_VALID_ENDPOINTS for IDOR, PII, or debug exposure!${NC}"

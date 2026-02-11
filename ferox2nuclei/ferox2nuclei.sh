#!/bin/bash
# Feroxbuster Results Processor & Nuclei Automation
# Created for CTF/Hackathon automation
# Version: 3.0 - Auto-detection of ferox files

# Get script directory (works from any location)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Feroxbuster Results Processor${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Function to find ferox files
detect_ferox_files() {
    local search_dir="$1"
    local found=0
    
    for file in "ferox-graphql.txt" "ferox-nucleiNorm.txt" "ferox-goodENUM.txt" \
                "ferox-admin.txt" "ferox-signup.txt" "ferox-sensitive.txt" "ferox-endpoints.txt"; do
        if [ -f "${search_dir}/${file}" ]; then
            cp "${search_dir}/${file}" "./${file}"
            echo -e "${GREEN}  ✓ Found: ${file}${NC}"
            found=$((found + 1))
        fi
    done
    
    return $found
}

# Check for command-line argument (custom path)
if [ $# -eq 1 ]; then
    CUSTOM_PATH="$1"
    if [ -d "$CUSTOM_PATH" ]; then
        echo -e "${BLUE}[*] Searching for ferox files in: $CUSTOM_PATH${NC}"
        detect_ferox_files "$CUSTOM_PATH"
        echo ""
    else
        echo -e "${RED}[!] Invalid directory: $CUSTOM_PATH${NC}"
        exit 1
    fi
else
    # Auto-detection: check current directory first, then parent
    echo -e "${BLUE}[*] Auto-detecting feroxbuster output files...${NC}"
    
    # Check current directory (where script is located)
    for file in ferox-*.txt; do
        if [ -f "$file" ]; then
            echo -e "${GREEN}  ✓ Found: $file${NC}"
        fi
    done
    
    # If no files found, check parent directory
    if [ ! -f "ferox-admin.txt" ] && [ ! -f "ferox-graphql.txt" ]; then
        echo -e "${YELLOW}[*] No ferox files in script directory, checking parent...${NC}"
        detect_ferox_files ".."
        echo ""
    fi
fi

# Check if output files exist
OUTPUT_FILES=(
    "ferox-graphql.txt"
    "ferox-nucleiNorm.txt"
    "ferox-goodENUM.txt"
    "ferox-admin.txt"
    "ferox-signup.txt"
    "ferox-sensitive.txt"
    "ferox-endpoints.txt"
)

echo -e "${BLUE}[*] Checking for feroxbuster output files...${NC}"
FOUND_COUNT=0
for file in "${OUTPUT_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo -e "${GREEN}  ✓ Found: $file${NC}"
        ((FOUND_COUNT++))
    else
        echo -e "${RED}  ✗ Missing: $file${NC}"
    fi
done

echo ""
echo -e "${YELLOW}[*] Found $FOUND_COUNT output files${NC}"
echo ""

if [ $FOUND_COUNT -eq 0 ]; then
    echo -e "${RED}[!] No feroxbuster output files found!${NC}"
    echo -e "${YELLOW}[!] Run feroxbuster scans first${NC}"
    exit 1
fi

# Function to extract URL from feroxbuster output
# Format: 301      GET        0l        0w        0c http://example.com/path => https://example.com/path
# Extracts the final URL (after => if present, otherwise the main URL)
extract_urls() {
    local input_file="$1"
    local output_file="$2"
    
    # Extract lines with status codes, then get the URL
    # Handle redirects: if " => " present, take URL after arrow, otherwise take the URL before any space after 0c
    grep -E "^[0-9]{3}" "$input_file" 2>/dev/null | while read -r line; do
        # Extract URL part (comes after "0c ")
        url=$(echo "$line" | sed -E 's/^[0-9]+[[:space:]]+[A-Z]+[[:space:]]+[0-9]+l[[:space:]]+[0-9]+w[[:space:]]+[0-9]+c[[:space:]]+//' | sed -E 's/[[:space:]]+=>.*$//')
        
        # If there's a redirect (=>), use the redirected URL (HTTPS)
        if echo "$line" | grep -q " => "; then
            redirect_url=$(echo "$line" | sed -E 's/.* => //')
            echo "$redirect_url"
        else
            echo "$url"
        fi
    done | sort -u > "$output_file"
}

# Create master summary
echo -e "${CYAN}[*] Creating master summary...${NC}"
cat > MASTER-SUMMARY.txt << 'HEAD'
================================================================================
FEROXBUSTER SCAN SUMMARY - CTF/HACKATHON
================================================================================

Generated: $(date)
Total Scans: 7

HEAD

# Process each file
for file in "${OUTPUT_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        continue
    fi
    
    # Extract folder name from filename
    FOLDER_NAME=$(echo "$file" | sed 's/ferox-//' | sed 's/.txt$//')
    DIR_NAME="results-${FOLDER_NAME}"
    
    echo -e "${CYAN}[*] Processing: $file → $DIR_NAME/${NC}"
    
    # Create directory
    mkdir -p "$DIR_NAME"
    
    # Copy original file
    cp "$file" "$DIR_NAME/original-${file}"
    
    # Extract URLs from feroxbuster output (clean URLs for nuclei)
    echo -e "${BLUE}  [*] Extracting URLs...${NC}"
    extract_urls "$file" "$DIR_NAME/all-urls.txt"
    TOTAL_URLS=$(wc -l < "$DIR_NAME/all-urls.txt" 2>/dev/null || echo "0")
    
    echo -e "${GREEN}  ✓ Extracted $TOTAL_URLS unique URLs${NC}"
    
    # Sort by status code and extract URLs
    echo -e "${BLUE}  [*] Sorting by status code...${NC}"
    
    # 200 OK
    grep "^200 " "$file" 2>/dev/null | while read -r line; do
        url=$(echo "$line" | sed -E 's/^[0-9]+[[:space:]]+[A-Z]+[[:space:]]+[0-9]+l[[:space:]]+[0-9]+w[[:space:]]+[0-9]+c[[:space:]]+//' | sed -E 's/[[:space:]]+=>.*$//')
        if echo "$line" | grep -q " => "; then
            echo "$line" | sed -E 's/.* => //'
        else
            echo "$url"
        fi
    done | sort -u > "$DIR_NAME/status-200.txt" 2>/dev/null || touch "$DIR_NAME/status-200.txt"
    COUNT_200=$(wc -l < "$DIR_NAME/status-200.txt" 2>/dev/null || echo "0")
    
    # 301/302 Redirects
    grep -E "^301 |^302 " "$file" 2>/dev/null | while read -r line; do
        url=$(echo "$line" | sed -E 's/^[0-9]+[[:space:]]+[A-Z]+[[:space:]]+[0-9]+l[[:space:]]+[0-9]+w[[:space:]]+[0-9]+c[[:space:]]+//' | sed -E 's/[[:space:]]+=>.*$//')
        if echo "$line" | grep -q " => "; then
            echo "$line" | sed -E 's/.* => //'
        else
            echo "$url"
        fi
    done | sort -u > "$DIR_NAME/status-redirect.txt" 2>/dev/null || touch "$DIR_NAME/status-redirect.txt"
    COUNT_REDIRECT=$(wc -l < "$DIR_NAME/status-redirect.txt" 2>/dev/null || echo "0")
    
    # 401/403 Forbidden
    grep -E "^401 |^403 " "$file" 2>/dev/null | while read -r line; do
        url=$(echo "$line" | sed -E 's/^[0-9]+[[:space:]]+[A-Z]+[[:space:]]+[0-9]+l[[:space:]]+[0-9]+w[[:space:]]+[0-9]+c[[:space:]]+//' | sed -E 's/[[:space:]]+=>.*$//')
        if echo "$line" | grep -q " => "; then
            echo "$line" | sed -E 's/.* => //'
        else
            echo "$url"
        fi
    done | sort -u > "$DIR_NAME/status-forbidden.txt" 2>/dev/null || touch "$DIR_NAME/status-forbidden.txt"
    COUNT_FORBIDDEN=$(wc -l < "$DIR_NAME/status-forbidden.txt" 2>/dev/null || echo "0")
    
    # 500 Server Errors
    grep "^500 " "$file" 2>/dev/null | while read -r line; do
        url=$(echo "$line" | sed -E 's/^[0-9]+[[:space:]]+[A-Z]+[[:space:]]+[0-9]+l[[:space:]]+[0-9]+w[[:space:]]+[0-9]+c[[:space:]]+//' | sed -E 's/[[:space:]]+=>.*$//')
        if echo "$line" | grep -q " => "; then
            echo "$line" | sed -E 's/.* => //'
        else
            echo "$url"
        fi
    done | sort -u > "$DIR_NAME/status-500.txt" 2>/dev/null || touch "$DIR_NAME/status-500.txt"
    COUNT_500=$(wc -l < "$DIR_NAME/status-500.txt" 2>/dev/null || echo "0")
    
    # Other status codes
    grep -v -E "^200 |^301 |^302 |^401 |^403 |^500 " "$file" 2>/dev/null | grep "^[0-9]" | while read -r line; do
        url=$(echo "$line" | sed -E 's/^[0-9]+[[:space:]]+[A-Z]+[[:space:]]+[0-9]+l[[:space:]]+[0-9]+w[[:space:]]+[0-9]+c[[:space:]]+//' | sed -E 's/[[:space:]]+=>.*$//')
        if echo "$line" | grep -q " => "; then
            echo "$line" | sed -E 's/.* => //'
        else
            echo "$url"
        fi
    done | sort -u > "$DIR_NAME/status-other.txt" 2>/dev/null || touch "$DIR_NAME/status-other.txt"
    COUNT_OTHER=$(wc -l < "$DIR_NAME/status-other.txt" 2>/dev/null || echo "0")
    
    # Create consolidated file with full lines (for reference)
    echo "================================================================================" > "$DIR_NAME/consolidated-all.txt"
    echo "CONSOLIDATED RESULTS: $file" >> "$DIR_NAME/consolidated-all.txt"
    echo "Generated: $(date)" >> "$DIR_NAME/consolidated-all.txt"
    echo "================================================================================" >> "$DIR_NAME/consolidated-all.txt"
    echo "" >> "$DIR_NAME/consolidated-all.txt"
    echo "=== 200 OK (Success) - $COUNT_200 URLs ===" >> "$DIR_NAME/consolidated-all.txt"
    cat "$DIR_NAME/status-200.txt" >> "$DIR_NAME/consolidated-all.txt" 2>/dev/null
    echo "" >> "$DIR_NAME/consolidated-all.txt"
    echo "=== Redirects (301/302) - $COUNT_REDIRECT URLs ===" >> "$DIR_NAME/consolidated-all.txt"
    cat "$DIR_NAME/status-redirect.txt" >> "$DIR_NAME/consolidated-all.txt" 2>/dev/null
    echo "" >> "$DIR_NAME/consolidated-all.txt"
    echo "=== Forbidden (401/403) - $COUNT_FORBIDDEN URLs ===" >> "$DIR_NAME/consolidated-all.txt"
    cat "$DIR_NAME/status-forbidden.txt" >> "$DIR_NAME/consolidated-all.txt" 2>/dev/null
    echo "" >> "$DIR_NAME/consolidated-all.txt"
    echo "=== Server Errors (500) - $COUNT_500 URLs ===" >> "$DIR_NAME/consolidated-all.txt"
    cat "$DIR_NAME/status-500.txt" >> "$DIR_NAME/consolidated-all.txt" 2>/dev/null
    echo "" >> "$DIR_NAME/consolidated-all.txt"
    echo "=== Other Status Codes - $COUNT_OTHER URLs ===" >> "$DIR_NAME/consolidated-all.txt"
    cat "$DIR_NAME/status-other.txt" >> "$DIR_NAME/consolidated-all.txt" 2>/dev/null
    
    echo -e "${GREEN}  ✓ Status codes sorted${NC}"
    
    # Extract by category from all URLs
    echo -e "${BLUE}  [*] Extracting categories...${NC}"
    
    # Admin panels
    grep -iE "/admin|/dashboard|/manage|/panel|/console|/backend|/controlpanel|/moderator|/operator|/root" "$DIR_NAME/all-urls.txt" 2>/dev/null | sort -u > "$DIR_NAME/admin-panels.txt" || touch "$DIR_NAME/admin-panels.txt"
    COUNT_ADMIN=$(wc -l < "$DIR_NAME/admin-panels.txt" 2>/dev/null || echo "0")
    
    # API endpoints
    grep -iE "/api|/graphql|/v1/|/v2/|/v3/|/rest|/swagger|/docs|/openapi|/jsonrpc|/soap|/wsdl" "$DIR_NAME/all-urls.txt" 2>/dev/null | sort -u > "$DIR_NAME/api-endpoints.txt" || touch "$DIR_NAME/api-endpoints.txt"
    COUNT_API=$(wc -l < "$DIR_NAME/api-endpoints.txt" 2>/dev/null || echo "0")
    
    # Backup files
    grep -iE "\.bak|\.backup|\.old|\.zip|\.tar|\.gz|\.sql|\.dump|\.archive|\.save|\.swp|\.tmp" "$DIR_NAME/all-urls.txt" 2>/dev/null | sort -u > "$DIR_NAME/backup-files.txt" || touch "$DIR_NAME/backup-files.txt"
    COUNT_BACKUP=$(wc -l < "$DIR_NAME/backup-files.txt" 2>/dev/null || echo "0")
    
    # Config files
    grep -iE "\.env|config|settings|configuration|\.ini|\.yaml|\.yml|\.json|\.xml|\.properties|\.conf|\.cfg|\.toml" "$DIR_NAME/all-urls.txt" 2>/dev/null | sort -u > "$DIR_NAME/config-files.txt" || touch "$DIR_NAME/config-files.txt"
    COUNT_CONFIG=$(wc -l < "$DIR_NAME/config-files.txt" 2>/dev/null || echo "0")
    
    # Dev tools
    grep -iE "/playground|/graphiql|/explorer|/swagger|/docs|/debug|/phpinfo|/profiler|/test|/demo|/try" "$DIR_NAME/all-urls.txt" 2>/dev/null | sort -u > "$DIR_NAME/dev-tools.txt" || touch "$DIR_NAME/dev-tools.txt"
    COUNT_DEV=$(wc -l < "$DIR_NAME/dev-tools.txt" 2>/dev/null || echo "0")
    
    echo -e "${GREEN}  ✓ Categories extracted${NC}"
    
    # Create high-priority file (200 OK only from interesting categories)
    cat "$DIR_NAME/status-200.txt" 2>/dev/null | grep -iE "/admin|/dashboard|/api|/graphql|/v1/|/v2/|/playground|/graphiql|/swagger|\.env|config|\.json|\.yaml|backup|\.sql" | sort -u > "$DIR_NAME/high-priority.txt" || touch "$DIR_NAME/high-priority.txt"
    COUNT_HIGH=$(wc -l < "$DIR_NAME/high-priority.txt" 2>/dev/null || echo "0")
    
    echo -e "${GREEN}  ✓ High-priority list created${NC}"
    
    # Update master summary
    cat >> MASTER-SUMMARY.txt << EOF

--------------------------------------------------------------------------------
SCAN: $file
Directory: $DIR_NAME/
--------------------------------------------------------------------------------
Total URLs Found: $TOTAL_URLS

Status Code Breakdown:
  200 OK:           $COUNT_200
  Redirects:        $COUNT_REDIRECT
  Forbidden:        $COUNT_FORBIDDEN
  Server Errors:    $COUNT_500
  Other:            $COUNT_OTHER

Category Breakdown:
  Admin Panels:     $COUNT_ADMIN
  API Endpoints:    $COUNT_API
  Backup Files:     $COUNT_BACKUP
  Config Files:     $COUNT_CONFIG
  Dev Tools:        $COUNT_DEV
  High Priority:    $COUNT_HIGH


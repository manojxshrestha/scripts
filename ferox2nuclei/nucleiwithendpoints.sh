#!/bin/bash
# Nuclei Automation for Endpoints Category
# Targets: API endpoints, REST endpoints, general endpoints

# Get script directory (works from any location)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1

echo "========================================"
echo "  Nuclei Scan: Endpoints Category"
echo "========================================"
echo ""

DIR_NAME="results-endpoints"

# Auto-detect: check script directory first, then current working directory
if [ ! -d "$DIR_NAME" ]; then
    echo "[!] Directory not found: $DIR_NAME"
    echo "[!] Run ./ferox2nuclei.sh first to process feroxbuster results"
    exit 1
fi

mkdir -p nuclei-results-endpoints

echo "[*] Starting endpoint-focused scans..."
echo ""

# 1. API endpoint vulnerabilities
echo "[1/7] API Vulnerabilities..."
if [ -f "$DIR_NAME/api-endpoints.txt" ] && [ -s "$DIR_NAME/api-endpoints.txt" ]; then
    nuclei -l "$DIR_NAME/api-endpoints.txt" \
        -t /home/pwn/nuclei-templates/http/exposures/apis/ \
        -t /home/pwn/nuclei-templates/http/vulnerabilities/ \
        -severity high,critical \
        -c 40 \
        -rl 120 \
        -o nuclei-results-endpoints/01-api-vulns.txt 2>/dev/null || echo "  [!] API scan skipped"
fi
echo "  ✓ Complete"
echo ""

# 2. CVEs on endpoints (2023-2025)
echo "[2/7] Recent CVEs (2023-2025)..."
if [ -f "$DIR_NAME/all-urls.txt" ] && [ -s "$DIR_NAME/all-urls.txt" ]; then
    nuclei -l "$DIR_NAME/all-urls.txt" \
        -t /home/pwn/nuclei-templates/http/cves/2025/ \
        -t /home/pwn/nuclei-templates/http/cves/2024/ \
        -t /home/pwn/nuclei-templates/http/cves/2023/ \
        -severity high,critical \
        -c 40 \
        -rl 120 \
        -retries 2 \
        -o nuclei-results-endpoints/02-endpoint-cves.txt 2>/dev/null || echo "  [!] CVE scan skipped"
fi
echo "  ✓ Complete"
echo ""

# 3. Exposed panels on endpoints
echo "[3/7] Exposed Panels..."
if [ -f "$DIR_NAME/all-urls.txt" ] && [ -s "$DIR_NAME/all-urls.txt" ]; then
    nuclei -l "$DIR_NAME/all-urls.txt" \
        -t /home/pwn/nuclei-templates/http/exposed-panels/ \
        -severity medium,high,critical \
        -c 50 \
        -rl 150 \
        -o nuclei-results-endpoints/03-exposed-panels.txt 2>/dev/null || echo "  [!] Panel scan skipped"
fi
echo "  ✓ Complete"
echo ""

# 4. Misconfigurations
echo "[4/7] Security Misconfigurations..."
if [ -f "$DIR_NAME/all-urls.txt" ] && [ -s "$DIR_NAME/all-urls.txt" ]; then
    nuclei -l "$DIR_NAME/all-urls.txt" \
        -t /home/pwn/nuclei-templates/http/misconfiguration/ \
        -severity medium,high,critical \
        -c 40 \
        -rl 120 \
        -o nuclei-results-endpoints/04-misconfigurations.txt 2>/dev/null || echo "  [!] Misconfig scan skipped"
fi
echo "  ✓ Complete"
echo ""

# 5. Technology fingerprinting
echo "[5/7] Technology Detection..."
if [ -f "$DIR_NAME/all-urls.txt" ] && [ -s "$DIR_NAME/all-urls.txt" ]; then
    nuclei -l "$DIR_NAME/all-urls.txt" \
        -t /home/pwn/nuclei-templates/http/technologies/ \
        -c 50 \
        -rl 150 \
        -o nuclei-results-endpoints/05-technologies.txt 2>/dev/null || echo "  [!] Tech detection skipped"
fi
echo "  ✓ Complete"
echo ""

# 6. Token/API key exposure
echo "[6/7] API Key & Token Exposure..."
if [ -f "$DIR_NAME/api-endpoints.txt" ] && [ -s "$DIR_NAME/api-endpoints.txt" ]; then
    nuclei -l "$DIR_NAME/api-endpoints.txt" \
        -t /home/pwn/nuclei-templates/http/token-spray/ \
        -c 40 \
        -rl 120 \
        -o nuclei-results-endpoints/06-api-tokens.txt 2>/dev/null || echo "  [!] Token scan skipped"
fi
echo "  ✓ Complete"
echo ""

# 7. General vulnerabilities
echo "[7/7] General Vulnerabilities..."
if [ -f "$DIR_NAME/all-urls.txt" ] && [ -s "$DIR_NAME/all-urls.txt" ]; then
    nuclei -l "$DIR_NAME/all-urls.txt" \
        -t /home/pwn/nuclei-templates/http/vulnerabilities/ \
        -severity high,critical \
        -c 30 \
        -rl 100 \
        -o nuclei-results-endpoints/07-vulnerabilities.txt 2>/dev/null || echo "  [!] Vuln scan skipped"
fi
echo "  ✓ Complete"
echo ""

echo "========================================"
echo "  Endpoints Scans Complete!"
echo "========================================"
echo ""
echo "Results: nuclei-results-endpoints/"
ls -lh nuclei-results-endpoints/ 2>/dev/null || echo "No results generated"

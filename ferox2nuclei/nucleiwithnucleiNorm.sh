#!/bin/bash
# Nuclei Automation for NucleiNorm Category
# Targets: General vulnerability assessment

# Get script directory (works from any location)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1

echo "========================================"
echo "  Nuclei Scan: NucleiNorm Category"
echo "========================================"
echo ""

DIR_NAME="results-nucleiNorm"

# Auto-detect: check script directory first, then current working directory
if [ ! -d "$DIR_NAME" ]; then
    echo "[!] Directory not found: $DIR_NAME"
    echo "[!] Run ./ferox2nuclei.sh first to process feroxbuster results"
    exit 1
fi

mkdir -p nuclei-results-nucleiNorm

echo "[*] Starting comprehensive vulnerability scans..."
echo ""

# 1. Recent CVEs (2024-2025) - Critical & High only
echo "[1/7] Recent CVEs (2024-2025)..."
if [ -f "$DIR_NAME/all-urls.txt" ] && [ -s "$DIR_NAME/all-urls.txt" ]; then
    nuclei -l "$DIR_NAME/all-urls.txt" \
        -t /home/pwn/nuclei-templates/http/cves/2025/ \
        -t /home/pwn/nuclei-templates/http/cves/2024/ \
        -severity critical,high \
        -c 40 \
        -rl 120 \
        -retries 2 \
        -o nuclei-results-nucleiNorm/01-recent-cves.txt 2>/dev/null || echo "  [!] No recent CVEs found"
fi
echo "  ✓ Complete"
echo ""

# 2. Exposed panels and interfaces
echo "[2/7] Exposed Panels..."
if [ -f "$DIR_NAME/all-urls.txt" ] && [ -s "$DIR_NAME/all-urls.txt" ]; then
    nuclei -l "$DIR_NAME/all-urls.txt" \
        -t /home/pwn/nuclei-templates/http/exposed-panels/ \
        -severity medium,high,critical \
        -c 50 \
        -rl 150 \
        -o nuclei-results-nucleiNorm/02-exposed-panels.txt 2>/dev/null || echo "  [!] Panel scan skipped"
fi
echo "  ✓ Complete"
echo ""

# 3. Misconfigurations
echo "[3/7] Security Misconfigurations..."
if [ -f "$DIR_NAME/all-urls.txt" ] && [ -s "$DIR_NAME/all-urls.txt" ]; then
    nuclei -l "$DIR_NAME/all-urls.txt" \
        -t /home/pwn/nuclei-templates/http/misconfiguration/ \
        -severity medium,high,critical \
        -c 40 \
        -rl 120 \
        -o nuclei-results-nucleiNorm/03-misconfigurations.txt 2>/dev/null || echo "  [!] Misconfig scan skipped"
fi
echo "  ✓ Complete"
echo ""

# 4. Vulnerabilities (general)
echo "[4/7] General Vulnerabilities..."
if [ -f "$DIR_NAME/all-urls.txt" ] && [ -s "$DIR_NAME/all-urls.txt" ]; then
    nuclei -l "$DIR_NAME/all-urls.txt" \
        -t /home/pwn/nuclei-templates/http/vulnerabilities/ \
        -severity high,critical \
        -c 30 \
        -rl 100 \
        -o nuclei-results-nucleiNorm/04-vulnerabilities.txt 2>/dev/null || echo "  [!] Vuln scan skipped"
fi
echo "  ✓ Complete"
echo ""

# 5. Exposures (configs, files, backups)
echo "[5/7] Information Exposures..."
if [ -f "$DIR_NAME/all-urls.txt" ] && [ -s "$DIR_NAME/all-urls.txt" ]; then
    nuclei -l "$DIR_NAME/all-urls.txt" \
        -t /home/pwn/nuclei-templates/http/exposures/ \
        -severity medium,high,critical \
        -c 40 \
        -rl 120 \
        -o nuclei-results-nucleiNorm/05-exposures.txt 2>/dev/null || echo "  [!] Exposure scan skipped"
fi
echo "  ✓ Complete"
echo ""

# 6. Token/API key exposures
echo "[6/7] Token & API Key Leaks..."
if [ -f "$DIR_NAME/all-urls.txt" ] && [ -s "$DIR_NAME/all-urls.txt" ]; then
    nuclei -l "$DIR_NAME/all-urls.txt" \
        -t /home/pwn/nuclei-templates/http/token-spray/ \
        -c 30 \
        -rl 100 \
        -o nuclei-results-nucleiNorm/06-token-leaks.txt 2>/dev/null || echo "  [!] Token scan skipped"
fi
echo "  ✓ Complete"
echo ""

# 7. Technologies (fingerprinting)
echo "[7/7] Technology Detection..."
if [ -f "$DIR_NAME/all-urls.txt" ] && [ -s "$DIR_NAME/all-urls.txt" ]; then
    nuclei -l "$DIR_NAME/all-urls.txt" \
        -t /home/pwn/nuclei-templates/http/technologies/ \
        -c 50 \
        -rl 150 \
        -o nuclei-results-nucleiNorm/07-technologies.txt 2>/dev/null || echo "  [!] Tech detection skipped"
fi
echo "  ✓ Complete"
echo ""

echo "========================================"
echo "  NucleiNorm Scans Complete!"
echo "========================================"
echo ""
echo "Results: nuclei-results-nucleiNorm/"
ls -lh nuclei-results-nucleiNorm/ 2>/dev/null || echo "No results generated"

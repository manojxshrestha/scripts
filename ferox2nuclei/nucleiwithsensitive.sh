#!/bin/bash
# Nuclei Automation for Sensitive Category
# Targets: Sensitive directories, private files, confidential data

echo "========================================"
echo "  Nuclei Scan: Sensitive Category"
echo "========================================"
echo ""

DIR_NAME="results-sensitive"

if [ ! -d "$DIR_NAME" ]; then
    echo "[!] Directory not found: $DIR_NAME"
    echo "[!] Run ./process-ferox-results.sh first"
    exit 1
fi

mkdir -p nuclei-results-sensitive

echo "[*] Starting sensitive data scans..."
echo ""

# 1. Config file exposures (highest priority)
echo "[1/7] Config File Exposures..."
if [ -f "$DIR_NAME/config-files.txt" ] && [ -s "$DIR_NAME/config-files.txt" ]; then
    nuclei -l "$DIR_NAME/config-files.txt" \
        -t /home/pwn/nuclei-templates/http/exposures/configs/ \
        -severity medium,high,critical \
        -c 50 \
        -rl 150 \
        -o nuclei-results-sensitive/01-config-exposures.txt 2>/dev/null || echo "  [!] Config scan skipped"
fi
echo "  ✓ Complete"
echo ""

# 2. Backup file exposures
echo "[2/7] Backup File Exposures..."
if [ -f "$DIR_NAME/backup-files.txt" ] && [ -s "$DIR_NAME/backup-files.txt" ]; then
    nuclei -l "$DIR_NAME/backup-files.txt" \
        -t /home/pwn/nuclei-templates/http/exposures/backups/ \
        -severity medium,high,critical \
        -c 50 \
        -rl 150 \
        -o nuclei-results-sensitive/02-backup-exposures.txt 2>/dev/null || echo "  [!] Backup scan skipped"
fi
echo "  ✓ Complete"
echo ""

# 3. File exposures (general)
echo "[3/7] Sensitive File Exposures..."
if [ -f "$DIR_NAME/all-urls.txt" ] && [ -s "$DIR_NAME/all-urls.txt" ]; then
    nuclei -l "$DIR_NAME/all-urls.txt" \
        -t /home/pwn/nuclei-templates/http/exposures/files/ \
        -severity medium,high,critical \
        -c 50 \
        -rl 150 \
        -o nuclei-results-sensitive/03-file-exposures.txt 2>/dev/null || echo "  [!] File scan skipped"
fi
echo "  ✓ Complete"
echo ""

# 4. Log file exposures
echo "[4/7] Log File Exposures..."
if [ -f "$DIR_NAME/all-urls.txt" ] && [ -s "$DIR_NAME/all-urls.txt" ]; then
    nuclei -l "$DIR_NAME/all-urls.txt" \
        -t /home/pwn/nuclei-templates/http/exposures/logs/ \
        -severity medium,high \
        -c 40 \
        -rl 120 \
        -o nuclei-results-sensitive/04-log-exposures.txt 2>/dev/null || echo "  [!] Log scan skipped"
fi
echo "  ✓ Complete"
echo ""

# 5. Token/API key leaks
echo "[5/7] Token & API Key Leaks..."
if [ -f "$DIR_NAME/all-urls.txt" ] && [ -s "$DIR_NAME/all-urls.txt" ]; then
    nuclei -l "$DIR_NAME/all-urls.txt" \
        -t /home/pwn/nuclei-templates/http/token-spray/ \
        -c 40 \
        -rl 120 \
        -o nuclei-results-sensitive/05-token-leaks.txt 2>/dev/null || echo "  [!] Token scan skipped"
fi
echo "  ✓ Complete"
echo ""

# 6. Exposures (general)
echo "[6/7] General Exposures..."
if [ -f "$DIR_NAME/all-urls.txt" ] && [ -s "$DIR_NAME/all-urls.txt" ]; then
    nuclei -l "$DIR_NAME/all-urls.txt" \
        -t /home/pwn/nuclei-templates/http/exposures/ \
        -severity medium,high,critical \
        -c 40 \
        -rl 120 \
        -o nuclei-results-sensitive/06-general-exposures.txt 2>/dev/null || echo "  [!] General exposure scan skipped"
fi
echo "  ✓ Complete"
echo ""

# 7. CVEs on sensitive endpoints
echo "[7/7] CVE Scan (2024-2025)..."
if [ -f "$DIR_NAME/all-urls.txt" ] && [ -s "$DIR_NAME/all-urls.txt" ]; then
    nuclei -l "$DIR_NAME/all-urls.txt" \
        -t /home/pwn/nuclei-templates/http/cves/2025/ \
        -t /home/pwn/nuclei-templates/http/cves/2024/ \
        -severity high,critical \
        -c 30 \
        -rl 100 \
        -o nuclei-results-sensitive/07-sensitive-cves.txt 2>/dev/null || echo "  [!] CVE scan skipped"
fi
echo "  ✓ Complete"
echo ""

echo "========================================"
echo "  Sensitive Scans Complete!"
echo "========================================"
echo ""
echo "Results: nuclei-results-sensitive/"
ls -lh nuclei-results-sensitive/ 2>/dev/null || echo "No results generated"

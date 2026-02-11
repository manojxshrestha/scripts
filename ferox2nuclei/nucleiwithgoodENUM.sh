#!/bin/bash
# Nuclei Automation for GoodENUM Category
# Targets: Well-enumerated endpoints with extensions

echo "========================================"
echo "  Nuclei Scan: GoodENUM Category"
echo "========================================"
echo ""

DIR_NAME="results-goodENUM"

if [ ! -d "$DIR_NAME" ]; then
    echo "[!] Directory not found: $DIR_NAME"
    echo "[!] Run ./process-ferox-results.sh first"
    exit 1
fi

mkdir -p nuclei-results-goodENUM

echo "[*] Starting enumeration-focused scans..."
echo ""

# 1. File exposures (configs, backups, sensitive files)
echo "[1/6] File Exposure Scan..."
if [ -f "$DIR_NAME/all-urls.txt" ] && [ -s "$DIR_NAME/all-urls.txt" ]; then
    nuclei -l "$DIR_NAME/all-urls.txt" \
        -t /home/pwn/nuclei-templates/http/exposures/files/ \
        -t /home/pwn/nuclei-templates/http/exposures/backups/ \
        -severity medium,high,critical \
        -c 50 \
        -rl 150 \
        -o nuclei-results-goodENUM/01-file-exposures.txt 2>/dev/null || echo "  [!] File scan skipped"
fi
echo "  ✓ Complete"
echo ""

# 2. Config file exposures
echo "[2/6] Config File Exposures..."
if [ -f "$DIR_NAME/config-files.txt" ] && [ -s "$DIR_NAME/config-files.txt" ]; then
    nuclei -l "$DIR_NAME/config-files.txt" \
        -t /home/pwn/nuclei-templates/http/exposures/configs/ \
        -severity medium,high,critical \
        -c 50 \
        -rl 150 \
        -o nuclei-results-goodENUM/02-config-exposures.txt 2>/dev/null || echo "  [!] Config scan skipped"
fi
echo "  ✓ Complete"
echo ""

# 3. Backup file exposures
echo "[3/6] Backup File Exposures..."
if [ -f "$DIR_NAME/backup-files.txt" ] && [ -s "$DIR_NAME/backup-files.txt" ]; then
    nuclei -l "$DIR_NAME/backup-files.txt" \
        -t /home/pwn/nuclei-templates/http/exposures/backups/ \
        -severity medium,high,critical \
        -c 50 \
        -rl 150 \
        -o nuclei-results-goodENUM/03-backup-exposures.txt 2>/dev/null || echo "  [!] Backup scan skipped"
fi
echo "  ✓ Complete"
echo ""

# 4. Log file exposures
echo "[4/6] Log File Exposures..."
if [ -f "$DIR_NAME/all-urls.txt" ] && [ -s "$DIR_NAME/all-urls.txt" ]; then
    nuclei -l "$DIR_NAME/all-urls.txt" \
        -t /home/pwn/nuclei-templates/http/exposures/logs/ \
        -severity medium,high \
        -c 40 \
        -rl 120 \
        -o nuclei-results-goodENUM/04-log-exposures.txt 2>/dev/null || echo "  [!] Log scan skipped"
fi
echo "  ✓ Complete"
echo ""

# 5. CVEs on enumerated endpoints
echo "[5/6] CVE Scan (2023-2025)..."
if [ -f "$DIR_NAME/all-urls.txt" ] && [ -s "$DIR_NAME/all-urls.txt" ]; then
    nuclei -l "$DIR_NAME/all-urls.txt" \
        -t /home/pwn/nuclei-templates/http/cves/2025/ \
        -t /home/pwn/nuclei-templates/http/cves/2024/ \
        -t /home/pwn/nuclei-templates/http/cves/2023/ \
        -severity high,critical \
        -c 30 \
        -rl 100 \
        -retries 2 \
        -o nuclei-results-goodENUM/05-cve-scan.txt 2>/dev/null || echo "  [!] CVE scan skipped"
fi
echo "  ✓ Complete"
echo ""

# 6. Credential stuffing check (if login endpoints found)
echo "[6/6] Credential Stuffing Check..."
if [ -f "$DIR_NAME/all-urls.txt" ] && [ -s "$DIR_NAME/all-urls.txt" ]; then
    nuclei -l "$DIR_NAME/all-urls.txt" \
        -t /home/pwn/nuclei-templates/http/credential-stuffing/ \
        -severity high,critical \
        -c 20 \
        -rl 80 \
        -o nuclei-results-goodENUM/06-credential-stuffing.txt 2>/dev/null || echo "  [!] Credential check skipped"
fi
echo "  ✓ Complete"
echo ""

echo "========================================"
echo "  GoodENUM Scans Complete!"
echo "========================================"
echo ""
echo "Results: nuclei-results-goodENUM/"
ls -lh nuclei-results-goodENUM/ 2>/dev/null || echo "No results generated"

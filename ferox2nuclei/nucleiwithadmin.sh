#!/bin/bash
# Nuclei Automation for Admin Category
# Targets: Admin panels, dashboards, management consoles

# Get script directory (works from any location)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1

echo "========================================"
echo "  Nuclei Scan: Admin Category"
echo "========================================"
echo ""

DIR_NAME="results-admin"

# Auto-detect: check script directory first, then current working directory
if [ ! -d "$DIR_NAME" ]; then
    # Try to find in current working directory
    CWD_DIR="$(pwd)"
    if [ -d "${CWD_DIR}/${DIR_NAME}" ]; then
        echo "[*] Found results in current directory"
    else
        echo "[!] Directory not found: $DIR_NAME"
        echo "[!] Run ./ferox2nuclei.sh first to process feroxbuster results"
        exit 1
    fi
fi

mkdir -p nuclei-results-admin

echo "[*] Starting Admin-focused scans..."
echo ""

# 1. Exposed admin panels
echo "[1/7] Admin Panel Exposure..."
if [ -f "$DIR_NAME/admin-panels.txt" ] && [ -s "$DIR_NAME/admin-panels.txt" ]; then
    nuclei -l "$DIR_NAME/admin-panels.txt" \
        -t /home/pwn/nuclei-templates/http/exposed-panels/ \
        -severity medium,high,critical \
        -c 50 \
        -rl 150 \
        -retries 2 \
        -o nuclei-results-admin/01-admin-panels.txt 2>/dev/null || echo "  [!] No admin panels"
fi
echo "  ✓ Complete"
echo ""

# 2. Default logins (admin/admin, root/root, etc.)
echo "[2/7] Default Credentials..."
if [ -f "$DIR_NAME/admin-panels.txt" ] && [ -s "$DIR_NAME/admin-panels.txt" ]; then
    nuclei -l "$DIR_NAME/admin-panels.txt" \
        -t /home/pwn/nuclei-templates/http/default-logins/ \
        -severity high,critical \
        -c 30 \
        -rl 100 \
        -o nuclei-results-admin/02-default-logins.txt 2>/dev/null || echo "  [!] Default login check skipped"
fi
echo "  ✓ Complete"
echo ""

# 3. Admin dashboard misconfigurations
echo "[3/7] Admin Dashboard Misconfigurations..."
if [ -f "$DIR_NAME/admin-panels.txt" ] && [ -s "$DIR_NAME/admin-panels.txt" ]; then
    nuclei -l "$DIR_NAME/admin-panels.txt" \
        -t /home/pwn/nuclei-templates/http/misconfiguration/ \
        -severity medium,high,critical \
        -c 50 \
        -rl 150 \
        -o nuclei-results-admin/03-admin-misconfig.txt 2>/dev/null || echo "  [!] Misconfig check skipped"
fi
echo "  ✓ Complete"
echo ""

# 4. CVEs targeting admin panels (2023-2025)
echo "[4/7] Admin Panel CVEs (2023-2025)..."
if [ -f "$DIR_NAME/all-urls.txt" ] && [ -s "$DIR_NAME/all-urls.txt" ]; then
    nuclei -l "$DIR_NAME/all-urls.txt" \
        -t /home/pwn/nuclei-templates/http/cves/2025/ \
        -t /home/pwn/nuclei-templates/http/cves/2024/ \
        -t /home/pwn/nuclei-templates/http/cves/2023/ \
        -severity high,critical \
        -c 30 \
        -rl 100 \
        -retries 2 \
        -o nuclei-results-admin/04-admin-cves.txt 2>/dev/null || echo "  [!] CVE scan skipped"
fi
echo "  ✓ Complete"
echo ""

# 5. Config file exposures (admin configs)
echo "[5/7] Admin Config Exposures..."
if [ -f "$DIR_NAME/config-files.txt" ] && [ -s "$DIR_NAME/config-files.txt" ]; then
    nuclei -l "$DIR_NAME/config-files.txt" \
        -t /home/pwn/nuclei-templates/http/exposures/configs/ \
        -severity medium,high,critical \
        -c 50 \
        -rl 150 \
        -o nuclei-results-admin/05-config-exposure.txt 2>/dev/null || echo "  [!] Config check skipped"
fi
echo "  ✓ Complete"
echo ""

# 6. Privilege escalation vulnerabilities
echo "[6/7] Privilege Escalation Checks..."
if [ -f "$DIR_NAME/all-urls.txt" ] && [ -s "$DIR_NAME/all-urls.txt" ]; then
    nuclei -l "$DIR_NAME/all-urls.txt" \
        -t /home/pwn/nuclei-templates/http/vulnerabilities/ \
        -severity high,critical \
        -c 30 \
        -rl 100 \
        -o nuclei-results-admin/06-privilege-escalation.txt 2>/dev/null || echo "  [!] PrivEsc check skipped"
fi
echo "  ✓ Complete"
echo ""

# 7. Backup files in admin areas
echo "[7/7] Admin Backup Files..."
if [ -f "$DIR_NAME/backup-files.txt" ] && [ -s "$DIR_NAME/backup-files.txt" ]; then
    nuclei -l "$DIR_NAME/backup-files.txt" \
        -t /home/pwn/nuclei-templates/http/exposures/backups/ \
        -severity medium,high,critical \
        -c 50 \
        -rl 150 \
        -o nuclei-results-admin/07-admin-backups.txt 2>/dev/null || echo "  [!] Backup check skipped"
fi
echo "  ✓ Complete"
echo ""

echo "========================================"
echo "  Admin Scans Complete!"
echo "========================================"
echo ""
echo "Results: nuclei-results-admin/"
ls -lh nuclei-results-admin/ 2>/dev/null || echo "No results generated"

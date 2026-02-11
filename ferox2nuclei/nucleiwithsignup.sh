#!/bin/bash
# Nuclei Automation for Signup Category
# Targets: Authentication, registration, login endpoints

echo "========================================"
echo "  Nuclei Scan: Signup Category"
echo "========================================"
echo ""

DIR_NAME="results-signup"

if [ ! -d "$DIR_NAME" ]; then
    echo "[!] Directory not found: $DIR_NAME"
    echo "[!] Run ./process-ferox-results.sh first"
    exit 1
fi

mkdir -p nuclei-results-signup

echo "[*] Starting authentication-focused scans..."
echo ""

# 1. Default credentials on login endpoints
echo "[1/6] Default Credentials Check..."
if [ -f "$DIR_NAME/all-urls.txt" ] && [ -s "$DIR_NAME/all-urls.txt" ]; then
    nuclei -l "$DIR_NAME/all-urls.txt" \
        -t /home/pwn/nuclei-templates/http/default-logins/ \
        -severity high,critical \
        -c 30 \
        -rl 100 \
        -o nuclei-results-signup/01-default-credentials.txt 2>/dev/null || echo "  [!] Default creds check skipped"
fi
echo "  ✓ Complete"
echo ""

# 2. Authentication vulnerabilities
echo "[2/6] Authentication Vulnerabilities..."
if [ -f "$DIR_NAME/all-urls.txt" ] && [ -s "$DIR_NAME/all-urls.txt" ]; then
    nuclei -l "$DIR_NAME/all-urls.txt" \
        -t /home/pwn/nuclei-templates/http/vulnerabilities/ \
        -severity high,critical \
        -c 30 \
        -rl 100 \
        -o nuclei-results-signup/02-auth-vulns.txt 2>/dev/null || echo "  [!] Auth vuln scan skipped"
fi
echo "  ✓ Complete"
echo ""

# 3. Exposed panels (login pages)
echo "[3/6] Login Panel Exposures..."
if [ -f "$DIR_NAME/all-urls.txt" ] && [ -s "$DIR_NAME/all-urls.txt" ]; then
    nuclei -l "$DIR_NAME/all-urls.txt" \
        -t /home/pwn/nuclei-templates/http/exposed-panels/ \
        -severity medium,high \
        -c 40 \
        -rl 120 \
        -o nuclei-results-signup/03-login-panels.txt 2>/dev/null || echo "  [!] Panel scan skipped"
fi
echo "  ✓ Complete"
echo ""

# 4. Token/API key exposures (auth tokens)
echo "[4/6] Auth Token Exposures..."
if [ -f "$DIR_NAME/all-urls.txt" ] && [ -s "$DIR_NAME/all-urls.txt" ]; then
    nuclei -l "$DIR_NAME/all-urls.txt" \
        -t /home/pwn/nuclei-templates/http/token-spray/ \
        -c 30 \
        -rl 100 \
        -o nuclei-results-signup/04-token-exposures.txt 2>/dev/null || echo "  [!] Token scan skipped"
fi
echo "  ✓ Complete"
echo ""

# 5. CVEs related to authentication (2023-2025)
echo "[5/6] Auth-Related CVEs..."
if [ -f "$DIR_NAME/all-urls.txt" ] && [ -s "$DIR_NAME/all-urls.txt" ]; then
    nuclei -l "$DIR_NAME/all-urls.txt" \
        -t /home/pwn/nuclei-templates/http/cves/2025/ \
        -t /home/pwn/nuclei-templates/http/cves/2024/ \
        -severity high,critical \
        -c 30 \
        -rl 100 \
        -o nuclei-results-signup/05-auth-cves.txt 2>/dev/null || echo "  [!] CVE scan skipped"
fi
echo "  ✓ Complete"
echo ""

# 6. Misconfigurations on auth endpoints
echo "[6/6] Auth Misconfigurations..."
if [ -f "$DIR_NAME/all-urls.txt" ] && [ -s "$DIR_NAME/all-urls.txt" ]; then
    nuclei -l "$DIR_NAME/all-urls.txt" \
        -t /home/pwn/nuclei-templates/http/misconfiguration/ \
        -severity medium,high,critical \
        -c 40 \
        -rl 120 \
        -o nuclei-results-signup/06-auth-misconfig.txt 2>/dev/null || echo "  [!] Misconfig scan skipped"
fi
echo "  ✓ Complete"
echo ""

echo "========================================"
echo "  Signup Scans Complete!"
echo "========================================"
echo ""
echo "Results: nuclei-results-signup/"
ls -lh nuclei-results-signup/ 2>/dev/null || echo "No results generated"

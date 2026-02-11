#!/bin/bash
# Nuclei Automation for GraphQL Category
# Targets: GraphQL endpoints, API explorers, dev tools

echo "========================================"
echo "  Nuclei Scan: GraphQL Category"
echo "========================================"
echo ""

DIR_NAME="results-graphql"

if [ ! -d "$DIR_NAME" ]; then
    echo "[!] Directory not found: $DIR_NAME"
    echo "[!] Run ./process-ferox-results.sh first"
    exit 1
fi

mkdir -p nuclei-results-graphql

echo "[*] Starting GraphQL-focused scans..."
echo ""

# 1. GraphQL specific misconfigurations
echo "[1/6] GraphQL Misconfigurations..."
if [ -f "$DIR_NAME/api-endpoints.txt" ] && [ -s "$DIR_NAME/api-endpoints.txt" ]; then
    nuclei -l "$DIR_NAME/api-endpoints.txt" \
        -t /home/pwn/nuclei-templates/http/misconfiguration/graphql/ \
        -severity medium,high,critical \
        -c 50 \
        -rl 150 \
        -retries 2 \
        -o nuclei-results-graphql/01-graphql-misconfig.txt 2>/dev/null || echo "  [!] No GraphQL targets found"
fi
echo "  ✓ Complete"
echo ""

# 2. API documentation exposures (Swagger, OpenAPI, etc.)
echo "[2/6] API Documentation Exposures..."
if [ -f "$DIR_NAME/dev-tools.txt" ] && [ -s "$DIR_NAME/dev-tools.txt" ]; then
    nuclei -l "$DIR_NAME/dev-tools.txt" \
        -t /home/pwn/nuclei-templates/http/exposures/apis/ \
        -severity medium,high,critical \
        -c 50 \
        -rl 150 \
        -o nuclei-results-graphql/02-api-docs-exposure.txt 2>/dev/null || echo "  [!] No API doc targets"
fi
echo "  ✓ Complete"
echo ""

# 3. CVE-2025 & CVE-2024 on all 200 OK targets
echo "[3/6] Recent CVEs (2024-2025)..."
if [ -f "$DIR_NAME/all-urls.txt" ] && [ -s "$DIR_NAME/all-urls.txt" ]; then
    nuclei -l "$DIR_NAME/all-urls.txt" \
        -t /home/pwn/nuclei-templates/http/cves/2025/ \
        -t /home/pwn/nuclei-templates/http/cves/2024/ \
        -severity high,critical \
        -c 30 \
        -rl 100 \
        -retries 2 \
        -o nuclei-results-graphql/03-recent-cves.txt 2>/dev/null || echo "  [!] No CVE targets"
fi
echo "  ✓ Complete"
echo ""

# 4. Technology detection (to identify GraphQL implementations)
echo "[4/6] GraphQL Technology Detection..."
if [ -f "$DIR_NAME/all-urls.txt" ] && [ -s "$DIR_NAME/all-urls.txt" ]; then
    nuclei -l "$DIR_NAME/all-urls.txt" \
        -t /home/pwn/nuclei-templates/http/technologies/graphql/ \
        -c 50 \
        -rl 150 \
        -o nuclei-results-graphql/04-graphql-tech.txt 2>/dev/null || echo "  [!] Tech detection skipped"
fi
echo "  ✓ Complete"
echo ""

# 5. Exposed panels (Playground, Explorer, etc.)
echo "[5/6] Exposed Development Panels..."
if [ -f "$DIR_NAME/dev-tools.txt" ] && [ -s "$DIR_NAME/dev-tools.txt" ]; then
    nuclei -l "$DIR_NAME/dev-tools.txt" \
        -t /home/pwn/nuclei-templates/http/exposed-panels/ \
        -severity medium,high,critical \
        -c 50 \
        -rl 150 \
        -o nuclei-results-graphql/05-exposed-panels.txt 2>/dev/null || echo "  [!] Panel scan skipped"
fi
echo "  ✓ Complete"
echo ""

# 6. Token/API key exposure (for GraphQL endpoints)
echo "[6/6] API Key & Token Exposure..."
if [ -f "$DIR_NAME/api-endpoints.txt" ] && [ -s "$DIR_NAME/api-endpoints.txt" ]; then
    nuclei -l "$DIR_NAME/api-endpoints.txt" \
        -t /home/pwn/nuclei-templates/http/token-spray/ \
        -c 30 \
        -rl 100 \
        -o nuclei-results-graphql/06-token-exposure.txt 2>/dev/null || echo "  [!] Token scan skipped"
fi
echo "  ✓ Complete"
echo ""

echo "========================================"
echo "  GraphQL Scans Complete!"
echo "========================================"
echo ""
echo "Results: nuclei-results-graphql/"
ls -lh nuclei-results-graphql/ 2>/dev/null || echo "No results generated"

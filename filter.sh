#!/bin/bash
input_file="merged-crawl.txt"
output_file="crawledurls.txt"
param_file="param-urls.txt"
temp_file=$(mktemp)
challenge_noise='__cf_chl'
tracking_noise='^(utm_[a-z_]+|fbclid|gclid|msclkid|mc_eid|igshid|_zendesk)$'

trap 'rm -f "$temp_file"' EXIT

command -v httpx >/dev/null 2>&1 || { echo "Error: httpx not found in PATH"; exit 1; }

[ -f "$input_file" ] || { echo "Error: Input file '$input_file' not found in the current directory."; exit 1; }

read -r -p "Enter domain to filter (e.g., example.com): " domain

# Normalize + validate bare hostname only
domain=$(printf '%s' "$domain" | tr '[:upper:]' '[:lower:]')
if ! printf '%s\n' "$domain" | grep -qE '^[a-z0-9-]+(\.[a-z0-9-]+)*\.[a-z]{2,}$'; then
    echo "Invalid domain. Enter a bare hostname such as example.com"
    exit 1
fi

escaped_domain=$(printf '%s\n' "$domain" | sed 's/\./\\./g')

# Step 1: Filter to in-scope hosts.
#   - Match on normalized host (lowercase, port stripped) but output the original URL.
#   - Extra count check: crawler-concatenation junk (e.g. sub.example.comexample.com)
#     ends in ".example.com" so pure boundary matching would accept it — reject any host
#     where the apex domain appears more than once.
awk -v d="$domain" -v ed="$escaped_domain" '
{
    url = $0
    if (match(url, /^https?:\/\/[^\/?#]+/)) {
        host = substr(url, RSTART, RLENGTH)
        sub(/^https?:\/\//, "", host)
        sub(/:[0-9]+$/, "", host)
        host = tolower(host)
        if (host == d || host ~ ("\\." ed "$")) {
            n = gsub(ed, "&", host)
            if (n <= 1) print url
        }
    }
}' "$input_file" \
  | grep -aviE "$challenge_noise" \
  | sort -u > "$temp_file"
echo "[*] Domain-filtered URLs: $(wc -l < "$temp_file")"

# Step 2: Liveness — output is the original URL (plain httpx mode, no -sc/-cl parsing).
#         Do NOT pass -fr: redirects are intentionally not followed (default), so the
#         original URL is preserved. Keep WAF/403/401/429/5xx alive, drop 404s + errors.
httpx -silent -no-color -threads 100 -timeout 15 -retries 2 -fc 404,000 \
  < "$temp_file" | sort -u > "$output_file"
echo "[+] Clean URLs saved to $output_file: $(wc -l < "$output_file")"

# Step 3: Extract real key=value param URLs; strip fragments + tracking params but keep the URL.
awk -v track="$tracking_noise" '
{
    url = $0
    sub(/#.*/, "", url)            # fragments are not sent to the server
    if (url !~ /\?/) { next }
    q = url; sub(/^[^?]*\?/, "", q)
    n = split(q, parts, /&/)
    out = ""
    for (i = 1; i <= n; i++) {
        if (parts[i] !~ /=/) { continue }   # require key=value
        key = parts[i]; sub(/=.*/, "", key)
        if (key ~ track) { continue }        # drop tracking params, keep the URL
        out = (out == "" ? "" : out "&") parts[i]
    }
    if (out == "") { next }
    base = url; sub(/\?.*/, "", base)
    print base "?" out
}' "$output_file" | sort -u > "$param_file"
echo "[+] Param URLs saved to $param_file: $(wc -l < "$param_file")"

# Step 4: Extract PATH-parameterized API routes (query-param extraction above
# structurally misses REST/RPC routes where identifiers live in the path,
# e.g. /resource/XResource/create, /api/v3/pidgets/boards/{u}/{b}/pins,
# /url_shortener/{hex}/redirect, /users/12345/profile).
route_file="api-routes.txt"
awk '
{
    url = $0
    sub(/#.*/, "", url)
    sub(/\?.*/, "", url)
    host = ""
    if (match(url, /^https?:\/\/[^\/?#]+/)) {
        host = substr(url, RSTART, RLENGTH)
        sub(/^https?:\/\//, "", host)
        host = tolower(host)
    }
    path = url
    sub(/^https?:\/\/[^\/]+/, "", path)
    if (path !~ /\//) { next }
    n = split(path, seg, "/")
    hit = 0
    for (i = 1; i <= n; i++) {
        s = seg[i]
        if (s ~ /^[0-9]{3,}$/)                { hit = 1 }
        else if (s ~ /^[0-9a-fA-F]{8,}$/)     { hit = 1 }
        else if (s ~ /^v[0-9]+$/)             { hit = 1 }
        else if (tolower(s) == "resource")    { hit = 1 }
    }
    if (!hit && path ~ /\/(api\/v[0-9]+|resource)\//) { hit = 1 }
    if (!hit && host ~ /^api\./)                        { hit = 1 }
    if (hit) print url
}' "$output_file" | sort -u > "$route_file"
echo "[+] API routes saved to $route_file: $(wc -l < "$route_file")"

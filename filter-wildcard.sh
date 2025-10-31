#!/usr/bin/env bash
# validate-subdomains.sh
# Usage: ./filter-wildcard.sh allsubdomains.txt
set -euo pipefail

if [ $# -ne 1 ]; then
  echo "Usage: $0 allsubdomains.txt" >&2
  exit 2
fi

INPUT="$1"
[ -s "$INPUT" ] || { echo "Input file missing or empty: $INPUT" >&2; exit 2; }

# check deps
for cmd in dnsx jq anew awk sed sort; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "Require: $cmd" >&2; exit 2; }
done

# === OUTPUT DIRECTORY: user requested fixed name "results" ===
OUTDIR="$(pwd)/results"
if [ -d "$OUTDIR" ]; then
  echo "Warning: output directory '$OUTDIR' already exists — files inside may be overwritten."
else
  mkdir -p "$OUTDIR"
fi

TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

# random prefix for wildcard checks (safer than a constant string)
RANDPREFIX="pfx-$(date +%s)-$RANDOM-"
DNSX_THREADS=300
RETRY=3

# Step 1: initial dnsx probe (overwrite)
echo "[*] running initial dnsx probe..."
dnsx -l "$INPUT" -json -silent -stats -retry "$RETRY" -t "$DNSX_THREADS" > "$OUTDIR/dnsx-OUT.json"

# Step 2: extract hosts
jq -r '.host' "$OUTDIR/dnsx-OUT.json" | sort -u > "$OUTDIR/Hosts.txt"

# Step 3: wildcard detection — query prefixed hostnames
echo "[*] detecting wildcard entries with prefix: $RANDPREFIX"
awk -v p="$RANDPREFIX" '{print p $0}' "$OUTDIR/Hosts.txt" > "$TMPDIR/prefixed_hosts.txt"
dnsx -l "$TMPDIR/prefixed_hosts.txt" -json -silent -stats -retry "$RETRY" -t "$DNSX_THREADS" > "$OUTDIR/Wildcard.json"

# hosts that resolved when prefixed => probable wildcard (remove prefix)
jq -r '.host' "$OUTDIR/Wildcard.json" | sed "s/^$RANDPREFIX//" | sort -u > "$OUTDIR/Wildcards.txt"

# GOOD-Subdomains: hosts that are NOT wildcarded
comm -23 <(sort -u "$OUTDIR/Hosts.txt") <(sort -u "$OUTDIR/Wildcards.txt") > "$OUTDIR/GOOD-Subdomains.txt"

# ToCheck: hosts that need further per-record validation (start from wildcard candidates)
comm -12 <(sort -u "$OUTDIR/Hosts.txt") <(sort -u "$OUTDIR/Wildcards.txt") > "$OUTDIR/ToCheck.txt"

# function to validate by record type
validate_type() {
  local rtype="$1"
  [ -s "$OUTDIR/ToCheck.txt" ] || return 0

  echo "[*] validating record type: $rtype (hosts: $(wc -l < "$OUTDIR/ToCheck.txt"))"
  dnsx -l "$OUTDIR/ToCheck.txt" -resp -"$rtype" -silent -stats -retry "$RETRY" -t "$DNSX_THREADS" > "$OUTDIR/OUT_${rtype}.txt" || true

  awk -v p="$RANDPREFIX" '{print p $0}' "$OUTDIR/ToCheck.txt" > "$TMPDIR/prefixed_to_check.txt"
  dnsx -l "$TMPDIR/prefixed_to_check.txt" -resp -"$rtype" -silent -stats -retry "$RETRY" -t "$DNSX_THREADS" > "$OUTDIR/IN_${rtype}.txt" || true

  # normalize IN file: strip prefix and extract host column
  awk -v p="$RANDPREFIX" '{gsub(p,"",$1); print $1}' "$OUTDIR/IN_${rtype}.txt" | sort -u > "$TMPDIR/in_hosts_${rtype}.txt"
  awk '{print $1}' "$OUTDIR/OUT_${rtype}.txt" | sort -u > "$TMPDIR/out_hosts_${rtype}.txt"

  # keep hosts present in OUT but not in IN (likely real)
  comm -23 "$TMPDIR/out_hosts_${rtype}.txt" "$TMPDIR/in_hosts_${rtype}.txt" | sort -u > "$OUTDIR/confirmed_${rtype}.txt"

  # merge confirmed into GOOD-Subdomains
  if [ -s "$OUTDIR/confirmed_${rtype}.txt" ]; then
    cat "$OUTDIR/confirmed_${rtype}.txt" >> "$OUTDIR/GOOD-Subdomains.txt"
    sort -u -o "$OUTDIR/GOOD-Subdomains.txt" "$OUTDIR/GOOD-Subdomains.txt"
  fi

  # update ToCheck for next rounds
  if [ -s "$OUTDIR/confirmed_${rtype}.txt" ]; then
    comm -23 "$OUTDIR/ToCheck.txt" "$OUTDIR/confirmed_${rtype}.txt" > "$OUTDIR/ToCheck_next.txt" || true
    mv "$OUTDIR/ToCheck_next.txt" "$OUTDIR/ToCheck.txt"
  fi
}

# iterate record types
for t in a cname aaaa ns txt; do
  validate_type "$t"
done

# Finalize
sort -u -o "$OUTDIR/GOOD-Subdomains.txt" "$OUTDIR/GOOD-Subdomains.txt"
echo "Results in $OUTDIR"
echo "GOOD subdomains: $(wc -l < "$OUTDIR/GOOD-Subdomains.txt") lines"

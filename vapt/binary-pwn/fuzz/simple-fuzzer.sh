#!/bin/bash
# Simple Fuzzing Script for VAPT
# Version: 1.0 - Professional Grade
# Basic fuzzer for command-line applications and network services

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FUZZ_DIR="${SCRIPT_DIR}/fuzz"
mkdir -p "$FUZZ_DIR"

# Banner
banner() {
    echo -e "${CYAN}"
    cat << 'EOF'
╔═══════════════════════════════════════════════════════════╗
║              SIMPLE FUZZING TOOL                          ║
║            VAPT Professional Edition                      ║
╚═══════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# Logging
log_info() { echo -e "${BLUE}[*]${NC} $1"; }
log_good() { echo -e "${GREEN}[+]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[!]${NC} $1"; }
log_critical() { echo -e "${RED}[CRITICAL]${NC} $1"; }

# Generate fuzzing payload
generate_payload() {
    local type="$1"
    local size="${2:-100}"
    
    case "$type" in
        string)
            python3 -c "print('A' * $size)"
            ;;
        format)
            python3 -c "print('%s' * $size)"
            ;;
        integer)
            echo "$size"
            ;;
        negative)
            echo "-$size"
            ;;
        null)
            printf '\x00%.0s' $(seq 1 $size)
            ;;
        format_string)
            python3 -c "print('%x.' * $size)"
            ;;
        unicode)
            python3 -c "print('😀' * $size)"
            ;;
        path_traversal)
            python3 -c "print('../' * $size + 'etc/passwd')"
            ;;
        command_injection)
            echo "; id; #"
            ;;
        sql_injection)
            echo "' OR '1'='1"
            ;;
        xss)
            echo "<script>alert(1)</script>"
            ;;
        *)
            python3 -c "print('A' * $size)"
            ;;
    esac
}

# Fuzz command-line application
fuzz_cli() {
    local target="$1"
    local payload_type="${2:-string}"
    local max_size="${3:-1000}"
    local step="${4:-100}"
    
    log_info "Fuzzing CLI application: $target"
    log_info "Payload type: $payload_type"
    log_info "Max size: $max_size, Step: $step"
    
    local crash_file="${FUZZ_DIR}/crash_$(date +%s).txt"
    
    for (( size=$step; size<=$max_size; size+=$step )); do
        log_info "Testing with size: $size"
        
        payload=$(generate_payload "$payload_type" "$size")
        
        # Run with timeout
        if timeout 2 bash -c "echo '$payload' | $target" 2>&1 | grep -iE "(segfault|segmentation|crash|overflow|error)"; then
            log_critical "Crash detected at size $size!"
            echo "$payload" > "$crash_file"
            log_good "Payload saved to: $crash_file"
            return 0
        fi
        
        # Check return code
        echo "$payload" | timeout 2 $target 2>/dev/null
        local ret=$?
        if [[ $ret -eq 139 ]]; then  # SIGSEGV
            log_critical "Segmentation fault at size $size!"
            echo "$payload" > "$crash_file"
            return 0
        fi
    done
    
    log_good "No crashes found with $payload_type payloads up to size $max_size"
}

# Fuzz network service
fuzz_network() {
    local host="$1"
    local port="$2"
    local payload_type="${3:-string}"
    local max_size="${4:-1000}"
    local step="${5:-100}"
    
    log_info "Fuzzing network service: $host:$port"
    
    local crash_file="${FUZZ_DIR}/network_crash_$(date +%s).txt"
    
    for (( size=$step; size<=$max_size; size+=$step )); do
        log_info "Testing with size: $size"
        
        payload=$(generate_payload "$payload_type" "$size")
        
        # Send payload using netcat or Python
        if timeout 2 bash -c "echo '$payload' | nc -q 1 $host $port" 2>&1 | grep -iE "(crash|error|overflow)"; then
            log_critical "Interesting response at size $size!"
            echo "$payload" > "$crash_file"
        fi
        
        # Alternative: Python
        python3 << PYEOF 2>/dev/null
import socket
import sys

try:
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.settimeout(2)
    s.connect(("$host", $port))
    s.send(b"""$payload""" + b"\n")
    response = s.recv(1024)
    if b"error" in response.lower() or b"crash" in response.lower():
        print("Interesting response received")
    s.close()
except Exception as e:
    print(f"Connection error: {e}")
    sys.exit(1)
PYEOF

        if [[ $? -ne 0 ]]; then
            log_warn "Service may have crashed at size $size"
            echo "$payload" > "$crash_file"
            return 0
        fi
    done
    
    log_good "Fuzzing complete"
}

# Fuzz with wordlist
fuzz_wordlist() {
    local target="$1"
    local wordlist="$2"
    
    if [[ ! -f "$wordlist" ]]; then
        log_critical "Wordlist not found: $wordlist"
        return 1
    fi
    
    log_info "Fuzzing with wordlist: $wordlist"
    
    local count=0
    while IFS= read -r payload; do
        ((count++))
        
        if [[ $((count % 100)) -eq 0 ]]; then
            log_info "Tested $count payloads..."
        fi
        
        # Test payload
        if timeout 2 bash -c "echo '$payload' | $target" 2>&1 | grep -iE "(crash|error|exception)"; then
            log_critical "Interesting response for: $payload"
        fi
        
    done < "$wordlist"
    
    log_good "Fuzzed $count payloads from wordlist"
}

# Generate mutation-based payloads
fuzz_mutation() {
    local seed="$1"
    local count="${2:-100}"
    
    log_info "Generating $count mutation-based payloads from seed: $seed"
    
    for (( i=1; i<=$count; i++ )); do
        # Mutate seed
        local payload="$seed"
        
        # Random mutations
        local mutations=(
            "s/a/A/g"
            "s/e/E/g"
            "s/i/I/g"
            "s/o/O/g"
            "s/u/U/g"
            "s/0/zero/g"
            "s/1/one/g"
            "s/./\./g"
            "s/$/\\\\x00/"
            "s/^/\\\\x90/"
        )
        
        local num_mutations=$((RANDOM % 3 + 1))
        for (( m=0; m<$num_mutations; m++ )); do
            local mutation="${mutations[$RANDOM % ${#mutations[@]}]}"
            payload=$(echo "$payload" | sed "$mutation" 2>/dev/null || echo "$payload")
        done
        
        echo "$payload"
    done
}

# Run comprehensive fuzzing suite
comprehensive_fuzz() {
    local target="$1"
    
    log_info "Running comprehensive fuzzing suite..."
    
    local payload_types=("string" "format" "format_string" "unicode" "null" "integer" "negative")
    
    for ptype in "${payload_types[@]}"; do
        log_info "Testing with $ptype payloads..."
        fuzz_cli "$target" "$ptype" 500 50
    done
    
    log_good "Comprehensive fuzzing complete"
}

# Show usage
usage() {
    cat << 'EOF'
USAGE:
    ./simple-fuzzer.sh [OPTIONS]

OPTIONS:
    CLI Fuzzing:
    -c, --cli CMD             Fuzz CLI application
    -t, --type TYPE           Payload type (string/format/integer/null/...)
    --max-size SIZE           Maximum payload size [1000]
    --step SIZE               Size increment [100]
    
    Network Fuzzing:
    -n, --network HOST:PORT   Fuzz network service
    
    Wordlist Fuzzing:
    -w, --wordlist FILE       Use wordlist for fuzzing
    
    Other:
    --comprehensive CMD       Run comprehensive fuzzing
    --list-types              List available payload types
    -h, --help                Show this help

PAYLOAD TYPES:
    string          - String of A's
    format          - Format string (%s)
    format_string   - Format specifiers (%x)
    integer         - Large integers
    negative        - Negative numbers
    null            - Null bytes
    unicode         - Unicode characters
    path_traversal  - Path traversal (../)
    command_injection - Command injection
    sql_injection   - SQL injection
    xss             - XSS payloads

EXAMPLES:
    # Fuzz CLI with strings
    ./simple-fuzzer.sh -c ./program -t string --max-size 5000

    # Fuzz network service
    ./simple-fuzzer.sh -n 127.0.0.1:8080 -t string

    # Use wordlist
    ./simple-fuzzer.sh -c ./program -w /usr/share/wordlists/fuzzing.txt

    # Comprehensive fuzzing
    ./simple-fuzzer.sh --comprehensive ./program

    # Test with format strings
    ./simple-fuzzer.sh -c ./program -t format_string

EOF
}

# List payload types
list_types() {
    echo "Available payload types:"
    echo "  string          - String of A's"
    echo "  format          - Format string (%s)"
    echo "  format_string   - Format specifiers (%x)"
    echo "  integer         - Large integers"
    echo "  negative        - Negative numbers"
    echo "  null            - Null bytes"
    echo "  unicode         - Unicode characters"
    echo "  path_traversal  - Path traversal (../)"
    echo "  command_injection - Command injection"
    echo "  sql_injection   - SQL injection"
    echo "  xss             - XSS payloads"
}

# Main function
main() {
    local mode=""
    local target=""
    local payload_type="string"
    local max_size=1000
    local step=100
    local wordlist=""
    local host=""
    local port=""
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -c|--cli)
                mode="cli"
                target="$2"
                shift 2
                ;;
            -n|--network)
                mode="network"
                local hp="$2"
                host=$(echo "$hp" | cut -d: -f1)
                port=$(echo "$hp" | cut -d: -f2)
                shift 2
                ;;
            -t|--type)
                payload_type="$2"
                shift 2
                ;;
            --max-size)
                max_size="$2"
                shift 2
                ;;
            --step)
                step="$2"
                shift 2
                ;;
            -w|--wordlist)
                wordlist="$2"
                shift 2
                ;;
            --comprehensive)
                mode="comprehensive"
                target="$2"
                shift 2
                ;;
            --list-types)
                list_types
                exit 0
                ;;
            -h|--help)
                banner
                usage
                exit 0
                ;;
            *)
                log_warn "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done
    
    if [[ -z "$mode" ]]; then
        banner
        usage
        exit 1
    fi
    
    banner
    
    case "$mode" in
        cli)
            if [[ -n "$wordlist" ]]; then
                fuzz_wordlist "$target" "$wordlist"
            else
                fuzz_cli "$target" "$payload_type" "$max_size" "$step"
            fi
            ;;
        network)
            fuzz_network "$host" "$port" "$payload_type" "$max_size" "$step"
            ;;
        comprehensive)
            comprehensive_fuzz "$target"
            ;;
    esac
}

main "$@"

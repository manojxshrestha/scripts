#!/bin/bash
# Hash Identification & Cracking Tool
# Version: 1.0 - VAPT Professional
# Identifies hash types and automates cracking with multiple tools

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
HASHES_DIR="${SCRIPT_DIR}/hashes"
mkdir -p "$HASHES_DIR"

# Banner
banner() {
    echo -e "${CYAN}"
    cat << 'EOF'
╔═══════════════════════════════════════════════════════════╗
║        HASH IDENTIFICATION & CRACKING TOOL                ║
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

# Hash identification patterns
identify_hash() {
    local hash="$1"
    local length=${#hash}
    
    log_info "Analyzing hash: $hash"
    log_info "Length: $length characters"
    
    # Common hash types based on length and patterns
    declare -A hash_types
    
    case $length in
        32)
            if [[ "$hash" =~ ^[a-f0-9]+$ ]]; then
                hash_types["MD5"]="High probability"
                hash_types["MD4"]="Possible"
                hash_types["NTLM"]="Possible"
            fi
            ;;
        40)
            if [[ "$hash" =~ ^[a-f0-9]+$ ]]; then
                hash_types["SHA-1"]="High probability"
                hash_types["RIPEMD-160"]="Possible"
            fi
            ;;
        56)
            if [[ "$hash" =~ ^[a-f0-9]+$ ]]; then
                hash_types["SHA-224"]="High probability"
            fi
            ;;
        64)
            if [[ "$hash" =~ ^[a-f0-9]+$ ]]; then
                hash_types["SHA-256"]="High probability"
            fi
            ;;
        96)
            if [[ "$hash" =~ ^[a-f0-9]+$ ]]; then
                hash_types["SHA-384"]="High probability"
            fi
            ;;
        128)
            if [[ "$hash" =~ ^[a-f0-9]+$ ]]; then
                hash_types["SHA-512"]="High probability"
            fi
            ;;
        16)
            if [[ "$hash" =~ ^[a-f0-9]+$ ]]; then
                hash_types["MySQL"]="Possible"
                hash_types["Oracle"]="Possible"
            fi
            ;;
        13)
            if [[ "$hash" =~ ^[a-zA-Z0-9./]+$ ]]; then
                hash_types["DES (Unix)"]="Possible"
            fi
            ;;
        34)
            if [[ "$hash" =~ ^\$5\$ ]]; then
                hash_types["SHA-256 (Unix)"]="High probability"
            elif [[ "$hash" =~ ^\$6\$ ]]; then
                hash_types["SHA-512 (Unix)"]="Possible"
            fi
            ;;
        60)
            if [[ "$hash" =~ ^\$2[ayb]\$ ]]; then
                hash_types["bcrypt"]="High probability"
            fi
            ;;
        *)
            # Check for special patterns
            if [[ "$hash" =~ ^\$1\$ ]]; then
                hash_types["MD5 (Unix)"]="High probability"
            elif [[ "$hash" =~ ^\$apr1\$ ]]; then
                hash_types["MD5 (Apache)"]="High probability"
            elif [[ "$hash" =~ ^\$argon2 ]]; then
                hash_types["Argon2"]="High probability"
            elif [[ "$hash" =~ ^\$pbkdf2-sha256\$ ]]; then
                hash_types["PBKDF2-SHA256"]="High probability"
            elif [[ "$hash" =~ ^\$pbkdf2-sha512\$ ]]; then
                hash_types["PBKDF2-SHA512"]="High probability"
            elif [[ "$hash" =~ ^sha256\$ ]]; then
                hash_types["SHA-256 (Django)"]="High probability"
            elif [[ "$hash" =~ ^sha1\$ ]]; then
                hash_types["SHA-1 (Django)"]="High probability"
            elif [[ "$hash" =~ ^md5\$ ]]; then
                hash_types["MD5 (Django)"]="High probability"
            fi
            ;;
    esac
    
    # Check for Base64 encoded hashes
    if [[ "$hash" =~ ^[A-Za-z0-9+/]+={0,2}$ ]] && (( length % 4 == 0 )); then
        log_warn "Hash appears to be Base64 encoded"
        local decoded=$(echo "$hash" | base64 -d 2>/dev/null | xxd -p | tr -d '\n')
        if [[ -n "$decoded" ]]; then
            log_info "Decoded hex: $decoded"
            log_info "Decoded length: ${#decoded}"
        fi
    fi
    
    # Display results
    echo ""
    echo -e "${CYAN}Possible Hash Types:${NC}"
    if [[ ${#hash_types[@]} -eq 0 ]]; then
        log_warn "Unknown hash type or custom algorithm"
    else
        for type in "${!hash_types[@]}"; do
            echo -e "  ${GREEN}•${NC} $type - ${hash_types[$type]}"
        done
    fi
    
    return 0
}

# Crack with hashcat
crack_hashcat() {
    local hash="$1"
    local wordlist="${2:-/usr/share/wordlists/rockyou.txt}"
    local hash_type="${3:-0}"
    
    if ! command -v hashcat &> /dev/null; then
        log_warn "hashcat not found"
        return 1
    fi
    
    log_info "Attempting to crack with hashcat..."
    log_info "Hash type: $hash_type"
    log_info "Wordlist: $wordlist"
    
    # Create temporary file
    local tmpfile=$(mktemp)
    echo "$hash" > "$tmpfile"
    
    hashcat -m "$hash_type" "$tmpfile" "$wordlist" --force 2>/dev/null || \
    hashcat -m "$hash_type" "$tmpfile" "$wordlist" --force --optimized-kernel-enable 2>/dev/null
    
    rm -f "$tmpfile"
}

# Crack with John the Ripper
crack_john() {
    local hash="$1"
    local wordlist="${2:-/usr/share/wordlists/rockyou.txt}"
    local hash_format="${3:-}"
    
    if ! command -v john &> /dev/null; then
        log_warn "john not found"
        return 1
    fi
    
    log_info "Attempting to crack with John the Ripper..."
    
    local tmpfile=$(mktemp)
    echo "$hash" > "$tmpfile"
    
    if [[ -n "$hash_format" ]]; then
        john --format="$hash_format" --wordlist="$wordlist" "$tmpfile" 2>/dev/null
    else
        john --wordlist="$wordlist" "$tmpfile" 2>/dev/null
    fi
    
    john --show "$tmpfile" 2>/dev/null
    
    rm -f "$tmpfile"
}

# Generate hash
generate_hash() {
    local algorithm="$1"
    local input="$2"
    
    log_info "Generating $algorithm hash for: $input"
    
    case "$algorithm" in
        md5)
            echo -n "$input" | md5sum | cut -d' ' -f1
            ;;
        sha1)
            echo -n "$input" | sha1sum | cut -d' ' -f1
            ;;
        sha256)
            echo -n "$input" | sha256sum | cut -d' ' -f1
            ;;
        sha512)
            echo -n "$input" | sha512sum | cut -d' ' -f1
            ;;
        base64)
            echo -n "$input" | base64
            ;;
        base64url)
            echo -n "$input" | base64 | tr '+/' '-_' | tr -d '='
            ;;
        *)
            log_warn "Unknown algorithm: $algorithm"
            log_info "Supported: md5, sha1, sha256, sha512, base64, base64url"
            return 1
            ;;
    esac
}

# Compare two hashes
compare_hashes() {
    local hash1="$1"
    local hash2="$2"
    
    log_info "Comparing hashes..."
    log_info "Hash 1: $hash1"
    log_info "Hash 2: $hash2"
    
    if [[ "$hash1" == "$hash2" ]]; then
        log_good "Hashes match!"
    else
        log_warn "Hashes do not match"
        
        # Case insensitive comparison
        if [[ "${hash1,,}" == "${hash2,,}" ]]; then
            log_info "But they match case-insensitively"
        fi
    fi
}

# Rainbow table lookup (mock - would need actual tables)
rainbow_lookup() {
    local hash="$1"
    log_warn "Rainbow table lookup not implemented"
    log_info "Consider using online services:"
    echo "  - https://crackstation.net"
    echo "  - https://hashkiller.io"
    echo "  - https://hashes.org"
}

# Batch processing
batch_process() {
    local file="$1"
    
    if [[ ! -f "$file" ]]; then
        log_critical "File not found: $file"
        return 1
    fi
    
    log_info "Processing hashes from: $file"
    
    local count=0
    while IFS= read -r line; do
        # Skip empty lines and comments
        [[ -z "$line" || "$line" =~ ^# ]] && continue
        
        ((count++))
        echo ""
        echo -e "${CYAN}[$count] Analyzing: $line${NC}"
        identify_hash "$line"
    done < "$file"
    
    log_good "Processed $count hashes"
}

# Show usage
usage() {
    cat << 'EOF'
USAGE:
    ./hash-cracker.sh [OPTIONS] [HASH]

OPTIONS:
    -i, --identify HASH       Identify hash type
    -c, --crack HASH          Crack hash (auto-identify + crack)
    -t, --type TYPE           Specify hash type for cracking
    -w, --wordlist FILE       Wordlist file (default: rockyou.txt)
    -g, --generate ALGO TEXT  Generate hash
    --compare HASH1 HASH2     Compare two hashes
    -b, --batch FILE          Batch process file of hashes
    --hashcat                 Use hashcat for cracking
    --john                    Use John for cracking
    -h, --help                Show this help

EXAMPLES:
    # Identify hash
    ./hash-cracker.sh -i "5f4dcc3b5aa765d61d8327deb882cf99"

    # Crack with auto-detection
    ./hash-cracker.sh -c "5f4dcc3b5aa765d61d8327deb882cf99"

    # Crack with specific type
    ./hash-cracker.sh -c "hash" -t 0 -w /path/to/wordlist.txt

    # Generate hash
    ./hash-cracker.sh -g md5 "password"

    # Batch process
    ./hash-cracker.sh -b hashes.txt

    # Compare hashes
    ./hash-cracker.sh --compare "hash1" "hash2"

HASH TYPES (for hashcat -t option):
    0     MD5
    100   SHA-1
    1400  SHA-256
    1700  SHA-512
    1000  NTLM
    1800  SHA-512 (Unix)
    3200  bcrypt
    See: https://hashcat.net/wiki/doku.php?id=example_hashes

EOF
}

# Interactive mode
interactive_mode() {
    banner
    
    while true; do
        echo ""
        echo -e "${CYAN}Hash Cracker Menu:${NC}"
        echo "1. Identify hash"
        echo "2. Crack hash"
        echo "3. Generate hash"
        echo "4. Compare hashes"
        echo "5. Batch process"
        echo "0. Exit"
        echo ""
        read -p "Select option: " choice
        
        case $choice in
            1)
                read -p "Enter hash: " hash
                identify_hash "$hash"
                ;;
            2)
                read -p "Enter hash: " hash
                read -p "Wordlist [rockyou.txt]: " wordlist
                wordlist=${wordlist:-/usr/share/wordlists/rockyou.txt}
                identify_hash "$hash"
                echo ""
                read -p "Try to crack? [y/N]: " crack
                if [[ "$crack" =~ ^[Yy]$ ]]; then
                    if command -v hashcat &> /dev/null; then
                        crack_hashcat "$hash" "$wordlist"
                    elif command -v john &> /dev/null; then
                        crack_john "$hash" "$wordlist"
                    else
                        log_warn "No cracking tools found"
                    fi
                fi
                ;;
            3)
                read -p "Algorithm (md5/sha1/sha256/sha512): " algo
                read -p "Text to hash: " text
                generate_hash "$algo" "$text"
                ;;
            4)
                read -p "Hash 1: " hash1
                read -p "Hash 2: " hash2
                compare_hashes "$hash1" "$hash2"
                ;;
            5)
                read -p "File path: " file
                batch_process "$file"
                ;;
            0)
                exit 0
                ;;
            *)
                log_warn "Invalid option"
                ;;
        esac
    done
}

# Main function
main() {
    local operation=""
    local hash=""
    local hash_type=""
    local wordlist="/usr/share/wordlists/rockyou.txt"
    local use_hashcat=false
    local use_john=false
    local batch_file=""
    local hash1=""
    local hash2=""
    local algo=""
    local text=""
    
    # No arguments = interactive mode
    if [[ $# -eq 0 ]]; then
        interactive_mode
        exit 0
    fi
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -i|--identify)
                operation="identify"
                hash="$2"
                shift 2
                ;;
            -c|--crack)
                operation="crack"
                hash="$2"
                shift 2
                ;;
            -t|--type)
                hash_type="$2"
                shift 2
                ;;
            -w|--wordlist)
                wordlist="$2"
                shift 2
                ;;
            -g|--generate)
                operation="generate"
                algo="$2"
                text="$3"
                shift 3
                ;;
            --compare)
                operation="compare"
                hash1="$2"
                hash2="$3"
                shift 3
                ;;
            -b|--batch)
                operation="batch"
                batch_file="$2"
                shift 2
                ;;
            --hashcat)
                use_hashcat=true
                shift
                ;;
            --john)
                use_john=true
                shift
                ;;
            -h|--help)
                banner
                usage
                exit 0
                ;;
            *)
                if [[ -z "$hash" && "$1" != -* ]]; then
                    hash="$1"
                    operation="identify"
                    shift
                else
                    log_warn "Unknown option: $1"
                    usage
                    exit 1
                fi
                ;;
        esac
    done
    
    # Execute operation
    case "$operation" in
        identify)
            banner
            identify_hash "$hash"
            ;;
        crack)
            banner
            identify_hash "$hash"
            echo ""
            if [[ "$use_hashcat" == true ]]; then
                crack_hashcat "$hash" "$wordlist" "$hash_type"
            elif [[ "$use_john" == true ]]; then
                crack_john "$hash" "$wordlist" "$hash_type"
            else
                # Try both
                if command -v hashcat &> /dev/null; then
                    crack_hashcat "$hash" "$wordlist" "$hash_type"
                elif command -v john &> /dev/null; then
                    crack_john "$hash" "$wordlist" "$hash_type"
                else
                    log_warn "No cracking tools found (hashcat or john)"
                fi
            fi
            ;;
        generate)
            banner
            generate_hash "$algo" "$text"
            ;;
        compare)
            banner
            compare_hashes "$hash1" "$hash2"
            ;;
        batch)
            banner
            batch_process "$batch_file"
            ;;
        *)
            banner
            usage
            ;;
    esac
}

main "$@"

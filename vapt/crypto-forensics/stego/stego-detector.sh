#!/bin/bash
# Steganography Detection Tool
# Version: 1.0 - VAPT Professional
# Detects hidden data in images, audio, and other files

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
STEGO_DIR="${SCRIPT_DIR}/stego"
mkdir -p "$STEGO_DIR"

# Banner
banner() {
    echo -e "${CYAN}"
    cat << 'EOF'
╔═══════════════════════════════════════════════════════════╗
║          STEGANOGRAPHY DETECTION TOOL                     ║
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

# Check for steganography tools
check_tools() {
    local tools=("steghide" "stegseek" "zsteg" "binwalk" "exiftool" "strings" "xxd")
    
    log_info "Checking for steganography tools..."
    
    for tool in "${tools[@]}"; do
        if command -v "$tool" &> /dev/null; then
            log_good "$tool: Found"
        else
            log_warn "$tool: Not installed"
        fi
    done
}

# Analyze image with exiftool
analyze_metadata() {
    local file="$1"
    
    log_info "Analyzing metadata with exiftool..."
    
    if ! command -v exiftool &> /dev/null; then
        log_warn "exiftool not installed"
        return
    fi
    
    exiftool "$file" 2>/dev/null | while read -r line; do
        # Look for suspicious metadata
        if [[ "$line" =~ (Comment|Copyright|Author|Title|Description|Software) ]]; then
            log_warn "Metadata: $line"
        else
            echo "  $line"
        fi
    done
}

# Check for LSB steganography in images
check_lsb() {
    local file="$1"
    
    log_info "Checking for LSB (Least Significant Bit) steganography..."
    
    if command -v zsteg &> /dev/null; then
        log_info "Running zsteg..."
        zsteg "$file" 2>/dev/null | head -50 | while read -r line; do
            if [[ "$line" =~ (flag|password|key|secret|hidden|message) ]]; then
                log_critical "Potential hidden data: $line"
            else
                echo "  $line"
            fi
        done
    else
        log_warn "zsteg not installed (gem install zsteg)"
    fi
    
    # Check with strings for readable text
    log_info "Extracting strings from image..."
    strings "$file" 2>/dev/null | grep -E "^.{4,}$" | head -20 | while read -r line; do
        if [[ "$line" =~ (flag|password|key|secret|http|base64) ]]; then
            log_warn "Interesting string: $line"
        fi
    done
}

# Check for steghide
extract_steghide() {
    local file="$1"
    
    log_info "Attempting steghide extraction..."
    
    if ! command -v steghide &> /dev/null; then
        log_warn "steghide not installed"
        return
    fi
    
    # Try without password
    log_info "Trying empty password..."
    if steghide extract -sf "$file" -p "" -xf "${STEGO_DIR}/steghide_extract.txt" 2>/dev/null; then
        log_critical "Data extracted with empty password!"
        cat "${STEGO_DIR}/steghide_extract.txt"
    else
        log_info "No data with empty password"
    fi
    
    # Try common passwords if stegseek is available
    if command -v stegseek &> /dev/null; then
        log_info "Running stegseek with wordlist..."
        if stegseek "$file" /usr/share/wordlists/rockyou.txt -xf "${STEGO_DIR}/stegseek_extract.txt" 2>/dev/null; then
            log_critical "Password found and data extracted!"
            cat "${STEGO_DIR}/stegseek_extract.txt"
        fi
    fi
}

# Check for embedded files with binwalk
extract_binwalk() {
    local file="$1"
    
    log_info "Scanning for embedded files with binwalk..."
    
    if ! command -v binwalk &> /dev/null; then
        log_warn "binwalk not installed"
        return
    fi
    
    binwalk "$file" 2>/dev/null | while read -r line; do
        if [[ "$line" =~ (Zip|PNG|JPEG|PDF|executable|archive) ]]; then
            log_warn "Embedded data found: $line"
        else
            echo "  $line"
        fi
    done
    
    # Try to extract
    log_info "Attempting extraction..."
    binwalk -e "$file" -C "$STEGO_DIR" 2>/dev/null && log_good "Files extracted to: $STEGO_DIR"
}

# Check for outguess
extract_outguess() {
    local file="$1"
    
    log_info "Attempting outguess extraction..."
    
    if ! command -v outguess &> /dev/null; then
        log_warn "outguess not installed"
        return
    fi
    
    if outguess -r "$file" "${STEGO_DIR}/outguess_extract.txt" 2>/dev/null; then
        log_critical "Data extracted with outguess!"
        cat "${STEGO_DIR}/outguess_extract.txt"
    else
        log_info "No outguess data found"
    fi
}

# Check for audio steganography (spectrogram)
analyze_audio() {
    local file="$1"
    
    log_info "Analyzing audio file for steganography..."
    
    # Check for silenteye
    if command -v silenteye &> /dev/null; then
        log_info "Try: silenteye -f $file"
    fi
    
    # Extract raw audio data
    log_info "Extracting raw data..."
    strings "$file" 2>/dev/null | grep -E "^.{8,}$" | head -10 | while read -r line; do
        if [[ "$line" =~ (flag|password|key|secret) ]]; then
            log_warn "Interesting string: $line"
        fi
    done
}

# Analyze file entropy (high entropy may indicate encryption/stego)
check_entropy() {
    local file="$1"
    
    log_info "Calculating file entropy..."
    
    if command -v ent &> /dev/null; then
        ent "$file" 2>/dev/null | head -10
    else
        # Simple entropy calculation with Python
        python3 << PYEOF 2>/dev/null || log_warn "Python not available for entropy calculation"
import sys
import math
from collections import Counter

with open("$file", 'rb') as f:
    data = f.read()
    
if len(data) == 0:
    print("Empty file")
    sys.exit(0)
    
counter = Counter(data)
entropy = -sum((count/len(data)) * math.log2(count/len(data)) for count in counter.values())
print(f"Entropy: {entropy:.4f} bits/byte")
print(f"File size: {len(data)} bytes")

if entropy > 7.5:
    print("High entropy - possibly encrypted or compressed")
elif entropy < 1.0:
    print("Very low entropy - possibly mostly zeros")
else:
    print("Normal entropy")
PYEOF
    fi
}

# Check for whitespace steganography (snow)
check_whitespace() {
    local file="$1"
    
    log_info "Checking for whitespace steganography..."
    
    if command -v stegsnow &> /dev/null; then
        if stegsnow -C "$file" 2>/dev/null | grep -v "^$"; then
            log_warn "Potential whitespace steganography detected"
        fi
    fi
}

# Full analysis
full_analysis() {
    local file="$1"
    
    if [[ ! -f "$file" ]]; then
        log_critical "File not found: $file"
        return 1
    fi
    
    log_info "Starting full steganography analysis..."
    log_info "Target file: $file"
    log_info "File type: $(file "$file" 2>/dev/null || echo "Unknown")"
    echo ""
    
    check_tools
    echo ""
    
    analyze_metadata "$file"
    echo ""
    
    check_entropy "$file"
    echo ""
    
    # Determine file type and run appropriate checks
    local filetype=$(file -b "$file" 2>/dev/null | tr '[:upper:]' '[:lower:]')
    
    if [[ "$filetype" =~ (image|png|jpeg|jpg|gif|bmp) ]]; then
        log_info "Image file detected"
        check_lsb "$file"
        extract_steghide "$file"
        extract_outguess "$file"
        extract_binwalk "$file"
    elif [[ "$filetype" =~ (audio|wav|mp3|ogg) ]]; then
        log_info "Audio file detected"
        analyze_audio "$file"
    elif [[ "$filetype" =~ (text|ascii) ]]; then
        log_info "Text file detected"
        check_whitespace "$file"
    else
        log_info "Unknown/Other file type"
        extract_binwalk "$file"
        check_lsb "$file"
    fi
    
    log_good "Analysis complete!"
    log_info "Check $STEGO_DIR for extracted files"
}

# Show usage
usage() {
    cat << 'EOF'
USAGE:
    ./stego-detector.sh [OPTIONS] FILE

OPTIONS:
    -f, --file FILE           Target file to analyze
    -m, --metadata            Analyze metadata only
    -l, --lsb                 Check LSB steganography only
    -s, --steghide            Try steghide extraction only
    -b, --binwalk             Use binwalk only
    -e, --entropy             Check file entropy
    --tools                   List required tools
    -h, --help                Show this help

EXAMPLES:
    # Full analysis
    ./stego-detector.sh -f image.jpg

    # Analyze metadata only
    ./stego-detector.sh -m -f image.png

    # Extract with specific tool
    ./stego-detector.sh -s -f image.jpg

    # Check multiple files
    for img in *.jpg; do ./stego-detector.sh -f "$img"; done

REQUIRED TOOLS:
    steghide    - Hide data in images
    stegseek    - Steghide brute forcer
    zsteg       - LSB steganography detection
    binwalk     - Firmware analysis tool
    exiftool    - Metadata reader
    outguess    - Universal steganographic tool

INSTALLATION:
    apt install steghide stegseek binwalk exiftool outguess
    gem install zsteg

EOF
}

# Main function
main() {
    local file=""
    local mode="full"
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -f|--file)
                file="$2"
                shift 2
                ;;
            -m|--metadata)
                mode="metadata"
                shift
                ;;
            -l|--lsb)
                mode="lsb"
                shift
                ;;
            -s|--steghide)
                mode="steghide"
                shift
                ;;
            -b|--binwalk)
                mode="binwalk"
                shift
                ;;
            -e|--entropy)
                mode="entropy"
                shift
                ;;
            --tools)
                banner
                check_tools
                exit 0
                ;;
            -h|--help)
                banner
                usage
                exit 0
                ;;
            *)
                if [[ -z "$file" && "$1" != -* ]]; then
                    file="$1"
                    shift
                else
                    log_warn "Unknown option: $1"
                    usage
                    exit 1
                fi
                ;;
        esac
    done
    
    if [[ -z "$file" ]]; then
        banner
        usage
        exit 1
    fi
    
    banner
    
    case "$mode" in
        full)
            full_analysis "$file"
            ;;
        metadata)
            analyze_metadata "$file"
            ;;
        lsb)
            check_lsb "$file"
            ;;
        steghide)
            extract_steghide "$file"
            ;;
        binwalk)
            extract_binwalk "$file"
            ;;
        entropy)
            check_entropy "$file"
            ;;
    esac
}

main "$@"

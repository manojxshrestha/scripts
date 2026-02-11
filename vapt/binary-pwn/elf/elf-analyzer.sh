#!/bin/bash
# ELF Binary Analyzer for VAPT
# Version: 1.0 - Professional Grade
# Analyzes ELF binaries for security features and vulnerabilities

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
ELF_DIR="${SCRIPT_DIR}/elf"
mkdir -p "$ELF_DIR"

# Banner
banner() {
    echo -e "${CYAN}"
    cat << 'EOF'
╔═══════════════════════════════════════════════════════════╗
║             ELF BINARY ANALYZER                           ║
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

# Section headers
section() {
    echo ""
    echo -e "${MAGENTA}========================================${NC}"
    echo -e "${MAGENTA}  $1${NC}"
    echo -e "${MAGENTA}========================================${NC}"
    echo ""
}

# Check binary type and basic info
check_basic_info() {
    local binary="$1"
    
    section "BASIC INFORMATION"
    
    log_info "File: $binary"
    log_info "File type:"
    file "$binary"
    
    log_info "File size:"
    ls -lh "$binary" | awk '{print $5}'
    
    log_info "MD5:"
    md5sum "$binary" | cut -d' ' -f1
    
    log_info "SHA256:"
    sha256sum "$binary" | cut -d' ' -f1
    
    log_info "Strings (interesting):"
    strings "$binary" 2>/dev/null | grep -iE "(password|flag|key|secret|admin|root|/bin/sh|/bin/bash)" | head -10 || log_info "No obvious strings found"
}

# Check security features
check_security_features() {
    local binary="$1"
    
    section "SECURITY FEATURES"
    
    # Check if checksec is available
    if command -v checksec &> /dev/null; then
        log_info "Running checksec..."
        checksec --file="$binary" 2>/dev/null || checksec -f "$binary" 2>/dev/null
    else
        log_warn "checksec not installed, running manual checks..."
        
        # NX (No Execute)
        if readelf -l "$binary" 2>/dev/null | grep -q "GNU_STACK" && readelf -l "$binary" 2>/dev/null | grep "GNU_STACK" | grep -q "RWE"; then
            log_warn "NX Disabled - Stack is executable!"
        else
            log_good "NX Enabled - Stack is not executable"
        fi
        
        # PIE (Position Independent Executable)
        if readelf -h "$binary" 2>/dev/null | grep -q "Type:.*DYN"; then
            log_good "PIE Enabled"
        else
            log_warn "PIE Disabled - Binary is not position independent"
        fi
        
        # Stack Canary
        if readelf -s "$binary" 2>/dev/null | grep -q "__stack_chk_fail"; then
            log_good "Stack Canary Enabled"
        else
            log_warn "Stack Canary Disabled"
        fi
        
        # RELRO
        if readelf -d "$binary" 2>/dev/null | grep -q "BIND_NOW"; then
            log_good "Full RELRO Enabled"
        elif readelf -d "$binary" 2>/dev/null | grep -q "GNU_RELRO"; then
            log_warn "Partial RELRO"
        else
            log_warn "No RELRO"
        fi
        
        # Fortify Source
        if readelf -s "$binary" 2>/dev/null | grep -q "__fortify"; then
            log_good "Fortify Source Enabled"
        else
            log_warn "Fortify Source Disabled"
        fi
    fi
}

# Analyze symbols
analyze_symbols() {
    local binary="$1"
    
    section "SYMBOL ANALYSIS"
    
    log_info "Dynamic symbols:"
    readelf -s "$binary" 2>/dev/null | head -30
    
    log_info "Imported functions (suspicious):"
    readelf -s "$binary" 2>/dev/null | grep -E "(system|execve|execv|execvp|execl|execle|execlp|popen|gets|strcpy|sprintf|scanf|mprotect|mmap)" | while read -r line; do
        log_warn "Dangerous function: $line"
    done
    
    log_info "Exported functions:"
    readelf --dyn-syms "$binary" 2>/dev/null | grep -v "^$" | tail -20
}

# Check for PLT/GOT
check_plt_got() {
    local binary="$1"
    
    section "PLT/GOT ANALYSIS"
    
    log_info "PLT entries:"
    objdump -d -j .plt "$binary" 2>/dev/null | head -30 || log_warn "No PLT section"
    
    log_info "GOT entries:"
    readelf -r "$binary" 2>/dev/null | head -20 || log_warn "No relocation entries"
    
    log_info "Writable GOT entries (potential GOT overwrite):"
    readelf -S "$binary" 2>/dev/null | grep -E "\.got" | while read -r line; do
        if [[ "$line" =~ WA ]]; then
            log_critical "GOT is writable: $line"
        fi
    done
}

# Analyze sections
analyze_sections() {
    local binary="$1"
    
    section "SECTION ANALYSIS"
    
    log_info "Section headers:"
    readelf -S "$binary" 2>/dev/null
    
    log_info "Executable sections:"
    readelf -S "$binary" 2>/dev/null | grep "X" | while read -r line; do
        echo "  $line"
    done
    
    log_info "Writable sections:"
    readelf -S "$binary" 2>/dev/null | grep "W" | while read -r line; do
        echo "  $line"
    done
}

# Check for ROP gadgets
check_rop_gadgets() {
    local binary="$1"
    
    section "ROP GADGET ANALYSIS"
    
    if command -v ROPgadget &> /dev/null; then
        log_info "Searching for ROP gadgets..."
        log_info "Common gadgets:"
        ROPgadget --binary "$binary" 2>/dev/null | grep -E "(pop rdi|pop rsi|pop rdx|ret|syscall|int 0x80)" | head -10
        
        log_info "Total gadgets found:"
        ROPgadget --binary "$binary" 2>/dev/null | grep "Unique gadgets" || echo "Unknown"
    elif command -v ropper &> /dev/null; then
        log_info "Using ropper for gadget search..."
        ropper -f "$binary" --search "pop rdi" 2>/dev/null | head -5
    else
        log_warn "ROPgadget or ropper not installed"
        log_info "Install: pip install ropgadget"
    fi
    
    # Manual search for common gadgets
    log_info "Manual gadget search (strings):"
    objdump -d "$binary" 2>/dev/null | grep -E "(pop|ret|syscall)" | head -10
}

# Check for format string vulnerabilities
check_format_strings() {
    local binary="$1"
    
    section "FORMAT STRING ANALYSIS"
    
    log_info "Searching for format string functions..."
    strings "$binary" 2>/dev/null | grep -E "(printf|sprintf|fprintf|snprintf)" | sort -u | while read -r line; do
        echo "  $line"
    done
    
    # Check if printf is used with user-controlled data
    if readelf -s "$binary" 2>/dev/null | grep -q "printf"; then
        log_warn "Binary uses printf family functions - check for format string vulnerabilities"
    fi
}

# Check for buffer overflow indicators
check_buffer_overflow() {
    local binary="$1"
    
    section "BUFFER OVERFLOW INDICATORS"
    
    log_info "Dangerous functions present:"
    local dangerous_funcs=("gets" "strcpy" "strcat" "sprintf" "scanf" "fscanf" "sscanf" "vscanf" "vsscanf" "vfscanf" "realpath" "getwd")
    
    for func in "${dangerous_funcs[@]}"; do
        if readelf -s "$binary" 2>/dev/null | grep -q "$func"; then
            log_critical "Dangerous function found: $func - Potential buffer overflow!"
        fi
    done
    
    log_info "Safe alternatives (if using safe functions):"
    if readelf -s "$binary" 2>/dev/null | grep -qE "strncpy|strncat|snprintf|fgets"; then
        log_good "Some safe functions found"
    fi
}

# Extract interesting data
extract_data() {
    local binary="$1"
    
    section "DATA EXTRACTION"
    
    log_info "All readable strings:"
    strings "$binary" > "${ELF_DIR}/$(basename "$binary").strings"
    log_good "Saved to: ${ELF_DIR}/$(basename "$binary").strings"
    
    log_info "Interesting patterns:"
    strings "$binary" | grep -E "(http|ftp|/|\\.txt|\\.conf|\\.key)" | head -20
    
    log_info "Potential passwords/keys:"
    strings "$binary" | grep -iE "(password=|passwd=|key=|secret=|token=)" | head -10
}

# Generate exploit template
generate_exploit_template() {
    local binary="$1"
    local template_file="${ELF_DIR}/exploit_$(basename "$binary").py"
    
    section "EXPLOIT TEMPLATE"
    
    cat > "$template_file" << 'EOF'
#!/usr/bin/env python3
# Exploit template for: BINARY_NAME
# Generated by ELF Analyzer

from pwn import *

# Configuration
BINARY = './BINARY_NAME'
HOST = 'target.host'
PORT = 1337

# Context
context.log_level = 'info'
context.arch = 'ARCH'
context.os = 'linux'

# Load binary
elf = ELF(BINARY)

# Gadgets (update after running ROPgadget)
POP_RDI = 0x0000000000000000  # pop rdi; ret
POP_RSI = 0x0000000000000000  # pop rsi; ret
POP_RDX = 0x0000000000000000  # pop rdx; ret
POP_RAX = 0x0000000000000000  # pop rax; ret
SYSCALL = 0x0000000000000000  # syscall
BIN_SH = 0x0000000000000000   # /bin/sh string

# Addresses
PRINTF_GOT = elf.got['printf']
PRINTF_PLT = elf.plt['printf']
MAIN = elf.symbols.get('main', 0)

def local():
    return process(BINARY)

def remote():
    return remote(HOST, PORT)

def exploit(p):
    # Build your exploit here
    payload = b''
    payload += b'A' * 100  # Fill buffer
    payload += p64(0x0)    # Overwrite saved RBP
    payload += p64(0x0)    # Overwrite return address
    
    # Send payload
    p.sendline(payload)
    
    # Interact
    p.interactive()

if __name__ == '__main__':
    # Choose target
    # p = local()
    p = remote()
    
    # Run exploit
    exploit(p)
EOF

    # Replace placeholders
    sed -i "s/BINARY_NAME/$(basename "$binary")/g" "$template_file"
    
    # Detect architecture
    if file "$binary" | grep -q "64-bit"; then
        sed -i 's/ARCH/amd64/g' "$template_file"
    else
        sed -i 's/ARCH/i386/g' "$template_file"
    fi
    
    chmod +x "$template_file"
    log_good "Exploit template saved: $template_file"
}

# Show usage
usage() {
    cat << 'EOF'
USAGE:
    ./elf-analyzer.sh [OPTIONS] BINARY

OPTIONS:
    -f, --file BINARY         Target binary to analyze
    -s, --security            Check security features only
    -r, --rop                 Check ROP gadgets only
    -e, --exploit             Generate exploit template
    -o, --output DIR          Output directory
    --strings                 Extract strings only
    -a, --all                 Full analysis (default)
    -h, --help                Show this help

EXAMPLES:
    # Full analysis
    ./elf-analyzer.sh -f ./program

    # Check security features
    ./elf-analyzer.sh -f ./program -s

    # Generate exploit template
    ./elf-analyzer.sh -f ./program -e

    # ROP analysis only
    ./elf-analyzer.sh -f ./program -r

REQUIRED TOOLS:
    readelf, objdump, file    - Usually pre-installed
    checksec                  - Optional, for security checks
    ROPgadget/ropper          - Optional, for ROP analysis
    strings                   - Usually pre-installed

INSTALLATION:
    apt install binutils
    pip install ropgadget
    pip install ropper

EOF
}

# Main function
main() {
    local binary=""
    local mode="all"
    local output_dir="$ELF_DIR"
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -f|--file)
                binary="$2"
                shift 2
                ;;
            -s|--security)
                mode="security"
                shift
                ;;
            -r|--rop)
                mode="rop"
                shift
                ;;
            -e|--exploit)
                mode="exploit"
                shift
                ;;
            --strings)
                mode="strings"
                shift
                ;;
            -o|--output)
                output_dir="$2"
                mkdir -p "$output_dir"
                shift 2
                ;;
            -a|--all)
                mode="all"
                shift
                ;;
            -h|--help)
                banner
                usage
                exit 0
                ;;
            *)
                if [[ -z "$binary" && "$1" != -* ]]; then
                    binary="$1"
                    shift
                else
                    log_warn "Unknown option: $1"
                    usage
                    exit 1
                fi
                ;;
        esac
    done
    
    if [[ -z "$binary" ]]; then
        banner
        usage
        exit 1
    fi
    
    if [[ ! -f "$binary" ]]; then
        log_critical "Binary not found: $binary"
        exit 1
    fi
    
    # Check if it's an ELF
    if ! file "$binary" | grep -q "ELF"; then
        log_warn "File may not be an ELF binary"
    fi
    
    banner
    
    case "$mode" in
        all)
            check_basic_info "$binary"
            check_security_features "$binary"
            analyze_symbols "$binary"
            check_plt_got "$binary"
            analyze_sections "$binary"
            check_rop_gadgets "$binary"
            check_format_strings "$binary"
            check_buffer_overflow "$binary"
            extract_data "$binary"
            generate_exploit_template "$binary"
            ;;
        security)
            check_basic_info "$binary"
            check_security_features "$binary"
            check_buffer_overflow "$binary"
            ;;
        rop)
            check_basic_info "$binary"
            check_security_features "$binary"
            check_rop_gadgets "$binary"
            ;;
        exploit)
            check_basic_info "$binary"
            check_security_features "$binary"
            analyze_symbols "$binary"
            generate_exploit_template "$binary"
            ;;
        strings)
            extract_data "$binary"
            ;;
    esac
    
    log_good "Analysis complete!"
}

main "$@"

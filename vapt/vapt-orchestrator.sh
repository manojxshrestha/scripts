#!/bin/bash
# VAPT Master Orchestrator
# Version: 1.0 - Professional Grade
# Central control script for all VAPT automation tools

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Banner
banner() {
    clear
    echo -e "${CYAN}"
    cat << 'EOF'
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║           VAPT AUTOMATION FRAMEWORK                       ║
║              Master Orchestrator v1.0                     ║
║                                                           ║
║     Vulnerability Assessment & Penetration Testing        ║
║              Professional Edition                         ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# Show main menu
show_menu() {
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  MAIN MENU${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${YELLOW}4. Exploitation Helpers${NC}"
    echo "   41. Payload Generator"
    echo "   42. Reverse Shell Generator"
    echo "   43. Encoding & Obfuscation Toolkit"
    echo ""
    echo -e "${YELLOW}5. Post-Exploitation${NC}"
    echo "   51. Linux Privilege Escalation Checker"
    echo "   52. Windows Privilege Escalation Checker"
    echo "   53. Credential Harvester"
    echo ""
    echo -e "${YELLOW}6. Cryptography & Forensics${NC}"
    echo "   61. Hash Cracker (Identify & Crack)"
    echo "   62. Log Analyzer"
    echo "   63. Steganography Detector"
    echo ""
    echo -e "${YELLOW}8. Binary Exploitation${NC}"
    echo "   81. ELF Binary Analyzer"
    echo "   82. Simple Fuzzer"
    echo ""
    echo -e "${GREEN}9. Utilities${NC}"
    echo "   91. Show Tool Paths"
    echo "   92. Check Dependencies"
    echo "   93. Update Tools"
    echo ""
    echo -e "${RED}0. Exit${NC}"
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
}

# Logging
log_info() { echo -e "${BLUE}[*]${NC} $1"; }
log_good() { echo -e "${GREEN}[+]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[!]${NC} $1"; }

# Run tool
run_tool() {
    local tool="$1"
    shift
    
    if [[ -x "$tool" ]]; then
        log_info "Launching: $(basename "$tool")"
        echo ""
        "$tool" "$@"
    else
        log_warn "Tool not found or not executable: $tool"
        return 1
    fi
}

# Show tool paths
show_paths() {
    echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  TOOL LOCATIONS${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
    echo ""
    echo "Exploitation:"
    echo "  $SCRIPT_DIR/exploitation/payload-generator.sh"
    echo "  $SCRIPT_DIR/exploitation/reverse-shell-gen.sh"
    echo "  $SCRIPT_DIR/exploitation/encoder-toolkit.sh"
    echo ""
    echo "Post-Exploitation:"
    echo "  $SCRIPT_DIR/post-exploitation/linux/linux-privesc-check.sh"
    echo "  $SCRIPT_DIR/post-exploitation/windows/windows-privesc-check.ps1"
    echo "  $SCRIPT_DIR/post-exploitation/credentials/credential-harvester.sh"
    echo ""
    echo "Crypto & Forensics:"
    echo "  $SCRIPT_DIR/crypto-forensics/hashes/hash-cracker.sh"
    echo "  $SCRIPT_DIR/crypto-forensics/logs/log-analyzer.sh"
    echo "  $SCRIPT_DIR/crypto-forensics/stego/stego-detector.sh"
    echo ""
    echo "Binary Exploitation:"
    echo "  $SCRIPT_DIR/binary-pwn/elf/elf-analyzer.sh"
    echo "  $SCRIPT_DIR/binary-pwn/fuzz/simple-fuzzer.sh"
    echo ""
}

# Check dependencies
check_deps() {
    echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  DEPENDENCY CHECK${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
    echo ""
    
    local deps=("bash" "python3" "file" "strings" "readelf" "objdump" "xxd")
    
    echo "Core Dependencies:"
    for dep in "${deps[@]}"; do
        if command -v "$dep" &> /dev/null; then
            echo -e "  ${GREEN}✓${NC} $dep"
        else
            echo -e "  ${RED}✗${NC} $dep (missing)"
        fi
    done
    
    echo ""
    echo "Optional Tools:"
    local optional=("hashcat" "john" "steghide" "zsteg" "binwalk" "exiftool" "checksec" "ROPgadget")
    
    for tool in "${optional[@]}"; do
        if command -v "$tool" &> /dev/null; then
            echo -e "  ${GREEN}✓${NC} $tool"
        else
            echo -e "  ${YELLOW}○${NC} $tool (optional)"
        fi
    done
    
    echo ""
}

# Handle menu selection
handle_selection() {
    local choice="$1"
    
    case $choice in
        # Exploitation
        41)
            run_tool "$SCRIPT_DIR/exploitation/payload-generator.sh" --help
            read -p "Press Enter to launch tool..."
            run_tool "$SCRIPT_DIR/exploitation/payload-generator.sh" --interactive
            ;;
        42)
            run_tool "$SCRIPT_DIR/exploitation/reverse-shell-gen.sh" --help
            read -p "Press Enter to launch interactive mode..."
            run_tool "$SCRIPT_DIR/exploitation/reverse-shell-gen.sh" --interactive
            ;;
        43)
            run_tool "$SCRIPT_DIR/exploitation/encoder-toolkit.sh" --help
            read -p "Press Enter to launch interactive mode..."
            run_tool "$SCRIPT_DIR/exploitation/encoder-toolkit.sh" --interactive
            ;;
        
        # Post-Exploitation
        51)
            run_tool "$SCRIPT_DIR/post-exploitation/linux/linux-privesc-check.sh" --help
            read -p "Press Enter to run full scan..."
            run_tool "$SCRIPT_DIR/post-exploitation/linux/linux-privesc-check.sh" --all
            ;;
        52)
            echo "Windows Privilege Escalation Checker (PowerShell)"
            echo "Copy this script to target Windows machine and run:"
            echo "  powershell -ExecutionPolicy Bypass -File windows-privesc-check.ps1"
            read -p "Press Enter to view script..."
            cat "$SCRIPT_DIR/post-exploitation/windows/windows-privesc-check.ps1" | head -50
            ;;
        53)
            run_tool "$SCRIPT_DIR/post-exploitation/credentials/credential-harvester.sh" --help
            read -p "Press Enter to run quick scan..."
            run_tool "$SCRIPT_DIR/post-exploitation/credentials/credential-harvester.sh" --quick
            ;;
        
        # Crypto & Forensics
        61)
            run_tool "$SCRIPT_DIR/crypto-forensics/hashes/hash-cracker.sh" --help
            read -p "Press Enter to launch tool..."
            run_tool "$SCRIPT_DIR/crypto-forensics/hashes/hash-cracker.sh"
            ;;
        62)
            run_tool "$SCRIPT_DIR/crypto-forensics/logs/log-analyzer.sh" --help
            read -p "Press Enter to run full analysis..."
            run_tool "$SCRIPT_DIR/crypto-forensics/logs/log-analyzer.sh" --full
            ;;
        63)
            run_tool "$SCRIPT_DIR/crypto-forensics/stego/stego-detector.sh" --help
            echo ""
            read -p "Enter image file path: " img_file
            if [[ -f "$img_file" ]]; then
                run_tool "$SCRIPT_DIR/crypto-forensics/stego/stego-detector.sh" -f "$img_file"
            else
                log_warn "File not found: $img_file"
            fi
            ;;
        
        # Binary Exploitation
        81)
            run_tool "$SCRIPT_DIR/binary-pwn/elf/elf-analyzer.sh" --help
            echo ""
            read -p "Enter binary path: " binary
            if [[ -f "$binary" ]]; then
                run_tool "$SCRIPT_DIR/binary-pwn/elf/elf-analyzer.sh" -f "$binary" --all
            else
                log_warn "Binary not found: $binary"
            fi
            ;;
        82)
            run_tool "$SCRIPT_DIR/binary-pwn/fuzz/simple-fuzzer.sh" --help
            echo ""
            read -p "Enter target command: " target
            if [[ -n "$target" ]]; then
                run_tool "$SCRIPT_DIR/binary-pwn/fuzz/simple-fuzzer.sh" --comprehensive "$target"
            else
                log_warn "No target specified"
            fi
            ;;
        
        # Utilities
        91)
            show_paths
            read -p "Press Enter to continue..."
            ;;
        92)
            check_deps
            read -p "Press Enter to continue..."
            ;;
        93)
            log_info "Update functionality not implemented yet"
            log_info "To update, run: cd $SCRIPT_DIR && git pull"
            read -p "Press Enter to continue..."
            ;;
        
        0)
            echo -e "${GREEN}Goodbye!${NC}"
            exit 0
            ;;
        *)
            log_warn "Invalid selection: $choice"
            sleep 1
            ;;
    esac
}

# Main loop
main() {
    while true; do
        banner
        show_menu
        
        echo ""
        read -p "Enter your choice: " choice
        
        handle_selection "$choice"
    done
}

# If run with arguments, execute specific tool
if [[ $# -gt 0 ]]; then
    case "$1" in
        payload|41)
            shift
            run_tool "$SCRIPT_DIR/exploitation/payload-generator.sh" "$@"
            ;;
        shell|42)
            shift
            run_tool "$SCRIPT_DIR/exploitation/reverse-shell-gen.sh" "$@"
            ;;
        encode|43)
            shift
            run_tool "$SCRIPT_DIR/exploitation/encoder-toolkit.sh" "$@"
            ;;
        linpriv|51)
            shift
            run_tool "$SCRIPT_DIR/post-exploitation/linux/linux-privesc-check.sh" "$@"
            ;;
        creds|53)
            shift
            run_tool "$SCRIPT_DIR/post-exploitation/credentials/credential-harvester.sh" "$@"
            ;;
        hash|61)
            shift
            run_tool "$SCRIPT_DIR/crypto-forensics/hashes/hash-cracker.sh" "$@"
            ;;
        log|62)
            shift
            run_tool "$SCRIPT_DIR/crypto-forensics/logs/log-analyzer.sh" "$@"
            ;;
        stego|63)
            shift
            run_tool "$SCRIPT_DIR/crypto-forensics/stego/stego-detector.sh" "$@"
            ;;
        elf|81)
            shift
            run_tool "$SCRIPT_DIR/binary-pwn/elf/elf-analyzer.sh" "$@"
            ;;
        fuzz|82)
            shift
            run_tool "$SCRIPT_DIR/binary-pwn/fuzz/simple-fuzzer.sh" "$@"
            ;;
        menu|gui)
            main
            ;;
        *)
            echo "Unknown command: $1"
            echo "Use 'menu' or 'gui' for interactive mode"
            exit 1
            ;;
    esac
else
    # No arguments - run interactive mode
    main
fi

#!/bin/bash

# ANSI color codes
RED='\033[91m'
GREEN='\033[92m'
YELLOW='\033[93m'
BLUE='\033[94m'
PURPLE='\033[95m'
CYAN='\033[96m'
WHITE='\033[97m'
BOLD='\033[1m'
RESET='\033[0m'

# Banner
echo -e "${CYAN}${BOLD}"
cat << "EOF"
    ________                   __ ___________                                 
    \______ \ _____    _______/  |\_   _____/_ __________________ ___________ 
     |    |  \\__  \  /  ___/\   __\    __)|  |  \___   /\___   // __ \_  __ \
     |    `   \/ __ \_\___ \  |  | |     \ |  |  //    /  /    /\  ___/|  | \/
    /_______  (____  /____  > |__| \___  / |____//_____ \/_____ \\___  >__|   
            \/     \/     \/           \/              \/      \/    \/       
EOF
echo -e "${RESET}"
echo -e "${PURPLE}${BOLD}                    DAST Vulnerability Scanner${RESET}"
echo -e ""

# Default settings
HUNT_DIR="$HOME/hunt"
TEMPLATE_DIR="$HOME/nuclei-templates"
DAST_TEMPLATE_DIR="$TEMPLATE_DIR/dast"
OUTPUT_DIR="$HUNT_DIR/dast-results"
LOG_FILE="$OUTPUT_DIR/dast-scan.log"
SUMMARY_FILE="$OUTPUT_DIR/dast-scan-report.txt"
NUCLEI_PARAMS="-dast -c 50 -rl 100 -retries 2"
VERBOSE=false

# Vulnerability types and their corresponding URL files
declare -A VULN_URL_FILES=(
    ["cmdi"]="cmdi-urls.txt"
    ["crlf"]="crlf-urls.txt" 
    ["csti"]="csti-urls.txt"
    ["injection"]="injection-urls.txt"
    ["lfi"]="lfi-urls.txt"
    ["redirect"]="redirect-urls.txt"
    ["rfi"]="rfi-urls.txt"
    ["sqli"]="sqli-urls.txt"
    ["ssrf"]="ssrf-urls.txt"
    ["ssti"]="ssti-urls.txt"
    ["xss"]="xss-urls.txt"
    ["xxe"]="xxe-urls.txt"
)

# Initialize findings counter
declare -A FINDINGS_COUNT
TOTAL_FINDINGS=0

# Symbols and icons
CHECK_MARK="${GREEN}✓${RESET}"
CROSS_MARK="${RED}✗${RESET}"
WARNING_MARK="${YELLOW}⚠${RESET}"
INFO_MARK="${BLUE}ℹ${RESET}"
PROGRESS_MARK="${CYAN}↻${RESET}"
ARROW_RIGHT="${PURPLE}➜${RESET}"

# Help menu
display_help() {
    echo -e "${CYAN}${BOLD}DastFuzzer: Automated DAST Vulnerability Scanner${RESET}\n"
    echo -e "${WHITE}Usage: $0 [options]${RESET}"
    echo -e "\n${YELLOW}Options:${RESET}"
    echo -e "  ${GREEN}-h, --help${RESET}      Display this help menu"
    echo -e "  ${GREEN}-v, --verbose${RESET}   Enable verbose output for debugging"
    echo -e "\n${YELLOW}Examples:${RESET}"
    echo -e "  ${WHITE}$0${RESET}              Run standard scan"
    echo -e "  ${WHITE}$0 -v${RESET}           Run with verbose output"
    exit 0
}

# Print section header
print_section() {
    local title="$1"
    echo -e "\n${PURPLE}${BOLD}╔════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${PURPLE}${BOLD}║${RESET} ${CYAN}${BOLD}$title${RESET}"
    echo -e "${PURPLE}${BOLD}╚════════════════════════════════════════════════════════════════╝${RESET}\n"
}

# Print task with status
print_task() {
    local task="$1"
    local status="$2"
    local padding=$(printf '%*s' 60)
    echo -e "  ${WHITE}${task}${RESET}${padding:${#task}} [${status}]"
}

# Log function
log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
    
    case "$level" in
        INFO) echo -e "  ${INFO_MARK} ${GREEN}[INFO]${RESET} $message" ;;
        WARNING) echo -e "  ${WARNING_MARK} ${YELLOW}[WARNING]${RESET} $message" ;;
        ERROR) echo -e "  ${CROSS_MARK} ${RED}[ERROR]${RESET} $message" ;;
        SUCCESS) echo -e "  ${CHECK_MARK} ${GREEN}[SUCCESS]${RESET} $message" ;;
    esac
}

# Check if Nuclei is installed
check_nuclei() {
    print_section "DEPENDENCY CHECK"
    if ! command -v nuclei &> /dev/null; then
        log "ERROR" "Nuclei is not installed."
        echo -e "\n${YELLOW}Installation command:${RESET}"
        echo -e "  ${WHITE}go install -v github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest${RESET}"
        exit 1
    fi
    local nuclei_version=$(nuclei -version 2>&1 | grep Version | awk '{print $NF}')
    print_task "Nuclei" "${CHECK_MARK} v$nuclei_version"
    log "INFO" "Nuclei is installed (version: $nuclei_version)."
}

# Validate file existence
validate_file() {
    local file="$1"
    local type="$2"
    if [ ! -f "$file" ]; then
        log "WARNING" "$type file not found: $file"
        return 1
    elif [ ! -s "$file" ]; then
        log "WARNING" "$type file is empty: $file"
        return 1
    fi
    return 0
}

# Count URLs in a file
count_urls() {
    local file="$1"
    if [ -f "$file" ] && [ -s "$file" ]; then
        wc -l < "$file" | tr -d ' '
    else
        echo "0"
    fi
}

# Count templates in a directory
count_templates() {
    local vuln="$1"
    local template_path="$DAST_TEMPLATE_DIR/vulnerabilities/$vuln"
    if [ -d "$template_path" ]; then
        find "$template_path" -name "*.yaml" -type f 2>/dev/null | wc -l | tr -d ' '
    else
        echo "0"
    fi
}

# Run Nuclei for a vulnerability type
run_nuclei() {
    local vuln="$1"
    local url_file="$HUNT_DIR/${VULN_URL_FILES[$vuln]}"
    local result_file="$OUTPUT_DIR/nuclei-dast-$vuln.txt"
    local template_path="$DAST_TEMPLATE_DIR/vulnerabilities/$vuln"
    
    # Validate URL file
    validate_file "$url_file" "URL" || return 0
    
    local url_count=$(count_urls "$url_file")
    local template_count=$(count_templates "$vuln")
    
    if [ "$template_count" -eq 0 ]; then
        log "WARNING" "No DAST templates found for $vuln"
        print_task "$vulni scan" "${WARNING_MARK} No templates"
        return 0
    fi
    
    # Print scan header
    echo -e "\n${CYAN}${BOLD}┌─ SCANNING: ${vuln^^}${RESET}"
    echo -e "${CYAN}${BOLD}│${RESET} ${WHITE}URLs:${RESET} $url_count ${WHITE}Templates:${RESET} $template_count"
    echo -e "${CYAN}${BOLD}│${RESET} ${WHITE}Input:${RESET} ${VULN_URL_FILES[$vuln]}"
    echo -e "${CYAN}${BOLD}│${RESET} ${WHITE}Output:${RESET} nuclei-dast-$vuln.txt"
    echo -e "${CYAN}${BOLD}└─────────────────────────────────────────────────────────────────────${RESET}"
    
    # Build and execute Nuclei command
    local nuclei_cmd="nuclei -l \"$url_file\" -t \"$template_path\" $NUCLEI_PARAMS -o \"$result_file\""
    
    log "INFO" "Executing: $nuclei_cmd"
    
    # Show progress spinner for long-running tasks
    if [ "$VERBOSE" != true ] && [ "$url_count" -gt 1000 ]; then
        echo -n "  ${PROGRESS_MARK} Scanning..."
        local spinstr='|/-\'
        local tempfile=$(mktemp)
        
        (eval "$nuclei_cmd" > "$tempfile" 2>&1) &
        local pid=$!
        
        while kill -0 "$pid" 2>/dev/null; do
            local temp=${spinstr#?}
            printf "  ${PROGRESS_MARK} [%c] Scanning..." "$spinstr"
            local spinstr=$temp${spinstr%"$temp"}
            sleep 0.1
            printf "\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b"
        done
        
        wait "$pid"
        local exit_code=$?
        rm -f "$tempfile"
        printf "                                   \r"
    else
        if [ "$VERBOSE" = true ]; then
            eval "$nuclei_cmd"
        else
            eval "$nuclei_cmd" >/dev/null 2>&1
        fi
        local exit_code=$?
    fi
    
    # Count findings
    local findings=0
    if [ -f "$result_file" ] && [ -s "$result_file" ]; then
        findings=$(grep -c "^http" "$result_file" 2>/dev/null || echo "0")
    fi
    
    FINDINGS_COUNT["$vuln"]=$findings
    ((TOTAL_FINDINGS+=findings))
    
    # Print result
    if [ "$findings" -eq 0 ]; then
        echo -e "  ${CHECK_MARK} ${GREEN}No vulnerabilities found${RESET}"
        log "INFO" "No $vuln vulnerabilities found."
    else
        echo -e "  ${CHECK_MARK} ${RED}Found $findings vulnerabilities${RESET} ${WHITE}${ARROW_RIGHT}${RESET} ${YELLOW}nuclei-dast-$vuln.txt${RESET}"
        log "INFO" "Found $findings $vuln vulnerabilities. Results saved to $result_file."
    fi
    
    return 0
}

# Generate summary report
generate_summary() {
    print_section "SCAN SUMMARY"
    
    # Create detailed summary file
    {
        echo -e "${CYAN}${BOLD}╔════════════════════════════════════════════════════════════════╗"
        echo -e "║                    DAST SCAN SUMMARY REPORT                    ║"
        echo -e "╚════════════════════════════════════════════════════════════════╝${RESET}"
        echo -e ""
        echo -e "${WHITE}Scan Date:${RESET} $(date '+%Y-%m-%d %H:%M:%S')"
        echo -e "${WHITE}Scan Type:${RESET} DAST (Dynamic Application Security Testing)"
        echo -e "${WHITE}Template Directory:${RESET} $DAST_TEMPLATE_DIR"
        echo -e "${WHITE}Log File:${RESET} $LOG_FILE"
        echo -e ""
        echo -e "${CYAN}${BOLD}┌────────────────────────────────────────────────────────────────────┐"
        echo -e "│                     VULNERABILITY FINDINGS                     │"
        echo -e "└────────────────────────────────────────────────────────────────────┘${RESET}"
        echo -e ""
        
        # Table header
        printf "${WHITE}%-15s %-12s %-10s %-8s${RESET}\n" "VULNERABILITY" "URLS" "TEMPLATES" "FINDINGS"
        echo -e "────────────────────────────────────────────────────────────"
        
        # Table rows
        for vuln in "${!VULN_URL_FILES[@]}"; do
            local url_file="$HUNT_DIR/${VULN_URL_FILES[$vuln]}"
            local count=${FINDINGS_COUNT["$vuln"]:-0}
            local template_count=$(count_templates "$vuln")
            local url_count=$(count_urls "$url_file")
            
            local color=""
            if [ "$count" -gt 0 ]; then
                color="$RED"
            elif [ "$template_count" -eq 0 ]; then
                color="$YELLOW"
            else
                color="$GREEN"
            fi
            
            printf "${color}%-15s${RESET} ${WHITE}%-12s${RESET} ${WHITE}%-10s${RESET} ${color}%-8s${RESET}\n" \
                "$vuln" "$url_count" "$template_count" "$count"
        done
        
        echo -e ""
        echo -e "${CYAN}${BOLD}┌────────────────────────────────────────────────────────────────────┐"
        if [ "$TOTAL_FINDINGS" -gt 0 ]; then
            echo -e "│ ${RED}${BOLD}🚨 CRITICAL: $TOTAL_FINDINGS TOTAL VULNERABILITIES FOUND 🚨${RESET}${CYAN}${BOLD}           │"
        else
            echo -e "│ ${GREEN}${BOLD}✅ SECURE: NO VULNERABILITIES DETECTED${RESET}${CYAN}${BOLD}                          │"
        fi
        echo -e "└────────────────────────────────────────────────────────────────────┘"
        
    } > "$SUMMARY_FILE"
    
    # Display summary in terminal
    echo -e "${WHITE}Scan completed at:${RESET} $(date '+%Y-%m-%d %H:%M:%S')"
    echo -e "${WHITE}Total vulnerabilities found:${RESET} $TOTAL_FINDINGS"
    echo -e ""
    
    # Quick stats
    local scanned_vulns=0
    local available_templates=0
    for vuln in "${!VULN_URL_FILES[@]}"; do
        local url_file="$HUNT_DIR/${VULN_URL_FILES[$vuln]}"
        if [ -f "$url_file" ] && [ -s "$url_file" ]; then
            ((scanned_vulns++))
        fi
        local template_count=$(count_templates "$vuln")
        ((available_templates+=$template_count))
    done
    
    echo -e "${CYAN}${BOLD}📊 Quick Stats:${RESET}"
    echo -e "  ${WHITE}Scanned vulnerability types:${RESET} $scanned_vulns/${#VULN_URL_FILES[@]}"
    echo -e "  ${WHITE}Available DAST templates:${RESET} $available_templates"
    echo -e "  ${WHITE}Results directory:${RESET} $OUTPUT_DIR"
    
    log "INFO" "Summary report generated: $SUMMARY_FILE"
    echo -e "\n${GREEN}${BOLD}✅ Summary report saved to: $SUMMARY_FILE${RESET}"
}

# Check URL files existence
check_url_files() {
    print_section "INPUT VALIDATION"
    
    local missing_files=()
    local available_files=()
    
    for vuln in "${!VULN_URL_FILES[@]}"; do
        local url_file="$HUNT_DIR/${VULN_URL_FILES[$vuln]}"
        if [ -f "$url_file" ] && [ -s "$url_file" ]; then
            local url_count=$(count_urls "$url_file")
            available_files+=("${VULN_URL_FILES[$vuln]} ($url_count URLs)")
            print_task "${VULN_URL_FILES[$vuln]}" "${CHECK_MARK} $url_count URLs"
        else
            missing_files+=("${VULN_URL_FILES[$vuln]}")
            print_task "${VULN_URL_FILES[$vuln]}" "${CROSS_MARK} Missing"
        fi
    done
    
    if [ ${#available_files[@]} -eq 0 ]; then
        log "ERROR" "No URL files found in $HUNT_DIR/"
        echo -e "\n${YELLOW}Expected URL files:${RESET}"
        for vuln in "${!VULN_URL_FILES[@]}"; do
            echo -e "  ${WHITE}• ${VULN_URL_FILES[$vuln]}${RESET}"
        done
        exit 1
    fi
    
    echo -e "\n${GREEN}${BOLD}✅ Ready to scan ${#available_files[@]} vulnerability types${RESET}"
}

# Check DAST template availability
check_dast_templates() {
    print_section "TEMPLATE CHECK"
    
    local total_dast_templates=0
    local available_vulns=()
    
    for vuln in "${!VULN_URL_FILES[@]}"; do
        local template_count=$(count_templates "$vuln")
        if [ "$template_count" -gt 0 ]; then
            available_vulns+=("$vuln")
            total_dast_templates=$((total_dast_templates + template_count))
            print_task "$vuln templates" "${CHECK_MARK} $template_count"
        else
            print_task "$vuln templates" "${WARNING_MARK} None"
        fi
    done
    
    if [ "$total_dast_templates" -eq 0 ]; then
        log "ERROR" "No DAST templates found"
        echo -e "\n${YELLOW}Solution:${RESET}"
        echo -e "  ${WHITE}nuclei -update-templates${RESET}"
        exit 1
    fi
    
    echo -e "\n${GREEN}${BOLD}✅ $total_dast_templates DAST templates available${RESET}"
}

# Main logic
main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help) display_help ;;
            -v|--verbose) VERBOSE=true; shift ;;
            *) log "ERROR" "Unknown option: $1"; display_help ;;
        esac
    done

    # Setup
    print_section "DAST FUZZER INITIALIZATION"
    echo -e "${WHITE}Output Directory:${RESET} $OUTPUT_DIR"
    echo -e "${WHITE}Log File:${RESET} $LOG_FILE"
    echo -e "${WHITE}Verbose Mode:${RESET} $VERBOSE"
    
    mkdir -p "$OUTPUT_DIR" || { log "ERROR" "Failed to create output directory"; exit 1; }
    echo "" > "$LOG_FILE" || { log "ERROR" "Failed to create log file"; exit 1; }

    # Check dependencies
    check_nuclei

    # Check URL files
    check_url_files

    # Check DAST template availability
    check_dast_templates

    # Start scanning
    print_section "VULNERABILITY SCANNING"
    echo -e "${CYAN}${BOLD}🚀 Starting DAST vulnerability scans...${RESET}\n"
    
    for vuln in "${!VULN_URL_FILES[@]}"; do
        url_file="$HUNT_DIR/${VULN_URL_FILES[$vuln]}"
        if [ -f "$url_file" ] && [ -s "$url_file" ]; then
            run_nuclei "$vuln"
        fi
    done

    # Generate summary
    generate_summary

    # Final message
    print_section "SCAN COMPLETED"
    if [ "$TOTAL_FINDINGS" -gt 0 ]; then
        echo -e "${RED}${BOLD}⚠️  $TOTAL_FINDINGS VULNERABILITIES FOUND - REVIEW RESULTS CAREFULLY ⚠️${RESET}"
    else
        echo -e "${GREEN}${BOLD}✅ SCAN COMPLETED - NO VULNERABILITIES DETECTED${RESET}"
    fi
    echo -e ""
    echo -e "${WHITE}Results Directory:${RESET} ${YELLOW}$OUTPUT_DIR${RESET}"
    echo -e "${WHITE}Summary Report:${RESET} ${YELLOW}$SUMMARY_FILE${RESET}"
    echo -e "${WHITE}Log File:${RESET} ${YELLOW}$LOG_FILE${RESET}"
    echo -e ""
    echo -e "${CYAN}Thank you for using DastFuzzer!${RESET}"
}

# Run main function
main "$@"

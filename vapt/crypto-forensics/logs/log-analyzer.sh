#!/bin/bash
# Log Analysis & Forensics Tool
# Version: 1.0 - VAPT Professional
# Analyzes system logs for security events and suspicious activity

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
LOGS_DIR="${SCRIPT_DIR}/logs"
mkdir -p "$LOGS_DIR"

# Banner
banner() {
    echo -e "${CYAN}"
    cat << 'EOF'
╔═══════════════════════════════════════════════════════════╗
║            LOG ANALYSIS & FORENSICS TOOL                  ║
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

# Analyze authentication logs
analyze_auth_logs() {
    section "AUTHENTICATION ANALYSIS"
    
    local auth_log="${1:-/var/log/auth.log}"
    
    if [[ ! -f "$auth_log" ]]; then
        auth_log="/var/log/secure"
    fi
    
    if [[ ! -f "$auth_log" ]]; then
        log_warn "Auth log not found"
        return
    fi
    
    log_info "Analyzing: $auth_log"
    
    # Failed login attempts
    log_info "Failed login attempts:"
    grep -i "failed password\|authentication failure" "$auth_log" 2>/dev/null | tail -20 | while read -r line; do
        echo "  $line"
    done
    
    # Successful logins
    log_info "Recent successful logins:"
    grep -i "accepted password\|session opened" "$auth_log" 2>/dev/null | tail -10 | while read -r line; do
        echo "  $line"
    done
    
    # Brute force attempts (multiple failures from same IP)
    log_info "Potential brute force attacks (top 10 IPs with failures):"
    grep -i "failed password" "$auth_log" 2>/dev/null | grep -oE "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+" | sort | uniq -c | sort -rn | head -10 | while read -r line; do
        log_warn "$line failed attempts"
    done
    
    # Sudo usage
    log_info "Sudo commands executed:"
    grep -i "sudo:" "$auth_log" 2>/dev/null | grep "COMMAND=" | tail -10 | while read -r line; do
        echo "  $line"
    done
}

# Analyze web server logs
analyze_web_logs() {
    section "WEB SERVER LOG ANALYSIS"
    
    local web_log="${1:-/var/log/apache2/access.log}"
    
    if [[ ! -f "$web_log" ]]; then
        web_log="/var/log/httpd/access_log"
    fi
    
    if [[ ! -f "$web_log" ]]; then
        web_log="/var/log/nginx/access.log"
    fi
    
    if [[ ! -f "$web_log" ]]; then
        log_warn "Web server log not found"
        return
    fi
    
    log_info "Analyzing: $web_log"
    
    # Top requesting IPs
    log_info "Top 10 requesting IPs:"
    awk '{print $1}' "$web_log" | sort | uniq -c | sort -rn | head -10
    
    # Suspicious requests (SQL injection attempts)
    log_info "Potential SQL injection attempts:"
    grep -iE "union.*select|concat\(|load_file|benchmark|sleep\(" "$web_log" 2>/dev/null | head -10 | while read -r line; do
        log_warn "$line"
    done
    
    # XSS attempts
    log_info "Potential XSS attempts:"
    grep -iE "<script|javascript:|onerror=|onload=" "$web_log" 2>/dev/null | head -10 | while read -r line; do
        log_warn "$line"
    done
    
    # Directory traversal attempts
    log_info "Directory traversal attempts:"
    grep -E "\.\./|\.\.\\|%2e%2e" "$web_log" 2>/dev/null | head -10 | while read -r line; do
        log_warn "$line"
    done
    
    # 404 errors (scanning attempts)
    log_info "Top 404 errors (potential scanning):"
    grep " 404 " "$web_log" 2>/dev/null | awk '{print $7}' | sort | uniq -c | sort -rn | head -10
}

# Analyze system logs
analyze_syslog() {
    section "SYSTEM LOG ANALYSIS"
    
    local syslog="${1:-/var/log/syslog}"
    
    if [[ ! -f "$syslog" ]]; then
        syslog="/var/log/messages"
    fi
    
    if [[ ! -f "$syslog" ]]; then
        log_warn "System log not found"
        return
    fi
    
    log_info "Analyzing: $syslog"
    
    # Kernel messages
    log_info "Recent kernel messages:"
    grep -i "kernel:" "$syslog" 2>/dev/null | tail -10
    
    # Service starts/stops
    log_info "Service changes:"
    grep -iE "started|stopped|restarted" "$syslog" 2>/dev/null | tail -10
    
    # Errors
    log_info "Error messages:"
    grep -i "error" "$syslog" 2>/dev/null | tail -10
    
    # Warnings
    log_info "Warning messages:"
    grep -i "warning" "$syslog" 2>/dev/null | tail -10
}

# Analyze failed services
analyze_services() {
    section "SERVICE ANALYSIS"
    
    log_info "Failed services:"
    systemctl --failed 2>/dev/null | grep "failed" | while read -r line; do
        log_warn "$line"
    done || log_info "No failed services"
}

# Analyze user activity
analyze_user_activity() {
    section "USER ACTIVITY ANALYSIS"
    
    log_info "Currently logged in users:"
    who
    
    log_info "Recent logins:"
    last | head -20
    
    log_info "Failed login attempts:"
    lastb | head -10 2>/dev/null || log_warn "lastb requires root or specific permissions"
}

# Analyze for persistence
analyze_persistence() {
    section "PERSISTENCE MECHANISMS"
    
    log_info "Startup scripts:"
    ls -la /etc/rc.local /etc/init.d/ /etc/rc*.d/ 2>/dev/null | head -20
    
    log_info "Cron jobs for all users:"
    for user in $(cut -d: -f1 /etc/passwd); do
        crontab -l -u "$user" 2>/dev/null | grep -v "^#" | grep -v "^$" | while read -r line; do
            echo "  $user: $line"
        done
    done
    
    log_info "Systemd timers:"
    systemctl list-timers --all 2>/dev/null | head -10
    
    log_info "Sudoers configurations:"
    grep -r "NOPASSWD" /etc/sudoers /etc/sudoers.d/ 2>/dev/null | while read -r line; do
        log_warn "NOPASSWD found: $line"
    done
}

# Generate timeline
generate_timeline() {
    section "EVENT TIMELINE"
    
    local log_dir="${1:-/var/log}"
    local hours="${2:-24}"
    
    log_info "Generating timeline for last $hours hours..."
    
    find "$log_dir" -name "*.log" -mtime -1 -exec ls -lt {} \; 2>/dev/null | head -20
    
    log_info "Recent auth events:"
    grep -h "" /var/log/auth.log /var/log/secure 2>/dev/null | tail -50 | while read -r line; do
        echo "  $line"
    done
}

# Export results
export_results() {
    local output_file="${1:-${LOGS_DIR}/log_analysis_$(date +%Y%m%d_%H%M%S).txt}"
    
    log_good "Exporting results to: $output_file"
    
    {
        echo "Log Analysis Report"
        echo "Generated: $(date)"
        echo "========================================"
        echo ""
        
        section "AUTHENTICATION LOGS"
        analyze_auth_logs 2>&1
        
        section "WEB SERVER LOGS"
        analyze_web_logs 2>&1
        
        section "SYSTEM LOGS"
        analyze_syslog 2>&1
        
        section "SERVICE ANALYSIS"
        analyze_services 2>&1
        
        section "USER ACTIVITY"
        analyze_user_activity 2>&1
        
        section "PERSISTENCE MECHANISMS"
        analyze_persistence 2>&1
        
    } > "$output_file"
    
    log_good "Report saved: $output_file"
}

# Show usage
usage() {
    cat << 'EOF'
USAGE:
    ./log-analyzer.sh [OPTIONS]

OPTIONS:
    -a, --auth FILE           Analyze auth log file
    -w, --web FILE            Analyze web server log
    -s, --syslog FILE         Analyze system log
    --timeline HOURS          Generate timeline for last N hours
    -e, --export FILE         Export results to file
    -f, --full                Full analysis (all logs)
    -h, --help                Show this help

EXAMPLES:
    # Full system analysis
    ./log-analyzer.sh -f

    # Analyze specific auth log
    ./log-analyzer.sh -a /var/log/auth.log

    # Analyze web logs
    ./log-analyzer.sh -w /var/log/apache2/access.log

    # Generate timeline and export
    ./log-analyzer.sh --timeline 24 -e report.txt

    # Export full report
    ./log-analyzer.sh -f -e full-report.txt

EOF
}

# Main function
main() {
    local auth_log=""
    local web_log=""
    local sys_log=""
    local export_file=""
    local timeline_hours=""
    local full_analysis=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -a|--auth)
                auth_log="$2"
                shift 2
                ;;
            -w|--web)
                web_log="$2"
                shift 2
                ;;
            -s|--syslog)
                sys_log="$2"
                shift 2
                ;;
            --timeline)
                timeline_hours="$2"
                shift 2
                ;;
            -e|--export)
                export_file="$2"
                shift 2
                ;;
            -f|--full)
                full_analysis=true
                shift
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
    
    banner
    
    if [[ "$full_analysis" == true ]]; then
        analyze_auth_logs
        analyze_web_logs
        analyze_syslog
        analyze_services
        analyze_user_activity
        analyze_persistence
    else
        [[ -n "$auth_log" ]] && analyze_auth_logs "$auth_log"
        [[ -n "$web_log" ]] && analyze_web_logs "$web_log"
        [[ -n "$sys_log" ]] && analyze_syslog "$sys_log"
    fi
    
    if [[ -n "$timeline_hours" ]]; then
        generate_timeline "/var/log" "$timeline_hours"
    fi
    
    if [[ -n "$export_file" ]]; then
        export_results "$export_file"
    fi
    
    # If no specific options, show usage
    if [[ -z "$auth_log" && -z "$web_log" && -z "$sys_log" && -z "$timeline_hours" && "$full_analysis" == false ]]; then
        usage
    fi
}

main "$@"

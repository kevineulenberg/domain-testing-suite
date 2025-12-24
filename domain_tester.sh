#!/bin/bash

# --- Color & Style Definitions ---
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m' # No Color

# --- Icons (Safe for most fonts, but using standard ASCII fallback if needed) ---
ICON_CHECK="✔"
ICON_CROSS="✘"
ICON_INFO="ℹ"
ICON_ARROW="➜"

# --- Initialization ---
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
LOG_DIR="$SCRIPT_DIR/domain_logs"
mkdir -p "$LOG_DIR"
LOG_FILE="/dev/null"

# Ensure we have the node wrapper
NODE_WRAPPER="$SCRIPT_DIR/scan_wrapper.js"

# --- Utility Functions ---

run_with_timeout() {
    local duration=$1
    shift
    local cmd="$@"
    
    if command -v gtimeout &> /dev/null; then
        gtimeout "$duration" bash -c "$cmd"
    elif command -v timeout &> /dev/null; then
        timeout "$duration" bash -c "$cmd"
    else
        # Perl fallback for macOS default
        perl -e 'alarm shift; exec @ARGV' "$duration" bash -c "$cmd"
    fi
}

print_header() {
    clear
    if [ -f "$NODE_WRAPPER" ] && command -v node &> /dev/null; then
        node "$NODE_WRAPPER" "ignored" "--banner"
    else
        echo -e "${CYAN}${BOLD}=============================================="
        echo -e "      AVANT-GARDE DOMAIN TESTING SUITE        "
        echo -e "==============================================${NC}"
    fi
    echo -e "${DIM}  v2.0.1 | System Ready | Timeout Safe${NC}\n"
}

spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    tput civis 2>/dev/null # Hide cursor
    while kill -0 $pid 2>/dev/null; do
        local temp=${spinstr#?}
        printf "${CYAN}%c${NC}" "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b"
    done
    printf " "
    printf "\b"
    tput cnorm 2>/dev/null # Show cursor
}

# Run a command with a spinner and nice formatting
# Usage: execute_task "Task Name" command_to_run [args...]
execute_task() {
    local title="$1"
    shift
    local cmd="$@"
    
    echo -ne "  ${ICON_ARROW} ${BOLD}${title}${NC} ... "
    
    # Create a temp file for output
    local temp_out
    temp_out=$(mktemp)
    
    # Run the command in background
    (eval "$cmd") > "$temp_out" 2>&1 &
    local pid=$!
    
    # Start spinner
    spinner $pid
    
    wait $pid
    local exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        echo -e "${GREEN}${ICON_CHECK}${NC}"
        # Print output indented, but filter empty lines if needed
        if [ -s "$temp_out" ]; then
            sed 's/^/    /' "$temp_out" | tee -a "$LOG_FILE"
        else
            echo -e "    ${DIM}(No output returned)${NC}" | tee -a "$LOG_FILE"
        fi
    else
        echo -e "${RED}${ICON_CROSS}${NC}"
        sed 's/^/    /' "$temp_out" | tee -a "$LOG_FILE"
    fi
    rm "$temp_out"
}

check_dependencies() {
    local deps=("dig" "curl" "openssl" "whois" "nc")
    local missing=0
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            echo -e "${RED}${ICON_CROSS} Error: $dep is not installed.${NC}"
            missing=1
        fi
    done
    
    if ! command -v node &> /dev/null; then
        echo -e "${YELLOW}${ICON_INFO} Warning: Node.js not found. Advanced features disabled.${NC}"
    fi
    
    if [ $missing -eq 1 ]; then
        exit 1
    fi
}

get_domain() {
    echo -ne "${YELLOW}${BOLD}? Enter target domain (e.g., google.com): ${NC}"
    read -r DOMAIN
    if [[ -z "$DOMAIN" ]]; then
        echo -e "${RED}Invalid domain.${NC}"
        sleep 1
        return 1
    fi
    # Sanitize
    DOMAIN=$(echo "$DOMAIN" | sed -e 's|^[^/]*//||' -e 's|/.*$||')
    LOG_FILE="/dev/null" # Reset log file or set to specific if recording
}

# --- Core Tasks ---

task_ping() {
    echo -e "\n${CYAN}--- Connectivity ---${NC}"
    execute_task "Ping Check" "ping -c 3 $DOMAIN"
}

task_dns() {
    echo -e "\n${CYAN}--- DNS Analysis ---${NC}"
    execute_task "A Records" "dig +time=2 +tries=1 +short $DOMAIN A"
    execute_task "MX Records" "dig +time=2 +tries=1 +short $DOMAIN MX"
    execute_task "NS Records" "dig +time=2 +tries=1 +short $DOMAIN NS"
    execute_task "TXT Records" "dig +time=2 +tries=1 +short $DOMAIN TXT"
}

task_email_sec() {
    echo -e "\n${CYAN}--- Email Security ---${NC}"
    execute_task "SPF Record" "dig +time=2 +tries=1 +short $DOMAIN TXT | grep 'v=spf1' || echo 'No SPF found'"
    execute_task "DMARC Record" "dig +time=2 +tries=1 +short _dmarc.$DOMAIN TXT || echo 'No DMARC found'"
}

task_headers() {
    echo -e "\n${CYAN}--- Security Headers ---${NC}"
    # We use a custom function here to parse nicely
    local cmd="curl -I -L -s --max-time 10 '$DOMAIN' | grep -iE 'Strict-Transport-Security|Content-Security-Policy|X-Frame-Options|X-Content-Type-Options|Referrer-Policy'"
    execute_task "Fetching Headers" "$cmd"
}

perform_port_scan() {
    local target_ip
    # Resolve IP once to avoid DNS overhead/issues during parallel scan
    target_ip=$(dig +short "$DOMAIN" | grep -E '^[0-9]' | head -n 1)
    # Fallback to domain if dig fails or returns nothing (e.g. /etc/hosts entry)
    if [[ -z "$target_ip" ]]; then target_ip="$DOMAIN"; fi
    
    local ports=("21" "22" "25" "53" "80" "443" "3306" "5432" "8080" "8443")
    
    for port in "${ports[@]}"; do
        (
            # Try to connect. 
            # -z: Zero-I/O mode (scan)
            # -w 2: Timeout in seconds
            if nc -z -w 2 "$target_ip" "$port" < /dev/null > /dev/null 2>&1; then
                 echo -e "    Port $port: ${GREEN}OPEN${NC}"
            fi
        ) &
    done
    wait
}
export -f perform_port_scan

task_ports() {
    echo -e "\n${CYAN}--- Port Scan (Parallel) ---${NC}"
    execute_task "Scanning Common Ports" "perform_port_scan"
}

task_ssl() {
    echo -e "\n${CYAN}--- SSL/TLS Audit ---${NC}"
    # Use run_with_timeout wrapper (10s), input from /dev/null
    local cmd="run_with_timeout 10 \"openssl s_client -connect ${DOMAIN}:443 -servername $DOMAIN < /dev/null 2>/dev/null | openssl x509 -noout -dates -issuer -subject\""
    execute_task "Certificate Details" "$cmd"
}

task_tech() {
    echo -e "\n${CYAN}--- Technology Stack ---${NC}"
    if [ -f "$NODE_WRAPPER" ] && command -v node &> /dev/null; then
        # Call the node wrapper directly, it handles its own spinner/formatting
        node "$NODE_WRAPPER" "$DOMAIN" | tee -a "$LOG_FILE"
    else
        execute_task "CMS Detection (Legacy)" "curl -I -L -s --max-time 10 $DOMAIN | grep 'Server\|X-Powered-By'"
    fi
}

task_subdomains() {
    echo -e "\n${CYAN}--- Subdomain Discovery ---${NC}"
    local subs="www dev staging api mail shop app admin"
    local cmd="for sub in $subs; do if dig +time=2 +tries=1 +short \${sub}.${DOMAIN} | grep -qE '^[0-9]'; then echo \"[FOUND] \${sub}.${DOMAIN}\"; fi; done"
    execute_task "Scanning List" "$cmd"
}

task_whois() {
    echo -e "\n${CYAN}--- Registration Info ---${NC}"
    # Whois for .de uses 'nserver' and 'Status', while others use 'Name Server' and 'Registrar'
    # We filter out the 'Status: connect' noise from certain whois clients
    local cmd="run_with_timeout 10 \"whois $DOMAIN | grep -Ei 'Registrar:|Creation Date:|Registry Expiry Date:|nserver:|Name Server:|Changed:|Updated Date:|Status:' | grep -vEi 'connect|Terms of Use' | sed 's/^[[:space:]]*//' | sort -u | head -n 12\""
    execute_task "Whois Lookup" "$cmd"
}

task_full() {
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    LOG_FILE="$LOG_DIR/${DOMAIN}_${TIMESTAMP}.log"
    echo "Report for $DOMAIN - $TIMESTAMP" > "$LOG_FILE"
    
    echo -e "${MAGENTA}${BOLD}Running Full Audit for: $DOMAIN${NC}"
    echo -e "${DIM}Logs saving to: $LOG_FILE${NC}"
    
    task_ping
    task_dns
    task_email_sec
    task_headers
    task_ssl
    task_ports
    task_tech
    task_subdomains
    task_whois
    
    echo -e "\n${GREEN}${BOLD}Audit Complete!${NC}"
}

# --- Main Logic ---

trap 'tput cnorm; echo -e "\n${RED}Aborted.${NC}"; exit 1' SIGINT

check_dependencies

# Argument Mode
if [[ -n "$1" ]]; then
    DOMAIN="$1"
    DOMAIN=$(echo "$DOMAIN" | sed -e 's|^[^/]*//||' -e 's|/.*$||')
    case "$2" in
        "tech") task_tech ;; 
        "ping") task_ping ;; 
        "dns") task_dns ;; 
        "ssl") task_ssl ;; 
        *) task_full ;; 
    esac
    exit 0
fi

# Interactive Mode
print_header
while true; do
    if [[ -z "$DOMAIN" ]]; then 
        get_domain || continue
        echo -e "${DIM}Selected: $DOMAIN${NC}"
    fi
    
    echo -e "\n${BOLD}Available Scans:${NC}"
    echo -e "  ${CYAN}1)${NC} Full Audit             ${CYAN}2)${NC} Tech Stack (Adv.)"
    echo -e "  ${CYAN}3)${NC} DNS Records            ${CYAN}4)${NC} Connectivity (Ping)"
    echo -e "  ${CYAN}5)${NC} SSL/TLS Info           ${CYAN}6)${NC} Security Headers"
    echo -e "  ${CYAN}7)${NC} Port Scan              ${CYAN}8)${NC} Subdomains"
    echo -e "  ${CYAN}9)${NC} Email Sec (SPF/DMARC)  ${CYAN}10)${NC} Whois Info"
    echo -e "  ${CYAN}c)${NC} Change Domain          ${CYAN}q)${NC} Quit"
    
    echo -ne "\n${YELLOW}${ICON_ARROW} Select option: ${NC}"
    read -r choice
    
    case $choice in
        1) task_full ;; 
        2) task_tech ;; 
        3) task_dns ;; 
        4) task_ping ;; 
        5) task_ssl ;; 
        6) task_headers ;; 
        7) task_ports ;; 
        8) task_subdomains ;; 
        9) task_email_sec ;; 
        10) task_whois ;; 
        c) DOMAIN=""; clear; print_header ;; 
        q|exit) echo -e "${CYAN}Goodbye.${NC}"; exit 0 ;; 
        *) echo -e "${RED}Invalid selection.${NC}" ;; 
    esac
done
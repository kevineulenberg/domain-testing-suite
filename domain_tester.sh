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

# --- Icons & Emojis ---
ICON_CHECK="✨"
ICON_CROSS="💥"
ICON_INFO="ℹ️"
ICON_ARROW="➜"

# Section Emojis
EMOJI_PING="📶"
EMOJI_DNS="📡"
EMOJI_EMAIL="📧"
EMOJI_SEC="🛡️"
EMOJI_SSL="🔒"
EMOJI_TECH="🤖"
EMOJI_SUB="🏘️"
EMOJI_WHOIS="📇"
EMOJI_PORT="🔌"
EMOJI_ROCKET="🚀"
EMOJI_GEAR="⚙️"
EMOJI_GLOBE="🌐"
EMOJI_SEARCH="🔍"
EMOJI_GEO="🌍"
EMOJI_FILE="📄"
EMOJI_TIME="⏳"
EMOJI_HTTP="🚦"
EMOJI_SEO="🎯"
EMOJI_RBL="🚫"
EMOJI_CARBON="🌱"
EMOJI_A11Y="♿"
EMOJI_LINK="🔗"

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
    while kill -0 $pid 2>/dev/null; do
        local temp=${spinstr#?}
        printf "${CYAN}%c${NC}" "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b"
    done
    printf " "
    printf "\b"
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
    echo -e "\n${CYAN}--- ${EMOJI_PING} Connectivity ---${NC}"
    execute_task "Ping Check" "ping -c 3 $DOMAIN"
}

task_dns() {
    echo -e "\n${CYAN}--- ${EMOJI_DNS} DNS Analysis ---${NC}"
    execute_task "A Records" "dig +time=2 +tries=1 +short $DOMAIN A"
    execute_task "MX Records" "dig +time=2 +tries=1 +short $DOMAIN MX"
    execute_task "NS Records" "dig +time=2 +tries=1 +short $DOMAIN NS"
    execute_task "TXT Records" "dig +time=2 +tries=1 +short $DOMAIN TXT"
}

task_email_sec() {
    echo -e "\n${CYAN}--- ${EMOJI_EMAIL} Email Security ---${NC}"
    execute_task "SPF Record" "dig +time=2 +tries=1 +short $DOMAIN TXT | grep 'v=spf1' || echo 'No SPF found'"
    execute_task "DMARC Record" "dig +time=2 +tries=1 +short _dmarc.$DOMAIN TXT || echo 'No DMARC found'"
}

task_headers() {
    echo -e "\n${CYAN}--- ${EMOJI_SEC} Security Headers ---${NC}"
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
    echo -e "\n${CYAN}--- ${EMOJI_PORT} Port Scan (Parallel) ---${NC}"
    execute_task "Scanning Common Ports" "perform_port_scan"
}

task_ssl() {
    echo -e "\n${CYAN}--- ${EMOJI_SSL} SSL/TLS Audit ---${NC}"
    # Use run_with_timeout wrapper (10s), input from /dev/null
    local cmd="run_with_timeout 10 \"openssl s_client -connect ${DOMAIN}:443 -servername $DOMAIN < /dev/null 2>/dev/null | openssl x509 -noout -dates -issuer -subject\""
    execute_task "Certificate Details" "$cmd"
}

task_tech() {
    echo -e "\n${CYAN}--- ${EMOJI_TECH} Technology Stack ---${NC}"
    if [ -f "$NODE_WRAPPER" ] && command -v node &> /dev/null; then
        # Call the node wrapper directly, it handles its own spinner/formatting
        node "$NODE_WRAPPER" "$DOMAIN" | tee -a "$LOG_FILE"
    else
        execute_task "CMS Detection (Legacy)" "curl -I -L -s --max-time 10 $DOMAIN | grep 'Server\|X-Powered-By'"
    fi
}

task_seo() {
    echo -e "\n${CYAN}--- ${EMOJI_SEO} SEO Deep Dive ---${NC}"
    if [ -f "$NODE_WRAPPER" ] && command -v node &> /dev/null; then
        node "$NODE_WRAPPER" "$DOMAIN" "seo" | tee -a "$LOG_FILE"
    else
        echo -e "    ${RED}${ICON_CROSS} Node.js or SEO scanner missing.${NC}"
    fi
}

task_rbl() {
    echo -e "\n${CYAN}--- ${EMOJI_RBL} Reputation Check ---${NC}"
    # Resolve IP
    local ip=$(dig +short "$DOMAIN" | grep -E '^[0-9]' | head -n 1)
    if [[ -z "$ip" ]]; then
        echo "    ${RED}Could not resolve IP.${NC}"
        return
    fi
    
    # Reverse IP for RBL query (1.2.3.4 -> 4.3.2.1)
    local rev_ip=$(echo "$ip" | awk -F. '{print $4"."$3"."$2"."$1}')
    
    local rbls=("zen.spamhaus.org" "b.barracudacentral.org" "dnsbl.sorbs.net")
    
    for rbl in "${rbls[@]}"; do
        # If dig returns an answer (usually 127.0.0.x), it's listed
        local lookup="${rev_ip}.${rbl}"
        local result=$(dig +short "$lookup")
        
        if [[ -n "$result" ]]; then
            echo -e "    ${RED}${ICON_CROSS} LISTED on $rbl ($result)${NC}"
        else
            echo -e "    ${GREEN}${ICON_CHECK} Clean on $rbl${NC}"
        fi
    done
}

task_carbon() {
    echo -e "\n${CYAN}--- ${EMOJI_CARBON} Eco-Digital Footprint ---${NC}"
    if [ -f "$NODE_WRAPPER" ] && command -v node &> /dev/null; then
        node "$NODE_WRAPPER" "$DOMAIN" "carbon" | tee -a "$LOG_FILE"
    else
        echo -e "    ${RED}${ICON_CROSS} Node.js missing.${NC}"
    fi
}

task_a11y() {
    echo -e "\n${CYAN}--- ${EMOJI_A11Y} Accessibility Forensics ---${NC}"
    if [ -f "$NODE_WRAPPER" ] && command -v node &> /dev/null; then
        node "$NODE_WRAPPER" "$DOMAIN" "a11y" | tee -a "$LOG_FILE"
    else
        echo -e "    ${RED}${ICON_CROSS} Node.js missing.${NC}"
    fi
}

task_links() {
    echo -e "\n${CYAN}--- ${EMOJI_LINK} Broken Link Detector ---${NC}"
    if [ -f "$NODE_WRAPPER" ] && command -v node &> /dev/null; then
        node "$NODE_WRAPPER" "$DOMAIN" "links" | tee -a "$LOG_FILE"
    else
        echo -e "    ${RED}${ICON_CROSS} Node.js missing.${NC}"
    fi
}

task_subdomains() {
    echo -e "\n${CYAN}--- ${EMOJI_SUB} Subdomain Discovery ---${NC}"
    
    # 1. Wildcard / Catch-all Check
    local rand_sub="wildcard-check-$(date +%s)"
    # Resolve and grab the first line that looks like an IP
    local wildcard_ip=$(dig +time=2 +tries=1 +short "${rand_sub}.${DOMAIN}" | grep -E '^[0-9]' | head -n 1)
    
    if [[ -n "$wildcard_ip" ]]; then
        echo -e "    ${YELLOW}${ICON_INFO} Wildcard DNS detected!${NC}"
        echo -e "    ${DIM}Reason: Random subdomain '${rand_sub}.${DOMAIN}' resolved to ${wildcard_ip}.${NC}"
        echo -e "    ${DIM}Skipping enumeration to avoid 100% false positives.${NC}"
        return
    fi

    # 2. Run Dictionary Scan if no wildcard
    local subs="www dev staging api mail shop app admin"
    local cmd="for sub in $subs; do if dig +time=2 +tries=1 +short \${sub}.${DOMAIN} | grep -qE '^[0-9]'; then echo \"[FOUND] \${sub}.${DOMAIN}\"; fi; done"
    execute_task "Scanning List" "$cmd"
}

task_whois() {
    echo -e "\n${CYAN}--- ${EMOJI_WHOIS} Registration Info ---${NC}"
    # Whois for .de uses 'nserver' and 'Status', while others use 'Name Server' and 'Registrar'
    # We filter out the 'Status: connect' noise from certain whois clients
    local cmd="run_with_timeout 10 \"whois $DOMAIN | grep -Ei 'Registrar:|Creation Date:|Registry Expiry Date:|nserver:|Name Server:|Changed:|Updated Date:|Status:' | grep -vEi 'connect|Terms of Use' | sed 's/^[[:space:]]*//' | sort -u | head -n 12\""
    execute_task "Whois Lookup" "$cmd"
}

task_geoip() {
    echo -e "\n${CYAN}--- ${EMOJI_GEO} Server Location ---${NC}"
    # Resolve IP first
    local ip=$(dig +short "$DOMAIN" | grep -E '^[0-9]' | head -n 1)
    if [[ -z "$ip" ]]; then
        echo "    ${RED}${ICON_CROSS} Could not resolve IP for GeoIP.${NC}"
        return
    fi
    # Use ip-api.com line format for easy parsing without jq
    # We remove empty lines and trailing commas
    local cmd="curl -s 'http://ip-api.com/line/$ip?fields=country,city,isp,org' | sed '/^$/d' | tr '\n' ',' | sed 's/,,*/,/g' | sed 's/,$//' | sed 's/,/, /g'"
    execute_task "GeoIP Lookup ($ip)" "$cmd"
}

task_content() {
    echo -e "\n${CYAN}--- ${EMOJI_FILE} Content Recon ---${NC}"
    
    # Robots.txt (Check for 200 or 3xx)
    local cmd_robots="status=\$(curl -s -o /dev/null -w \"%{http_code}\" -L --max-time 5 'http://$DOMAIN/robots.txt'); if [[ \$status =~ ^(200|301|302)\$ ]]; then echo \"${ICON_CHECK} Found (HTTP \$status)\"; else echo 'Not Found'; fi"
    execute_task "robots.txt" "$cmd_robots"
    
    # Sitemap
    local cmd_sitemap="status=\$(curl -s -o /dev/null -w \"%{http_code}\" -L --max-time 5 'http://$DOMAIN/sitemap.xml'); if [[ \$status =~ ^(200|301|302)\$ ]]; then echo \"${ICON_CHECK} Found (HTTP \$status)\"; else echo 'Not Found'; fi"
    execute_task "sitemap.xml" "$cmd_sitemap"
    
    # Security.txt
    local cmd_sec="status=\$(curl -s -o /dev/null -w \"%{http_code}\" -L --max-time 5 'http://$DOMAIN/.well-known/security.txt'); if [[ \$status =~ ^(200|301|302)\$ ]]; then echo \"${ICON_CHECK} Found (HTTP \$status)\"; else echo 'Not Found'; fi"
    execute_task "security.txt" "$cmd_sec"
}

task_http() {
    echo -e "\n${CYAN}--- ${EMOJI_HTTP} HTTP Methods ---${NC}"
    # Check Allowed Methods via OPTIONS
    local cmd="out=\$(curl -s -I -X OPTIONS --max-time 5 'http://$DOMAIN' | grep -i 'allow:' | sed 's/allow: //i'); if [[ -n \"\$out\" ]]; then echo \"\$out\"; else echo -e \"${DIM}(None detected or Blocked)${NC}\"; fi"
    execute_task "Allowed Methods" "$cmd"
}

task_archive() {
    echo -e "\n${CYAN}--- ${EMOJI_TIME} Wayback Machine ---${NC}"
    # Simple check if snapshots exist
    local cmd="curl -s 'http://archive.org/wayback/available?url=$DOMAIN' | grep -o '\"available\": true' > /dev/null && echo '${ICON_CHECK} Snapshots available' || echo 'No snapshots found'"
    execute_task "Archive Check" "$cmd"
}

task_full() {
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    LOG_FILE="$LOG_DIR/${DOMAIN}_${TIMESTAMP}.log"
    echo "Report for $DOMAIN - $TIMESTAMP" > "$LOG_FILE"
    
    echo -e "${MAGENTA}${BOLD}${EMOJI_ROCKET} Running Full Audit for: $DOMAIN${NC}"
    echo -e "${DIM}Logs saving to: $LOG_FILE${NC}"
    
    task_ping
    task_geoip
    task_dns
    task_email_sec
    task_headers
    task_http
    task_ssl
    task_ports
    task_tech
    task_seo
    task_rbl
    task_carbon
    task_a11y
    task_links
    task_content
    task_subdomains
    task_archive
    task_whois
    
    echo -e "\n${GREEN}${BOLD}${EMOJI_SUCCESS} Audit Complete!${NC}"
}

# --- Main Logic ---

trap 'tput cnorm; echo -e "\n${RED}${ICON_CROSS} Aborted.${NC}"; exit 1' SIGINT

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
        "seo") task_seo ;;
        "rbl") task_rbl ;;
        "carbon") task_carbon ;;
        "a11y") task_a11y ;;
        "links") task_links ;;
        *) task_full ;; 
    esac
    exit 0
fi

# Interactive Mode
print_header
while true; do
    if [[ -z "$DOMAIN" ]]; then 
        get_domain || continue
        echo -e "${DIM}${ICON_CHECK} Selected: $DOMAIN${NC}"
    fi
    
    echo -e "\n${BOLD}${EMOJI_GEAR} Available Scans:${NC}"
    echo -e "  ${CYAN}1)${NC} ${EMOJI_ROCKET} Full Audit           ${CYAN}2)${NC} ${EMOJI_TECH} Tech Stack (Adv.)"
    echo -e "  ${CYAN}3)${NC} ${EMOJI_DNS} DNS Records          ${CYAN}4)${NC} ${EMOJI_PING} Connectivity (Ping)"
    echo -e "  ${CYAN}5)${NC} ${EMOJI_SSL} SSL/TLS Info         ${CYAN}6)${NC} ${EMOJI_SEC} Security Headers"
    echo -e "  ${CYAN}7)${NC} ${EMOJI_PORT} Port Scan            ${CYAN}8)${NC} ${EMOJI_SUB} Subdomains"
    echo -e "  ${CYAN}9)${NC} ${EMOJI_EMAIL} Email Sec (SPF)      ${CYAN}10)${NC} ${EMOJI_WHOIS} Whois Info"
    echo -e "  ${CYAN}11)${NC} ${EMOJI_GEO} GeoIP Location       ${CYAN}12)${NC} ${EMOJI_FILE} Files (Robots/Site)"
    echo -e "  ${CYAN}13)${NC} ${EMOJI_TIME} Wayback Machine      ${CYAN}14)${NC} ${EMOJI_HTTP} HTTP Methods"
    echo -e "  ${CYAN}15)${NC} ${EMOJI_SEO} SEO Deep Dive        ${CYAN}16)${NC} ${EMOJI_RBL} Reputation / RBL"
    echo -e "  ${CYAN}17)${NC} ${EMOJI_CARBON} Eco-Impact (CO2)    ${CYAN}18)${NC} ${EMOJI_A11Y} A11y Forensics"
    echo -e "  ${CYAN}19)${NC} ${EMOJI_LINK} Broken Links"
    echo -e "  ${CYAN}c)${NC} ${EMOJI_SEARCH} Change Domain        ${CYAN}q)${NC} 🚪 Quit"
    
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
        11) task_geoip ;;
        12) task_content ;;
        13) task_archive ;;
        14) task_http ;;
        15) task_seo ;;
        16) task_rbl ;;
        17) task_carbon ;;
        18) task_a11y ;;
        19) task_links ;;
        c) DOMAIN=""; clear; print_header ;; 
        q|exit) echo -e "${CYAN}Goodbye.${NC}"; exit 0 ;; 
        *) echo -e "${RED}${ICON_CROSS} Invalid selection.${NC}" ;; 
    esac
done
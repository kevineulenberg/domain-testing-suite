#!/bin/bash

# --- Color Definitions ---
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# --- Initialization ---
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
LOG_DIR="$SCRIPT_DIR/domain_logs"
mkdir -p "$LOG_DIR"
LOG_FILE="/dev/null"

print_header() {
    clear
    echo -e "${CYAN}${BOLD}=============================================="
    echo -e "      AVANT-GARDE DOMAIN TESTING SUITE        "
    echo -e "==============================================${NC}"
}

check_dependencies() {
    local deps=("dig" "curl" "openssl" "whois" "ping" "nc")
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            if [[ "$dep" != "nc" ]]; then 
                echo -e "${RED}Error: $dep is not installed.${NC}"
                exit 1
            fi
        fi
done
}

get_domain() {
    echo -ne "${YELLOW}Enter domain (e.g., google.com): ${NC}"
    read -r DOMAIN
    if [[ -z "$DOMAIN" ]]; then
        echo -e "${RED}Invalid domain.${NC}"
        sleep 1
        return 1
    fi
    DOMAIN=$(echo "$DOMAIN" | sed -e 's|^[^/]*//||' -e 's|/.*$||')
    LOG_FILE="/dev/null"
}

# --- Tool Functions ---

run_ping() {
    echo -e "\n${BOLD}--- Connectivity (Ping) ---${NC}"
    ping -c 4 "$DOMAIN" 2>&1 | tee -a "$LOG_FILE"
}

run_dns() {
    echo -e "\n${BOLD}--- DNS Records (A, MX, TXT, NS) ---${NC}"
    {
        echo -e "${CYAN}[A Records]${NC}"
        dig +short "$DOMAIN" A
        echo -e "${CYAN}[MX Records]${NC}"
        dig +short "$DOMAIN" MX
        echo -e "${CYAN}[NS Records]${NC}"
        dig +short "$DOMAIN" NS
        echo -e "${CYAN}[TXT Records]${NC}"
        dig +short "$DOMAIN" TXT
    } | tee -a "$LOG_FILE"
}

run_email_security() {
    echo -e "\n${BOLD}--- Email Security (SPF, DMARC) ---${NC}"
    {
        echo -e "${CYAN}[SPF Record]${NC}"
        dig +short "$DOMAIN" TXT | grep "v=spf1"
        echo -e "${CYAN}[DMARC Record]${NC}"
        dig +short "_dmarc.$DOMAIN" TXT
    } | tee -a "$LOG_FILE"
}

run_security_headers() {
    echo -e "\n${BOLD}--- Security Headers Analysis ---${NC}"
    {
        local headers
        headers=$(curl -I -L -s "$DOMAIN")
        for header in "Strict-Transport-Security" "Content-Security-Policy" "X-Frame-Options" "X-Content-Type-Options" "Referrer-Policy" "Permissions-Policy"; do
            local val
            val=$(echo "$headers" | grep -i "$header")
            if [[ -n "$val" ]]; then
                echo -e "${GREEN}  [PASS]${NC} $val"
            else
                echo -e "${RED}  [MISSING]${NC} $header"
            fi
        done
    } | tee -a "$LOG_FILE"
}

run_port_scan() {
    echo -e "\n${BOLD}--- Basic Port Scan (Common Ports) ---${NC}"
    local ports=(21 22 25 53 80 443 3306 5432 8080)
    {
        for port in "${ports[@]}"; do
            (
                if nc -z -w 3 "$DOMAIN" "$port" &>/dev/null; then
                    echo -e "  ${GREEN}Port $port is OPEN${NC}"
                fi
            ) &
        done
        wait
    } | tee -a "$LOG_FILE"
}

run_ssl() {
    echo -e "\n${BOLD}--- SSL/TLS Status ---${NC}"
    {
        local T_CMD=""
        if command -v timeout &> /dev/null; then
            T_CMD="timeout 5"
        elif command -v gtimeout &> /dev/null; then
            T_CMD="gtimeout 5"
        fi

        local ssl_info
        if [[ -n "$T_CMD" ]]; then
            ssl_info=$($T_CMD openssl s_client -connect "${DOMAIN}:443" -servername "$DOMAIN" </dev/null 2>/dev/null)
        else
            ssl_info=$(openssl s_client -connect "${DOMAIN}:443" -servername "$DOMAIN" </dev/null 2>/dev/null)
        fi

        if [[ -n "$ssl_info" ]]; then
            echo "$ssl_info" | openssl x509 -noout -dates -issuer -subject | sed 's/^/  /'
        else
            echo -e "${RED}  Could not establish SSL connection to ${DOMAIN}:443${NC}"
        fi
    } | tee -a "$LOG_FILE"
}

run_cms_detect() {
    echo -e "\n${BOLD}--- CMS & Technology Detection ---${NC}"
    {
        local headers
        headers=$(curl -I -L -s --max-time 5 "$DOMAIN")
        local body
        body=$(curl -s --max-time 5 -L "$DOMAIN")

        echo -ne "  ${CYAN}Server/CDN:${NC} "
        local server_info
        server_info=$(echo "$headers" | grep -i "^Server:" | cut -d' ' -f2- | tr -d '\r')
        if echo "$headers" | grep -iq "cf-ray"; then
            echo "Cloudflare (Proxy) / $server_info"
        elif echo "$headers" | grep -iq "x-akamai"; then
            echo "Akamai CDN"
        elif echo "$headers" | grep -iq "x-vercel-id"; then
            echo "Vercel / $server_info"
        elif echo "$headers" | grep -iq "x-github-request"; then
            echo "GitHub Pages"
        else
            echo "${server_info:-Unknown}"
        fi

        echo -ne "  ${CYAN}Platform/CMS:${NC} "
        if echo "$body" | grep -iq "wp-content\|/wp-includes"; then echo "WordPress";
        elif echo "$body" | grep -iq "content=\"Joomla"; then echo "Joomla";
        elif echo "$body" | grep -iq "Drupal"; then echo "Drupal";
        elif echo "$body" | grep -iq "shopify.com"; then echo "Shopify";
        elif echo "$body" | grep -iq "squarespace.com"; then echo "Squarespace";
        elif echo "$body" | grep -iq "wix.com"; then echo "Wix";
        elif echo "$headers" | grep -iq "X-Powered-By: PHP"; then echo "PHP (Generic)";
        elif echo "$headers" | grep -iq "X-Powered-By: ASP.NET"; then echo "ASP.NET";
        else echo "Custom / Not detected"; fi

        echo -ne "  ${CYAN}Frameworks:${NC} "
        local fw=()
        if echo "$body" | grep -iq "_next/static"; then fw+=("Next.js"); fi
        if echo "$body" | grep -iq "react"; then fw+=("React"); fi
        if echo "$body" | grep -iq "vue.js\|vue@"; then fw+=("Vue.js"); fi
        if echo "$body" | grep -iq "angular"; then fw+=("Angular"); fi
        if echo "$body" | grep -iq "bootstrap.min.css"; then fw+=("Bootstrap"); fi
        if echo "$body" | grep -iq "tailwind"; then fw+=("Tailwind CSS"); fi
        if echo "$body" | grep -iq "jquery"; then fw+=("jQuery"); fi
        
        if [ ${#fw[@]} -eq 0 ]; then echo "None detected"; else echo "${fw[*]}"; fi

        echo -ne "  ${CYAN}Tracking/Tools:${NC} "
        local trackers=()
        if echo "$body" | grep -iq "googletagmanager.com"; then trackers+=("GTM"); fi
        if echo "$body" | grep -iq "google-analytics.com\|UA-\|G-"; then trackers+=("Google Analytics"); fi
        if echo "$body" | grep -iq "facebook.net/en_US/fbevents.js"; then trackers+=("Facebook Pixel"); fi
        if echo "$body" | grep -iq "hotjar"; then trackers+=("Hotjar"); fi
        
        if [ ${#trackers[@]} -eq 0 ]; then echo "None detected"; else echo "${trackers[*]}"; fi
    } | tee -a "$LOG_FILE"
}

run_subdomain_scan() {
    echo -e "\n${BOLD}--- Passive Subdomain Discovery (Common) ---${NC}"
    local subdomains=("www" "dev" "staging" "api" "mail" "shop" "blog" "test" "m" "admin" "vpn")
    {
        for sub in "${subdomains[@]}"; do
            (
                local full_sub="${sub}.${DOMAIN}"
                if dig +short "$full_sub" | grep -qE "^[0-9]"; then
                    echo -e "  ${GREEN}[FOUND]${NC} $full_sub"
                fi
            ) &
        done
        wait
    } | tee -a "$LOG_FILE"
}

run_pagespeed() {
    echo -e "\n${BOLD}--- Google PageSpeed Insights (Mobile) ---${NC}"
    {
        local CLEAN_DOMAIN
        CLEAN_DOMAIN=$(echo "$DOMAIN" | sed -E 's|^https?://||i' | sed -E 's|^https?:||i' | cut -d'/' -f1)
        local response
        response=$(curl -s "https://www.googleapis.com/pagespeedonline/v5/runPagespeed?url=https://${CLEAN_DOMAIN}&strategy=mobile")

        if echo "$response" | grep -q "rateLimitExceeded"; then
            echo -e "  ${RED}API Quota Exceeded.${NC}"
            return
        fi

        local score
        score=$(echo "$response" | grep -o '"score": [0-9.]*' | head -1 | awk '{print $2 * 100}')
        if [[ -n "$score" ]]; then
            echo -e "  ${CYAN}Overall Score:${NC} ${BOLD}${score}/100${NC}"
        else
            echo -e "${RED}  Could not fetch PageSpeed data.${NC}"
        fi
    } | tee -a "$LOG_FILE"
}

run_http() {
    echo -e "\n${BOLD}--- HTTP Headers & Status ---${NC}"
    curl -I -L -s "$DOMAIN" | grep -E "HTTP/|HTTP\/2|Location:|Server:|Content-Type:|strict-transport-security" | tee -a "$LOG_FILE"
}

run_whois() {
    echo -e "\n${BOLD}--- Whois Information (Summary) ---${NC}"
    local whois_data
    whois_data=$(whois "$DOMAIN")
    if echo "$DOMAIN" | grep -q "\.de$"; then
        echo "$whois_data" | grep -Ei "Status:|nserver:|Changed:" | sed 's/^/  /'
    else
        echo "$whois_data" | grep -Ei "Registrar:|Creation Date:|Registry Expiry Date:|Domain Status:|Name Server:|Status:" | sed 's/^/  /'
    fi | tee -a "$LOG_FILE"
}

run_full_audit() {
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    LOG_FILE="$LOG_DIR/${DOMAIN}_${TIMESTAMP}.log"
    echo -e "${BLUE}Session Log started at: $(date)${NC}\n" > "$LOG_FILE"
    echo -e "${BLUE}Target: $DOMAIN${NC}\n" >> "$LOG_FILE"

    echo -e "${GREEN}Starting Full Audit for $DOMAIN...${NC}"
    run_ping
    run_dns
    run_email_security
    run_security_headers
    run_ssl
    run_http
    run_port_scan
    run_cms_detect
    run_subdomain_scan
    run_pagespeed
    run_whois
    echo -e "\n${GREEN}Full Audit Complete. Log saved to $LOG_FILE${NC}"
}

# --- Main Logic ---
check_dependencies

if [[ -n "$1" ]]; then
    DOMAIN="$1"
    DOMAIN=$(echo "$DOMAIN" | sed -e 's|^[^/]*//||' -e 's|/.*$||')
    LOG_FILE="/dev/null"
    case "$2" in
        "ping") run_ping ;; 
        "dns") run_dns ;; 
        "email") run_email_security ;; 
        "headers") run_security_headers ;; 
        "ports") run_port_scan ;; 
        "cms") run_cms_detect ;; 
        "subdomains") run_subdomain_scan ;; 
        "ssl") run_ssl ;; 
        "http") run_http ;; 
        "pagespeed") run_pagespeed ;; 
        "whois") run_whois ;; 
        "full"|*) run_full_audit ;; 
    esac
    exit 0
fi

print_header
while true; do
    if [[ -z "$DOMAIN" ]]; then get_domain || continue; fi
    echo -e "\n${BOLD}Target: ${YELLOW}$DOMAIN${NC}"
    echo -e "1) Ping Test\n2) DNS Lookup\n3) Email Security (SPF/DMARC)\n4) Security Headers\n5) SSL Certificate Check\n6) HTTP Headers\n7) Port Scan\n8) CMS & Tech Detection\n9) Subdomain Scan\n10) Google PageSpeed\n11) Whois Summary\n12) Full Audit (All tests)\n13) Change Domain\n14) Exit"
    echo -ne "\n${CYAN}Select an option [1-14]: ${NC}"
    read -r choice
    case $choice in
        1) run_ping ;; 2) run_dns ;; 3) run_email_security ;; 4) run_security_headers ;; 5) run_ssl ;; 6) run_http ;; 7) run_port_scan ;; 8) run_cms_detect ;; 9) run_subdomain_scan ;; 10) run_pagespeed ;; 11) run_whois ;; 12) run_full_audit ;; 13) DOMAIN="" ; clear ; print_header ;; 14) exit 0 ;; *) echo -e "${RED}Invalid option.${NC}" ;;
    esac
done

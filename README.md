# 🌌 Domain Testing Suite: Avant-Garde Edition

A minimalist, high-performance domain analysis ecosystem. This suite bridges the gap between raw shell forensics, deep-web intelligence, and specialized vulnerability assessment.

## ⚡️ Core Intelligence

### 🛡️ Security & Network
- **Deep SSL/TLS Inspection:** Certificate validity, issuer chains, and expiration logic.
- **Port Reconnaissance:** Parallel, non-blocking scans of critical infrastructure ports (optimized for macOS).
- **Email Security:** Rigorous SPF and DMARC record verification to prevent spoofing.
- **Reputation Check:** Automated RBL (Real-time Blackhole List) lookups against Spamhaus, Barracuda, and SORBS.
- **Security Headers:** Audit of CSP, HSTS, X-Frame-Options, and more.
- **GeoIP Forensics:** Precise server location and ISP attribution.

### 🧠 Application & Tech
- **Tech Stack Detection:** Custom heuristic engine identifying CMS (WP, Shopify), Frameworks (React, Next.js), CDNs, and Analytics.
- **SEO Deep Dive:** Analysis of meta tags, viewport settings, heading structures, and robotic directives.
- **Content Recon:** automated checks for `robots.txt`, `sitemap.xml`, and security policy files.
- **Wayback Machine:** Instant verification of historical snapshots.

### 🌱 Performance & Quality
- **Eco-Digital Footprint:** Carbon emission estimation per page view based on resource weight.
- **Accessibility Forensics (A11y):** Static analysis of WCAG compliance (Alt text, labels, contrast).
- **Broken Link Detector:** Recursive crawler identifying dead internal and external links.

### 🕵️ Special Operations: WordPress Unit
*Activated automatically upon WordPress detection.*
- **Vulnerability Scanner:** Deep scan for known core, theme, and plugin vulnerabilities.
- **User Enumeration:** Identification of author IDs and usernames.
- **Configuration Audit:** Checks for exposed XML-RPC, REST API, and directory listings.
- **Version Intelligence:** Precise version fingerprinting via multiple vectors.

## 🚀 Installation & Setup

### Prerequisites
- **Node.js:** v16+ (Core Logic)
- **Python:** 3.7+ (Forensic Modules)
- **System Tools:** `dig`, `curl`, `whois`, `openssl`, `nc`

### Quick Start
```bash
# 1. Clone & Install (includes Python venv setup)
npm install
# Note: The post-install script or manual setup of 'tools/wp_scanner' might be needed if not fully automated.

# 2. Global Access (Recommended)
# Add this to your ~/.zshrc or ~/.bashrc:
alias domain-testing='node "/Users/kevgut/Local Sites/domain-testing-suite/server.js"'
alias domain-testing-cli='"/Users/kevgut/Local Sites/domain-testing-suite/domain_tester.sh"'

# 3. Reload config
source ~/.zshrc
```

## 🛠 Usage

### Web Interface (Visual)
Start the server to access the dashboard:
```bash
domain-testing
```
Visit: [http://localhost:4567](http://localhost:4567)

### CLI Mode (Headless)
Run the suite directly in your terminal:
```bash
domain-testing-cli                   # Interactive Menu
domain-testing-cli example.com       # Full Auto Scan
domain-testing-cli example.com tech  # Tech & Security Stack Only
```

## 🏗 Architecture

- **Orchestration:** Node.js (Express) & Bash acting as the central nervous system.
- **Network Layer:** Optimized Shell scripts (`domain_tester.sh`) for low-latency network tasks.
- **Forensic Layer:** Python (`WP-Scanner`) for deep vulnerability assessment in isolated environments.
- **Analysis Layer:** Node.js modules (`cheerio`, `axios`) for DOM parsing, SEO, and A11y checks.
- **Frontend:** Pure HTML5/JavaScript interface following "Intentional Minimalism" principles.

## 📂 Structure
- `server.js` - API Gateway.
- `domain_tester.sh` - Primary CLI engine.
- `scan_wrapper.js` - Bridge between Bash and Node.js logic.
- `tech_scanner.js` - Heuristic technology detection.
- `wp_security_scanner.js` - Wrapper for the Python forensic unit.
- `tools/wp_scanner/` - Isolated Python vulnerability scanner.
- `domain_logs/` - Persistent session logs.

---
*Precision is the ultimate elegance.*
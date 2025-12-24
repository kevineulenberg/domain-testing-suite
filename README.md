# 🌌 Domain Testing Suite: Avant-Garde Edition

A minimalist, high-performance domain analysis ecosystem. This suite bridges the gap between raw shell forensics and professional-grade web intelligence.

## ⚡️ Core Intelligence

- **Professional Tech Detection:** Integrated **Wappalyzer** engine for deep-dive technology audits (CMS, Frameworks, Analytics).
- **Subdomain Recon:** Parallel, high-speed discovery of common sub-environments.
- **Security Audit:** Deep SSL/TLS inspection and security header analysis.
- **Email Intelligence:** SPF and DMARC record verification.
- **Connectivity:** Low-level ping and parallel port scanning (optimized for macOS).
- **Performance:** Direct integration with Google PageSpeed Insights.
- **Whois & DNS:** Rapid extraction of registrar data and global record types.

## 🚀 Installation & Setup

### Prerequisites
- **Node.js:** v16+ (Required for Wappalyzer)
- **OS:** macOS or Linux
- **Tools:** `dig`, `curl`, `whois`, `openssl`, `nc`

### Quick Start
```bash
# 1. Clone & Install
npm install

# 2. Global Access (Optional but recommended)
# Add this to your ~/.zshrc or ~/.bashrc:
alias domain-testing='node "/Users/kevgut/Local Sites/domain-testing-suite/server.js"'
alias domain-testing-cli='"/Users/kevgut/Local Sites/domain-testing-suite/domain_tester.sh"'

# 3. Reload config
source ~/.zshrc
```

## 🛠 Usage

### Web Interface (Recommended)
Start the server and access the avant-garde UI:
```bash
domain-testing
```
Visit: [http://localhost:4567](http://localhost:4567)

### CLI Mode
Run the suite directly in your terminal from anywhere:
```bash
domain-testing-cli
```
*Note: You can also pass arguments directly:* `domain-testing-cli example.com full`

## 🏗 Architecture

- **Backend:** Node.js (Express) serving as the orchestration layer.
- **Core Engine:** Optimized Bash scripts (`domain_tester.sh`) for low-level network tasks.
- **Intelligence:** Wappalyzer integration for application-layer analysis.
- **Frontend:** Pure HTML5/JavaScript interface following "Intentional Minimalism" principles.

## 📂 Structure
- `server.js` - API Layer & Wappalyzer Integration.
- `domain_tester.sh` - High-performance shell diagnostics.
- `public/` - Avant-garde frontend assets.
- `domain_logs/` - Persistent session logs for all audits.

---
*Precision is the ultimate elegance.*
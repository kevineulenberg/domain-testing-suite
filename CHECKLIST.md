# 🚀 Avant-Garde Expansion Checklist

## Phase 1: Reputation & Security (Bash Native)
- [x] **Reputation / RBL Check**
    - [x] Implement `task_reputation` in `domain_tester.sh`.
    - [x] Check against Spamhaus (zen.spamhaus.org).
    - [x] Check against Barracuda (b.barracudacentral.org).
    - [x] Check against SORBS.

## Phase 2: Advanced Node.js Scanners
- [x] **Create `advanced_scanner.js`**
    - [x] Setup module structure with `axios` and `cheerio`.
- [x] **Broken Link Detector**
    - [x] Extract all `a href` links from main document.
    - [x] Filter internal vs external.
    - [x] Check HTTP status (HEAD request) for top 10 links.
- [x] **Eco-Digital Footprint (Carbon)**
    - [x] Calculate total transfer size (HTML + Assets approximation).
    - [x] Estimate CO2 per visit (0.5g/MB standard).
    - [x] Check Green Web Foundation API (optional/simulated).
- [x] **Accessibility Forensics (A11y)**
    - [x] Static analysis using `cheerio`.
    - [x] Check missing `alt` tags on images.
    - [x] Check empty buttons/links.
    - [x] Check form labels.

## Phase 3: Integration
- [x] **CLI Integration (`domain_tester.sh`)**
    - [x] Add `EMOJI` constants.
    - [x] Register new tasks in `task_full`.
    - [x] Update interactive menu.
- [x] **Wrapper Integration (`scan_wrapper.js`)**
    - [x] Import and route new scanners from `advanced_scanner.js`.
- [x] **Web UI (`public/index.html`)**
    - [x] Add buttons for new scanners.

## Phase 4: Verification
- [ ] Test `hoang-bistro.de` full audit.
- [ ] Verify UI output.
- [ ] Git Commit & Push.

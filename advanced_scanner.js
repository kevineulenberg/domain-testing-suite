const axios = require('axios');
const cheerio = require('cheerio');
const chalk = require('chalk');

// --- Helper: Carbon Calculator ---
// Roughly 0.81 g CO2e per GB for data transfer (2023 estimates vary, but this is a standard baseline)
// We'll estimate page weight based on HTML length + assumed assets. 
// A more accurate way would be headless browser network tracing, but this is "Avant-Garde Lite".
function calculateCarbon(bytes) {
    const gb = bytes / (1024 * 1024 * 1024);
    const co2g = gb * 0.81 * 1000; // Grams
    return co2g.toFixed(4);
}

function gradeCarbon(co2) {
    if (co2 < 0.1) return chalk.green('A+ (Eco-Friendly)');
    if (co2 < 0.5) return chalk.green('A (Very Good)');
    if (co2 < 1.0) return chalk.yellow('B (Average)');
    if (co2 < 2.5) return chalk.hex('#FFA500')('C (Heavy)');
    return chalk.red('D (Polluter)');
}

// --- Task: Eco-Digital Footprint ---
async function analyzeCarbon(domain) {
    const url = `https://${domain}`;
    try {
        const start = Date.now();
        const response = await axios.get(url, {
            headers: { 'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36' },
            timeout: 10000,
            validateStatus: false
        });
        
        // Approximation: HTML size * 1.5 (compression factor) + count of images/scripts * assumed avg size
        const htmlSize = parseInt(response.headers['content-length']) || response.data.length;
        const $ = cheerio.load(response.data);
        
        const resourceCount = $('img').length + $('script').length + $('link[rel="stylesheet"]').length;
        const estimatedTotalBytes = htmlSize + (resourceCount * 15 * 1024); // Assume 15KB per resource avg
        
        const co2 = calculateCarbon(estimatedTotalBytes);
        const grade = gradeCarbon(co2);
        
        return {
            bytes: (estimatedTotalBytes / 1024).toFixed(2) + ' KB',
            co2: co2 + 'g',
            grade: grade,
            resources: resourceCount
        };
    } catch (error) {
        throw new Error(`Carbon analysis failed: ${error.message}`);
    }
}

// --- Task: Accessibility Forensics (Static) ---
async function analyzeA11y(domain) {
    const url = `https://${domain}`;
    try {
        const response = await axios.get(url, {
            headers: { 'User-Agent': 'Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)' },
            timeout: 10000
        });
        const $ = cheerio.load(response.data);
        const issues = [];

        // Check 1: Images without alt
        const imagesNoAlt = $('img:not([alt])').length;
        if (imagesNoAlt > 0) issues.push(`${imagesNoAlt} images missing 'alt' text.`);

        // Check 2: Empty Buttons
        const emptyButtons = $('button:empty').length;
        if (emptyButtons > 0) issues.push(`${emptyButtons} buttons empty (no text/label).`);

        // Check 3: Form Labels
        const inputsNoLabel = $('input:not([type="hidden"]):not([type="submit"]):not([aria-label]):not([id])').length; // very loose check
        if (inputsNoLabel > 0) issues.push(`${inputsNoLabel} form inputs might be missing labels.`);

        // Check 4: HTML Lang attribute
        const lang = $('html').attr('lang');
        if (!lang) issues.push('Missing "lang" attribute on <html> tag.');

        // Score Calculation (Arbitrary "Avant-Garde" Score)
        const score = Math.max(0, 100 - (issues.length * 15));
        
        return {
            score: score,
            issues: issues.length > 0 ? issues : ['No critical static issues found.']
        };

    } catch (error) {
        throw new Error(`A11y check failed: ${error.message}`);
    }
}

// --- Task: Broken Link Detector ---
async function analyzeLinks(domain) {
    const url = `https://${domain}`;
    try {
        const response = await axios.get(url, { timeout: 10000 });
        const $ = cheerio.load(response.data);
        
        const links = [];
        $('a[href]').each((i, el) => {
            const href = $(el).attr('href');
            if (href && !href.startsWith('mailto:') && !href.startsWith('tel:') && !href.startsWith('#')) {
                // Resolve relative URLs
                if (href.startsWith('/')) links.push(`https://${domain}${href}`);
                else if (href.startsWith('http')) links.push(href);
            }
        });

        // Unique limits
        const uniqueLinks = [...new Set(links)].slice(0, 10); // Limit to 10 for speed in CLI
        const broken = [];

        // Parallel Check
        await Promise.all(uniqueLinks.map(async (link) => {
            try {
                await axios.head(link, { timeout: 3000 });
            } catch (err) {
                if (err.response && err.response.status >= 400) {
                    broken.push({ url: link, status: err.response.status });
                } else if (err.code === 'ENOTFOUND' || err.code === 'ECONNREFUSED') {
                    broken.push({ url: link, status: 'Dead' });
                }
            }
        }));

        return {
            checked: uniqueLinks.length,
            broken: broken
        };

    } catch (error) {
        throw new Error(`Link scan failed: ${error.message}`);
    }
}

module.exports = { analyzeCarbon, analyzeA11y, analyzeLinks };

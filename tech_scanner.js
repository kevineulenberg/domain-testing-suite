const axios = require('axios');

async function analyzeTech(domain) {
    const results = [];
    const url = `https://${domain}`;
    
    try {
        const response = await axios.get(url, {
            headers: { 'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36' },
            timeout: 8000,
            validateStatus: false
        });

        const html = response.data;
        const headers = response.headers;

        const checks = [
            // CMS
            { name: 'WordPress', cat: 'CMS', html: /wp-content|wp-includes/i },
            { name: 'Joomla', cat: 'CMS', html: /content="Joomla/i },
            { name: 'Drupal', cat: 'CMS', html: /Drupal/i },
            { name: 'Shopify', cat: 'E-commerce', html: /shopify\.com/i, header: /x-shopify/i },
            { name: 'Squarespace', cat: 'CMS', html: /static1\.squarespace\.com/i },
            { name: 'Wix', cat: 'CMS', html: /wix\.com/i },
            { name: 'Webflow', cat: 'CMS', html: /data-wf-site/i },
            
            // Frameworks
            { name: 'React', cat: 'Frontend', html: /react/i },
            { name: 'Next.js', cat: 'Frontend', html: /_next\/static/i, header: /x-nextjs-cache/i },
            { name: 'Vue.js', cat: 'Frontend', html: /vue\.js|vue@/i },
            { name: 'Nuxt.js', cat: 'Frontend', html: /__NUXT__/i },
            { name: 'Angular', cat: 'Frontend', html: /ng-version/i },
            { name: 'Tailwind CSS', cat: 'CSS', html: /tailwind/i },
            { name: 'Bootstrap', cat: 'CSS', html: /bootstrap/i },
            { name: 'jQuery', cat: 'JS Library', html: /jquery/i },
            
            // CDN / Server
            { name: 'Cloudflare', cat: 'CDN/Security', header: /cf-ray/i, header_key: 'server' },
            { name: 'Vercel', cat: 'Hosting', header: /x-vercel-id/i },
            { name: 'Netlify', cat: 'Hosting', header: /x-nf-request-id/i },
            { name: 'Akamai', cat: 'CDN', header: /x-akamai/i },
            
            // Analytics & Marketing
            { name: 'Google Tag Manager', cat: 'Tag Manager', html: /googletagmanager\.com/i },
            { name: 'Google Analytics', cat: 'Analytics', html: /google-analytics\.com|UA-|G-/i },
            { name: 'Facebook Pixel', cat: 'Analytics', html: /facebook\.net\/en_US\/fbevents\.js/i },
            { name: 'Hotjar', cat: 'Analytics', html: /hotjar/i },
            { name: 'HubSpot', cat: 'CRM', html: /hs-scripts\.com/i }
        ];

        checks.forEach(check => {
            let found = false;
            if (check.html && check.html.test(html)) found = true;
            if (check.header && Object.values(headers).some(h => check.header.test(h))) found = true;
            if (check.header_key && headers[check.header_key.toLowerCase()]) found = true;

            if (found) {
                results.push({ name: check.name, category: check.cat });
            }
        });

        // Unique results
        return [...new Map(results.map(item => [item.name, item])).values()];

    } catch (error) {
        throw new Error(`Analysis failed: ${error.message}`);
    }
}

module.exports = { analyzeTech };

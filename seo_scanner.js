const axios = require('axios');
const cheerio = require('cheerio');
const chalk = require('chalk');

async function analyzeSEO(domain) {
    const url = `https://${domain}`;
    
    try {
        const response = await axios.get(url, {
            headers: { 'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36' },
            timeout: 10000,
            validateStatus: false
        });

        const $ = cheerio.load(response.data);
        const results = {
            title: $('title').text().trim(),
            description: $('meta[name="description"]').attr('content') || '',
            canonical: $('link[rel="canonical"]').attr('href') || '',
            h1: $('h1').map((i, el) => $(el).text().trim()).get(),
            ogTitle: $('meta[property="og:title"]').attr('content') || '',
            ogImage: $('meta[property="og:image"]').attr('content') || '',
            viewport: $('meta[name="viewport"]').attr('content') || '',
            robots: $('meta[name="robots"]').attr('content') || 'index, follow'
        };

        const insights = [];

        // Analysis & Insights
        if (!results.title) insights.push(chalk.red('Critical: Missing <title> tag.'));
        else if (results.title.length < 30) insights.push(chalk.yellow('Warning: Title is very short. Aim for 50-60 characters.'));
        else if (results.title.length > 70) insights.push(chalk.yellow('Warning: Title is too long. It will be truncated in search results.'));

        if (!results.description) insights.push(chalk.red('Critical: Missing meta description.'));
        else if (results.description.length < 50) insights.push(chalk.yellow('Warning: Description is very short.'));
        else if (results.description.length > 160) insights.push(chalk.yellow('Warning: Description is too long.'));

        if (results.h1.length === 0) insights.push(chalk.red('Critical: Missing <h1> tag. Every page needs exactly one.'));
        if (results.h1.length > 1) insights.push(chalk.yellow(`Warning: Found ${results.h1.length} <h1> tags. Consider using only one.`));

        if (!results.viewport) insights.push(chalk.red('Critical: No viewport meta tag. Site might not be mobile-friendly.'));
        if (!results.canonical) insights.push(chalk.yellow('Suggestion: Add a canonical tag to prevent duplicate content issues.'));

        return { data: results, insights };

    } catch (error) {
        throw new Error(`SEO Analysis failed: ${error.message}`);
    }
}

module.exports = { analyzeSEO };

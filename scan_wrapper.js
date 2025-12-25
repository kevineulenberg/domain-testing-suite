const { analyzeTech } = require('./tech_scanner');
const { analyzeSEO } = require('./seo_scanner');
const { analyzeCarbon, analyzeA11y, analyzeLinks } = require('./advanced_scanner');
const { runWPSecurityScan } = require('./wp_security_scanner');
const chalk = require('chalk');
const figlet = require('figlet');
const ora = require('ora');

const domain = process.argv[2];
const mode = process.argv[3];

if (!domain) {
    console.error(chalk.red('Error: No domain provided'));
    process.exit(1);
}

// Banner mode
if (mode === '--banner') {
    console.log(chalk.cyan(figlet.textSync('DOM - TEST', { horizontalLayout: 'full' })));
    console.log(chalk.dim('      Avant-Garde Domain Testing Suite'));
    console.log(chalk.dim('      --------------------------------'));
    process.exit(0);
}

async function runSEO() {
    const spinner = ora(`Analyzing SEO for ${chalk.bold(domain)}...`).start();
    try {
        const { data, insights } = await analyzeSEO(domain);
        spinner.succeed(chalk.green('SEO Analysis Complete'));

        console.log(`  ${chalk.cyan.bold('Title:')} ${data.title || chalk.dim('None')}`);
        console.log(`  ${chalk.cyan.bold('Desc:')} ${data.description || chalk.dim('None')}`);
        console.log(`  ${chalk.cyan.bold('H1:')} ${data.h1[0] || chalk.dim('None')}`);
        console.log(`  ${chalk.cyan.bold('Robots:')} ${data.robots}`);

        if (insights.length > 0) {
            console.log(`\n  ${chalk.yellow.bold('Insights:')}`);
            insights.forEach(msg => console.log(`    ${chalk.dim('➜')} ${msg}`));
        }
    } catch (error) {
        spinner.fail(chalk.red('SEO Analysis Failed'));
        console.error(chalk.red(`  ${error.message}`));
    }
}

async function runCarbon() {
    const spinner = ora(`Calculating Digital Carbon Footprint for ${chalk.bold(domain)}...`).start();
    try {
        const result = await analyzeCarbon(domain);
        spinner.succeed(chalk.green('Eco-Impact Analysis Complete'));

        console.log(`  ${chalk.cyan.bold('Page Weight:')} ${result.bytes}`);
        console.log(`  ${chalk.cyan.bold('CO2 per Visit:')} ${result.co2}`);
        console.log(`  ${chalk.cyan.bold('Eco Grade:')} ${result.grade}`);
        console.log(`  ${chalk.cyan.bold('Resources:')} ${result.resources} (Images/Scripts/CSS)`);
    } catch (error) {
        spinner.fail(chalk.red('Carbon Analysis Failed'));
        console.error(chalk.red(`  ${error.message}`));
    }
}

async function runA11y() {
    const spinner = ora(`Running Forensic Accessibility Audit for ${chalk.bold(domain)}...`).start();
    try {
        const result = await analyzeA11y(domain);
        spinner.succeed(chalk.green('Accessibility Audit Complete'));

        console.log(`  ${chalk.cyan.bold('A11y Score:')} ${result.score}/100`);
        
        if (result.issues.length > 0) {
             console.log(`\n  ${chalk.yellow.bold('Findings:')}`);
             result.issues.forEach(issue => console.log(`    ${chalk.dim('➜')} ${issue}`));
        }
    } catch (error) {
        spinner.fail(chalk.red('Audit Failed'));
        console.error(chalk.red(`  ${error.message}`));
    }
}

async function runLinks() {
    const spinner = ora(`Crawling for Broken Links on ${chalk.bold(domain)}...`).start();
    try {
        const result = await analyzeLinks(domain);
        spinner.succeed(chalk.green('Link Health Check Complete'));

        console.log(`  ${chalk.cyan.bold('Links Scanned:')} ${result.checked}`);
        
        if (result.broken.length === 0) {
            console.log(chalk.green('  ✨ No broken links detected in sample.'));
        } else {
            console.log(chalk.red(`  💥 Found ${result.broken.length} broken link(s):`));
            result.broken.forEach(item => {
                console.log(`    ${chalk.dim('➜')} ${item.status} - ${item.url}`);
            });
        }
    } catch (error) {
        spinner.fail(chalk.red('Link Scan Failed'));
        console.error(chalk.red(`  ${error.message}`));
    }
}

async function runTech() {
    const spinner = ora(`Scanning technology stack for ${chalk.bold(domain)}...`).start();

    try {
        const results = await analyzeTech(domain);
        spinner.succeed(chalk.green('Technology Analysis Complete'));

        if (results.length === 0) {
            console.log(chalk.yellow('  No specific technologies detected.'));
        } else {
            // Group by category
            const categories = {};
            results.forEach(item => {
                if (!categories[item.category]) categories[item.category] = [];
                categories[item.category].push(item.name);
            });

            Object.keys(categories).forEach(cat => {
                console.log(`  ${chalk.cyan.bold(cat)}: ${categories[cat].join(', ')}`);
            });
        }
    } catch (error) {
        spinner.fail(chalk.red('Analysis Failed'));
        console.error(chalk.red(`  ${error.message}`));
    }
}

switch (mode) {
    case 'seo': runSEO(); break;
    case 'carbon': runCarbon(); break;
    case 'a11y': runA11y(); break;
    case 'links': runLinks(); break;
    case 'wp-scan': runWPSecurityScan(domain); break;
    case 'tech': 
    default: runTech(); break;
}

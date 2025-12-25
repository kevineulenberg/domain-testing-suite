const { analyzeTech } = require('./tech_scanner');
const { analyzeSEO } = require('./seo_scanner');
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

if (mode === 'seo') {
    runSEO();
} else {
    runTech();
}

const { analyzeTech } = require('./tech_scanner');
const chalk = require('chalk');
const figlet = require('figlet');
const ora = require('ora');

const domain = process.argv[2];

if (!domain) {
    console.error(chalk.red('Error: No domain provided'));
    process.exit(1);
}

// Function to display the banner
if (process.argv[3] === '--banner') {
    console.log(chalk.cyan(figlet.textSync('DOM - TEST', { horizontalLayout: 'full' })));
    console.log(chalk.dim('      Avant-Garde Domain Testing Suite'));
    console.log(chalk.dim('      --------------------------------'));
    process.exit(0);
}

async function run() {
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

run();

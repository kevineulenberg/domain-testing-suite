const { spawn } = require('child_process');
const path = require('path');
const chalk = require('chalk');
const ora = require('ora');

async function runWPSecurityScan(domain) {
    return new Promise((resolve, reject) => {
        const scriptDir = path.join(__dirname, 'tools', 'wp_scanner');
        const venvPython = path.join(scriptDir, 'venv', 'bin', 'python');
        const scannerScript = path.join(scriptDir, 'wp_scanner.py');
        const targetUrl = `https://${domain}`;

        console.log(chalk.cyan.bold('\n--- 🛡️ WordPress Security Intelligence ---'));
        console.log(chalk.dim(`Target: ${targetUrl}`));
        console.log(chalk.dim('Initializing specialized forensic unit...'));

        const spinner = ora('Engaging WP-Scanner protocols...').start();

        // Run the Python script from the venv
        const child = spawn(venvPython, [scannerScript, '-t', targetUrl, '--report-format', 'console'], {
            cwd: scriptDir, // Run in the tool's dir to ensure it finds its own files
            env: process.env
        });

        let outputBuffer = '';

        child.stdout.on('data', (data) => {
            const text = data.toString();
            outputBuffer += text;
            
            // Simple parsing to update spinner or log specific lines
            // We want to filter out raw debug noise but keep the good stuff
            
            if (text.includes('[+]')) {
                if (spinner.isSpinning) spinner.stop();
                process.stdout.write(chalk.green(text.replace('[+]', '✨')));
            } else if (text.includes('[-]')) {
                if (spinner.isSpinning) spinner.stop();
                process.stdout.write(chalk.red(text.replace('[-]', '💥')));
            } else if (text.includes('[!]')) {
                if (spinner.isSpinning) spinner.stop();
                process.stdout.write(chalk.yellow(text.replace('[!]', '⚠️')));
            } else if (text.includes('[*]')) {
                 if (!spinner.isSpinning) {
                    // Just log info lines cleanly
                    process.stdout.write(chalk.cyan(text.replace('[*]', 'ℹ️')));
                 } else {
                     spinner.text = text.replace('[*]', '').trim();
                 }
            } else {
                // Raw output for everything else
                 if (!spinner.isSpinning) process.stdout.write(chalk.dim(text));
            }
        });

        child.stderr.on('data', (data) => {
            // Python often prints progress bars to stderr
            // We ignore it mostly unless it's a real error
            const errText = data.toString();
            if (errText.toLowerCase().includes('error')) {
                if (spinner.isSpinning) spinner.fail();
                console.error(chalk.red(`\n[System Error] ${errText}`));
            }
        });

        child.on('close', (code) => {
            if (spinner.isSpinning) spinner.succeed('Scan operations completed.');
            
            if (code === 0) {
                console.log(chalk.green.bold('\n[SUCCESS] Vulnerability assessment finished.'));
                resolve();
            } else {
                console.log(chalk.yellow(`\n[INFO] Process exited with code ${code}. Check logs above.`));
                resolve(); // Resolve anyway to not break the chain
            }
        });

        child.on('error', (err) => {
            if (spinner.isSpinning) spinner.fail();
            console.error(chalk.red(`Failed to launch WP-Scanner: ${err.message}`));
            reject(err);
        });
    });
}

module.exports = { runWPSecurityScan };

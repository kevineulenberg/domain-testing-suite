const express = require('express');
const { spawn } = require('child_process');
const path = require('path');
const { analyzeTech } = require('./tech_scanner');
const app = express();
const port = 4567;

app.use(express.static(path.join(__dirname, 'public')));

app.get('/api/run', (req, res) => {
    const { domain, type } = req.query;
    if (!domain) return res.status(400).send('Domain is required');

    res.setHeader('Content-Type', 'text/plain; charset=utf-8');
    res.setHeader('Transfer-Encoding', 'chunked');

    // Handle Tech Detection separately via our new engine
    if (type === 'cms') {
        return runEliteDetection(domain, res);
    }

    const scriptPath = path.join(__dirname, 'domain_tester.sh');
    const child = spawn('bash', [scriptPath, domain, type || 'full']);

    child.stdout.on('data', (data) => {
        const cleanData = data.toString()
            .replace(/\x1B\]8;;.*?\x1B\\/g, '')
            .replace(/\x1B\]8;;\x1B\\/g, '')
            .replace(/\x1B\[[0-9;]*[mK]/g, '');
        res.write(cleanData);
    });

    child.stderr.on('data', (data) => {
        res.write(`ERROR: ${data}`);
    });

    child.on('close', (code) => {
        res.end(`\n[Process completed with code ${code}]`);
    });
});

async function runEliteDetection(domain, res) {
    res.write(`--- Elite Tech Detection Engine ---\n`);
    res.write(`Target: ${domain}\n\n`);
    res.write(`[INIT] Scanning target application layer...\n`);

    try {
        const results = await analyzeTech(domain);
        
        if (results.length > 0) {
            results.forEach(tech => {
                res.write(`[DETECTED] ${tech.name.padEnd(20)} | Category: ${tech.category}\n`);
            });
        } else {
            res.write(`[INFO] No common technologies detected. Target might be obfuscated or uses custom stack.\n`);
        }
    } catch (error) {
        res.write(`[ERROR] Detection failed: ${error.message}\n`);
    } finally {
        res.end(`\n[Process completed]`);
    }
}

app.listen(port, () => {
    console.log(`Domain Suite running at http://localhost:${port}`);
});


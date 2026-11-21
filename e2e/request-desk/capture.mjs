import { writeFile } from 'node:fs/promises';
import { resolve } from 'node:path';
import { chromium } from 'playwright-core';
import { startDesk } from './app.mjs';

const [modulePath, output, variant = 'healthy'] = process.argv.slice(2);
if (!modulePath || !output) {
  throw new Error('usage: node capture.mjs COMPILED.mjs TRACE.jsonl [early-ui]');
}
const desk = await startDesk(resolve(modulePath), variant);
let browser;
try {
  browser = await chromium.launch({
    executablePath: process.env.CHROMIUM_BIN || '/usr/bin/chromium',
  });
  const page = await browser.newPage();
  page.setDefaultTimeout(5000);
  await page.goto(desk.origin);
  const status = page.getByRole('status');
  const observe = async () => ({ phase: await status.innerText() });
  const rows = [{ observe: await observe() }];
  for (const [index, command] of ['Respond', 'Submit', 'Retry', 'Respond'].entries()) {
    await page.getByRole('button', { name: command, exact: true }).click();
    // This only waits for the request/render cycle, not any expected phase.
    await page.locator(`#commands[data-completed="${index + 1}"]`).waitFor();
    rows.push({ signal: `RequestDesk::${command}`, observe: await observe() });
  }
  await writeFile(output, rows.map(row => JSON.stringify(row)).join('\n') + '\n');
} finally {
  try { await browser?.close(); } finally { await desk.close(); }
}

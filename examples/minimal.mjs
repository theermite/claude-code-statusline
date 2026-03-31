#!/usr/bin/env node

// Minimal Claude Code statusline — just model + context usage
// Good starting point for customization

import { createInterface } from 'readline';

const rl = createInterface({ input: process.stdin });
let data = '';

rl.on('line', (line) => { data += line; });
rl.on('close', () => {
  try {
    const json = JSON.parse(data);
    const model = json?.model?.display_name?.replace(' (1M context)', '') || '?';
    const pct = Math.round(json?.context_window?.used_percentage || 0);
    const cost = json?.cost?.total_cost_usd;

    const bar = '█'.repeat(Math.floor(pct / 5)) + '░'.repeat(20 - Math.floor(pct / 5));
    const costStr = cost ? ` | ~$${cost.toFixed(2)}` : '';

    process.stdout.write(`[${model}] [${bar}] ${pct}%${costStr}`);
  } catch {
    process.stdout.write('[?] -');
  }
});

setTimeout(() => {
  if (!data) { process.stdout.write('[?] -'); process.exit(0); }
}, 2000);

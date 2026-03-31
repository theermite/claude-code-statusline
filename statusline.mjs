#!/usr/bin/env node

// Claude Code Statusline — Node.js implementation
// Fixes broken stdin on Windows + Git Bash where bash `cat`/`read` receive empty pipes
// https://github.com/theermite/claude-code-statusline

import { createInterface } from 'readline';
import { readFileSync } from 'fs';

// ── ANSI Colors ──
const c = {
  reset: '\x1b[0m',
  dim: '\x1b[2m',
  bold: '\x1b[1m',
  cyan: '\x1b[36m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  red: '\x1b[31m',
  magenta: '\x1b[35m',
  blue: '\x1b[34m',
  white: '\x1b[37m',
  gray: '\x1b[90m',
};

function colorPct(pct, thresholds = [50, 80]) {
  if (pct > thresholds[1]) return c.red;
  if (pct > thresholds[0]) return c.yellow;
  return c.green;
}

function makeBar(pct, width = 20) {
  const filled = Math.floor(pct * width / 100);
  const color = colorPct(pct);
  return `${color}${'█'.repeat(filled)}${c.gray}${'░'.repeat(width - filled)}${c.reset}`;
}

function formatDuration(ms) {
  const mins = Math.floor(ms / 60000);
  if (mins >= 60) return `${Math.floor(mins / 60)}h${String(mins % 60).padStart(2, '0')}`;
  return `${mins}m`;
}

function formatTimeUntil(resetTimestamp) {
  const remainMs = (resetTimestamp * 1000) - Date.now();
  const remainMin = Math.max(0, Math.floor(remainMs / 60000));
  if (remainMin >= 1440) return `${Math.ceil(remainMin / 1440)}d`;
  if (remainMin >= 60) return `${Math.floor(remainMin / 60)}h${String(remainMin % 60).padStart(2, '0')}`;
  return `${remainMin}m`;
}

function getRecentActivity(transcriptPath) {
  if (!transcriptPath) return { tools: [], agents: [] };
  try {
    const content = readFileSync(transcriptPath, 'utf-8');
    const lines = content.trim().split('\n').slice(-50);
    const tools = [];
    const agents = new Set();
    const toolCounts = {};

    for (const line of lines) {
      try {
        const d = JSON.parse(line);
        if (d.type === 'assistant' && d.message?.content) {
          for (const block of d.message.content) {
            if (block.type === 'tool_use') {
              const name = block.name;
              toolCounts[name] = (toolCounts[name] || 0) + 1;
              if (name === 'Agent') {
                const desc = block.input?.description || block.input?.subagent_type || '';
                if (desc) agents.add(desc);
              }
              if (name === 'Skill') {
                const skill = block.input?.skill || '';
                if (skill) agents.add(`/${skill}`);
              }
            }
          }
        }
      } catch {}
    }

    // Top 4 tools by frequency
    const sorted = Object.entries(toolCounts)
      .filter(([name]) => name !== 'Agent' && name !== 'Skill')
      .sort((a, b) => b[1] - a[1])
      .slice(0, 4);
    for (const [name, count] of sorted) {
      tools.push(count > 1 ? `${name}x${count}` : name);
    }

    return { tools, agents: Array.from(agents).slice(0, 3) };
  } catch {
    return { tools: [], agents: [] };
  }
}

const rl = createInterface({ input: process.stdin });
let data = '';

rl.on('line', (line) => { data += line; });
rl.on('close', () => {
  try {
    const json = JSON.parse(data);

    // ── Line 1: Model + Git + Project + Duration + Lines ──
    const model = json?.model?.display_name?.replace(' (1M context)', '') || '?';
    const branch = json?.git?.branch || '';
    const dirty = json?.git?.dirty ? '*' : '';
    const cwd = json?.cwd || '';
    const project = cwd ? cwd.split(/[/\\]/).filter(Boolean).slice(-1)[0] : '';
    const durationMs = json?.cost?.total_duration_ms || 0;
    const linesAdded = json?.cost?.total_lines_added || 0;
    const linesRemoved = json?.cost?.total_lines_removed || 0;

    let line1 = `${c.cyan}${c.bold}[${model}]${c.reset}`;
    if (branch) line1 += ` ${c.magenta}${branch}${dirty}${c.reset}`;
    if (project) line1 += ` ${c.gray}@${c.reset} ${c.white}${project}${c.reset}`;
    if (durationMs > 0) line1 += ` ${c.gray}|${c.reset} ${c.dim}${formatDuration(durationMs)}${c.reset}`;
    if (linesAdded || linesRemoved) {
      line1 += ` ${c.gray}|${c.reset} ${c.green}+${linesAdded}${c.reset} ${c.red}-${linesRemoved}${c.reset}`;
    }

    // ── Line 2: Context bar + Cost ──
    const pct = Math.round(json?.context_window?.used_percentage || 0);
    const bar = makeBar(pct);
    const cost = json?.cost?.total_cost_usd;
    const costStr = cost ? ` ${c.gray}|${c.reset} ${c.dim}~$${cost.toFixed(2)}${c.reset}` : '';
    const line2 = `[${bar}] ${colorPct(pct)}${pct}%${c.reset}${costStr}`;

    // ── Line 3: Rate limits ──
    const limits = json?.rate_limits;
    let line3 = '';
    if (limits) {
      const parts = [];
      if (limits.five_hour) {
        const p = Math.round(limits.five_hour.used_percentage || 0);
        const timeLeft = formatTimeUntil(limits.five_hour.resets_at);
        parts.push(`${c.bold}5h:${c.reset} ${colorPct(p)}${p}%${c.reset} ${c.gray}(${timeLeft})${c.reset}`);
      }
      if (limits.seven_day) {
        const p = Math.round(limits.seven_day.used_percentage || 0);
        const timeLeft = formatTimeUntil(limits.seven_day.resets_at);
        parts.push(`${c.bold}7d:${c.reset} ${colorPct(p)}${p}%${c.reset} ${c.gray}(${timeLeft})${c.reset}`);
      }
      if (parts.length > 0) line3 = `\n${c.dim}Usage:${c.reset} ${parts.join(` ${c.gray}|${c.reset} `)}`;
    }

    // ── Line 4: Recent tools + agents ──
    const activity = getRecentActivity(json?.transcript_path);
    let line4 = '';
    const actParts = [];
    if (activity.tools.length > 0) {
      actParts.push(`${c.blue}${activity.tools.join(` ${c.gray}·${c.blue} `)}${c.reset}`);
    }
    if (activity.agents.length > 0) {
      actParts.push(`${c.magenta}${activity.agents.join(', ')}${c.reset}`);
    }
    if (actParts.length > 0) {
      line4 = `\n${c.dim}Activity:${c.reset} ${actParts.join(` ${c.gray}|${c.reset} `)}`;
    }

    process.stdout.write(`${line1}\n${line2}${line3}${line4}`);
  } catch (e) {
    process.stdout.write(`[?] [░░░░░░░░░░░░░░░░░░░░] -`);
  }
});

setTimeout(() => {
  if (!data) {
    process.stdout.write('[?] [░░░░░░░░░░░░░░░░░░░░] -');
    process.exit(0);
  }
}, 2000);

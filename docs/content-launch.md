# Content Launch — claude-code-statusline

> Copy-paste ready. One article for the blog (auto-syndicates), two Reddit posts.

---

## 1. Blog Article (The Ermite)

### Metadata

```
title: "Claude Code Statusline Doesn't Work on Windows? Here's Why and How to Fix It"
slug: claude-code-statusline-windows-fix
tags: claude-code, windows, developer-tools, open-source, ai-tools
description: "The Claude Code statusline silently fails on Windows + Git Bash. The culprit: bash can't read stdin pipes from non-bash parents. Here's the root cause analysis and a Node.js fix."
```

### Article

# Claude Code Statusline Doesn't Work on Windows? Here's Why and How to Fix It

Claude Code has a neat feature called `statusLine` — a customizable bar at the bottom of your terminal that shows session info (model, context usage, cost, git state). You configure it in `~/.claude/settings.json` and it pipes JSON data to your command via stdin.

On macOS and Linux, it works fine with a simple bash script. On Windows with Git Bash? **Silence. Nothing. Zero data.**

I spent a full debugging session on this, and the answer turned out to be surprisingly simple — but not obvious at all.

## The Symptoms

You configure a statusline command. Something like:

```json
{
  "statusLine": {
    "type": "command",
    "command": "cat | jq -r '.model.display_name'"
  }
}
```

On macOS: you see "Claude Opus 4.6 (1M context)".
On Windows + Git Bash: you see **nothing**.

You try `read`, `timeout cat`, piping through `wc -c` — stdin is consistently empty. Zero bytes. Yet `echo "hello"` as the statusline command works perfectly, proving the mechanism itself is functional.

## The Root Cause

Git Bash on Windows can't read stdin pipes from non-bash parent processes.

When Claude Code spawns your statusline command, it creates a child process and pipes JSON to its stdin at the OS level. This pipe is a Windows handle. Git Bash's builtins (`cat`, `read`) go through bash's I/O layer, which apparently can't bridge that gap — they see an empty stream.

This isn't a Claude Code bug. It's a Git Bash limitation with stdin pipes from non-bash parents.

## The Fix: Use Node.js

Node.js reads stdin via its native `readline` module, which interfaces directly with OS file descriptors. It sees the pipe just fine.

Here's a minimal version:

```javascript
#!/usr/bin/env node
import { createInterface } from 'readline';

const rl = createInterface({ input: process.stdin });
let data = '';

rl.on('line', (line) => { data += line; });
rl.on('close', () => {
  try {
    const json = JSON.parse(data);
    const model = json?.model?.display_name || '?';
    const pct = Math.round(json?.context_window?.used_percentage || 0);
    const bar = '█'.repeat(Math.floor(pct / 5)) + '░'.repeat(20 - Math.floor(pct / 5));
    process.stdout.write(`[${model}] [${bar}] ${pct}%`);
  } catch {
    process.stdout.write('[?] -');
  }
});
```

Save this as `~/.claude/statusline.mjs` and configure:

```json
{
  "statusLine": {
    "type": "command",
    "command": "node /c/Users/YOUR_USERNAME/.claude/statusline.mjs"
  }
}
```

That's it. It works on Windows, macOS, and Linux. Zero dependencies.

## The Full Version

I published a richer statusline that shows 4 lines of data:

```
[Claude Opus 4.6] main* @ my-project | 42m | +127 -34
[████████████░░░░░░░░] 58% | ~$1.24
Usage: 5h: 23% (3h12) | 7d: 8% (5d)
Activity: Edit · Grep · Read x3 | explore-codebase
```

It includes:
- Model name, git branch with dirty indicator, project name
- Context window usage with color-coded progress bar
- Rate limit tracking (5-hour and 7-day) with time until reset
- Recent tool activity parsed from the session transcript

**Repo: [theermite/claude-code-statusline](https://github.com/theermite/claude-code-statusline)**

Single file, MIT licensed. Fork it, customize it, make it yours.

## How This Was Built

This was built using AI-assisted development — Claude Code itself helped write the implementation. But the AI didn't find the bug. The debugging methodology did: logs first, systematic escalation, environment isolation.

The human work was identifying the root cause (Git Bash stdin pipe limitation), designing the approach (Node.js readline), and validating across environments. The AI accelerated the implementation.

AI is the tool. Methodology is the craft.

---

## 2. Reddit Post — r/ClaudeAI

### Title

I fixed the broken statusline on Windows — here's why bash can't read stdin and the Node.js workaround

### Body

If you're on Windows + Git Bash and the Claude Code `statusLine` feature gives you nothing — you're not alone. I burned a debugging session on this.

**TL;DR**: Git Bash's `cat`/`read` can't read stdin pipes from non-bash parent processes. Node.js `readline` can. Use a `.mjs` script instead of bash.

**The root cause**: When Claude Code spawns your statusline command, it pipes JSON via a Windows handle. Git Bash builtins go through bash's I/O layer and see an empty stream. Node.js reads OS file descriptors directly — works fine.

I published a full statusline script (model, context bar, cost, rate limits, recent tools) as a single .mjs file:

**https://github.com/theermite/claude-code-statusline**

Zero dependencies, works on Windows/macOS/Linux. MIT licensed.

Install in 2 minutes:
1. Copy `statusline.mjs` to `~/.claude/`
2. Add to `settings.json`:
```json
{
  "statusLine": {
    "type": "command",
    "command": "node /c/Users/YOU/.claude/statusline.mjs"
  }
}
```
3. Restart Claude Code

Happy to answer questions if anyone has a similar setup.

---

## 3. Reddit Post — r/ClaudeDev

### Title

Open-source statusline for Claude Code — context usage, rate limits, cost, git state (+ Windows stdin fix)

### Body

I made a rich statusline for Claude Code that shows everything I want to see at a glance:

```
[Claude Opus 4.6] main* @ my-project | 42m | +127 -34
[████████████░░░░░░░░] 58% | ~$1.24
Usage: 5h: 23% (3h12) | 7d: 8% (5d)
Activity: Edit · Grep · Read x3 | explore-codebase
```

**What it shows:**
- Current model + git branch (with dirty flag)
- Context window usage bar (color-coded green/yellow/red)
- Session cost in USD
- Rate limit usage (5h + 7d) with countdown to reset
- Recent tool calls parsed from the transcript

**Bonus**: If you're on Windows + Git Bash and statusline gives you nothing — that's because bash `cat`/`read` can't read stdin pipes from non-bash parents. This script uses Node.js `readline` which handles it correctly.

Single file, zero dependencies, MIT: **https://github.com/theermite/claude-code-statusline**

The `examples/minimal.mjs` has a stripped-down version if you want a starting point for your own.

---

## 4. Optional — GitHub Issue on anthropics/claude-code

### Title

statusLine stdin is empty on Windows + Git Bash (bash builtins can't read the pipe)

### Body

**Environment**: Windows 11 + Git Bash, Claude Code latest

**Behavior**: When using a bash-based `statusLine` command, `cat`, `read`, and `timeout cat` all receive empty stdin (0 bytes). `echo "static"` works, confirming the statusLine mechanism is functional.

**Root cause**: Git Bash builtins can't read stdin pipes from non-bash parent processes. The Windows pipe handle is valid but bash's I/O layer doesn't bridge it.

**Workaround**: Use Node.js `readline` instead of bash. Published a working implementation: https://github.com/theermite/claude-code-statusline

This may affect other Windows users and any bash-based statusLine plugins (e.g. claude-hud).

Not a critical bug — just documenting for discoverability.

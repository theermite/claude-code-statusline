# claude-code-statusline

A rich, multi-line statusline for [Claude Code](https://docs.anthropic.com/en/docs/claude-code) that actually works on Windows.

```
[Claude Opus 4.6] main* @ my-project | 42m | +127 -34
[████████████░░░░░░░░] 58% | ~$1.24
Usage: 5h: 23% (3h12) | 7d: 8% (5d)
Activity: Edit · Grep · Read x3 | explore-codebase
```

## The Problem

Claude Code's `statusLine` feature pipes JSON session data to a command via stdin. On **Windows + Git Bash**, bash builtins (`cat`, `read`, `timeout cat`) receive **empty stdin** — the pipe silently fails. This means:

- Bash-based statusline scripts get zero data
- The [`claude-hud`](https://github.com/jarrodwatts/claude-hud) plugin breaks for the same reason
- `echo "static text"` works (proving the mechanism is functional), but anything reading stdin doesn't

## The Solution

Use **Node.js `readline`** instead of bash to read stdin. Node handles Windows pipes correctly where Git Bash doesn't.

Zero dependencies. Single file. Works on Windows, macOS, and Linux.

## What You Get

| Line | Content |
|------|---------|
| **1** | Model name, git branch (with dirty indicator), project name, session duration, lines changed |
| **2** | Context window usage bar with color thresholds (green/yellow/red) + session cost |
| **3** | Rate limit usage (5-hour and 7-day) with time until reset |
| **4** | Recent tool activity and active agents from the session transcript |

Colors adapt to usage levels:
- **Green** = under 50%
- **Yellow** = 50-80%
- **Red** = over 80%

## Installation

### 1. Copy the script

```bash
# Download to your Claude config directory
curl -o ~/.claude/statusline.mjs https://raw.githubusercontent.com/theermite/claude-code-statusline/main/statusline.mjs
```

Or manually copy `statusline.mjs` to `~/.claude/statusline.mjs`.

### 2. Configure Claude Code

Add this to your `~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "node ~/.claude/statusline.mjs"
  }
}
```

**Windows users** — use the full path with forward slashes:

```json
{
  "statusLine": {
    "type": "command",
    "command": "node /c/Users/YOUR_USERNAME/.claude/statusline.mjs"
  }
}
```

### 3. Restart Claude Code

The statusline appears automatically at the bottom of your terminal.

## Minimal Version

Want something simpler? `examples/minimal.mjs` is a stripped-down version with just model + context bar + cost:

```
[Claude Opus 4.6] [████████████░░░░░░░░] 58% | ~$1.24
```

## Available Data

Claude Code sends a JSON object on stdin with these fields:

| Field | Description |
|-------|-------------|
| `model.display_name` | Current model (e.g. "Claude Opus 4.6 (1M context)") |
| `context_window.used_percentage` | Context window usage (0-100) |
| `cost.total_cost_usd` | Session cost in USD |
| `cost.total_duration_ms` | Session duration |
| `cost.total_lines_added` / `total_lines_removed` | Lines changed |
| `git.branch` / `git.dirty` | Git state |
| `cwd` | Current working directory |
| `rate_limits.five_hour` / `seven_day` | Rate limit info with `used_percentage` and `resets_at` |
| `transcript_path` | Path to session transcript (JSONL) |

Use these fields to build your own custom statusline.

## Customization

The script is a single `.mjs` file — fork it, modify it, make it yours. Some ideas:

- Change the bar style (`█░` to `▓▒` or `●○`)
- Adjust color thresholds
- Add/remove lines
- Show different data from the transcript

## Why Node.js Instead of Bash?

On Windows, Claude Code spawns the statusline command through Git Bash. The stdin pipe from Claude Code to the child process works at the OS level, but Git Bash's `cat`, `read`, and other builtins can't access it — they see an empty stream.

Node.js reads the same pipe correctly via its native `readline` module because it interfaces directly with the OS file descriptors rather than going through bash's I/O layer.

This isn't a Claude Code bug — it's a Git Bash limitation with stdin pipes from non-bash parent processes.

## Requirements

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI
- [Node.js](https://nodejs.org/) 18+ (you already have it if you use Claude Code)

## How This Was Made

This tool was built using AI-assisted development (Claude Code) guided by a structured methodology: problem diagnosis through logs first, systematic debugging escalation, and verification-driven development.

The human contribution: identifying the root cause (Git Bash stdin pipe limitation), designing the solution architecture, and validating across environments. The AI contribution: implementation speed and code generation.

AI is the tool. Methodology is the craft.

## License

MIT - [The Ermite](https://github.com/theermite)

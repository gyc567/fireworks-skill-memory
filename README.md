<div align="center">

<img src="https://raw.githubusercontent.com/yizhiyanhua-ai/fireworks-skill-memory/main/docs/logo.svg" alt="fireworks-skill-memory" width="80" />

# fireworks-skill-memory

**Persistent experience memory for Claude Code skills.**

Claude remembers what it learned — session after session.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-compatible-8A2BE2)](https://claude.ai/code)
[![Python](https://img.shields.io/badge/Python-3.9%2B-3776AB?logo=python&logoColor=white)](https://python.org)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](https://github.com/yizhiyanhua-ai/fireworks-skill-memory/pulls)

[中文文档](README.zh-CN.md) · [Report Bug](https://github.com/yizhiyanhua-ai/fireworks-skill-memory/issues) · [Request Feature](https://github.com/yizhiyanhua-ai/fireworks-skill-memory/issues)

</div>

---

## The Problem

Every Claude Code session starts from zero. The same mistakes repeat — wrong API parameters, broken sequences, proxy pitfalls — because Claude has no memory between sessions.

```
Session 1:  "Don't forget — use index=0 for Feishu blocks"   ✓ works
Session 2:  same mistake again                                ✗ forgot
Session 3:  same mistake again                                ✗ forgot
```

## The Solution

`fireworks-skill-memory` gives Claude a persistent, skill-scoped memory that grows smarter with every session.

```
Session 1:  mistake happens → lesson saved automatically
Session 2:  lesson injected before Claude responds            ✓ no repeat
Session 3:  lesson still there, more lessons added            ✓ keeps improving
```

**Install in Claude Code — just say:**

> *"Help me install fireworks-skill-memory"*

Or run directly:

```bash
curl -fsSL https://raw.githubusercontent.com/yizhiyanhua-ai/fireworks-skill-memory/main/install.sh | bash
```

Then type `/hooks` in Claude Code to activate.

---

## How It Works

```
┌─────────────────────────────────────────────────────────────────┐
│                      Claude Code Session                        │
│                                                                 │
│   User invokes a skill                                          │
│         │                                                       │
│         ▼                                                       │
│   Claude reads SKILL.md  ──► PostToolUse Hook fires            │
│                                      │                         │
│                                      ▼                         │
│                              inject-skill-knowledge.py          │
│                                      │                         │
│                                      ▼                         │
│                         Reads KNOWLEDGE.md (< 5ms)             │
│                                      │                         │
│                                      ▼                         │
│                    ┌─────────────────────────────┐             │
│                    │  additionalContext injected  │             │
│                    │  Claude sees past lessons    │             │
│                    │  before writing one word     │             │
│                    └─────────────────────────────┘             │
│                                                                 │
│   Session ends                                                  │
│         │                                                       │
│         ▼                                                       │
│   Stop Hook fires (async, non-blocking)                        │
│         │                                                       │
│         ▼                                                       │
│   update-skills-knowledge.py                                    │
│         │                                                       │
│         ├── reads last 300 lines of JSONL transcript           │
│         ├── detects which skills were used                      │
│         ├── calls haiku → extracts 1-3 new lessons             │
│         ├── deduplicates → appends to KNOWLEDGE.md             │
│         └── checks for cross-skill patterns → global file      │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Knowledge Structure

```
~/.claude/
├── skills-knowledge.md        ← global principles (≤ 20 entries)
│     "Always test proxy connectivity before external calls"
│     "Batch operations: always go top → bottom, not reversed"
│
└── skills/
    ├── browser-use/
    │   └── KNOWLEDGE.md       ← skill-specific lessons (≤ 30 entries)
    │         "Run state before every click — indices change after interaction"
    │         "Use --profile for sites with saved logins"
    │
    ├── find-skills/
    │   └── KNOWLEDGE.md
    │
    └── {any-skill}/
        └── KNOWLEDGE.md       ← auto-created on first lesson
```

**Two-layer design:**
- **Global** — principles that help across all skills
- **Per-skill** — precise, actionable lessons for that specific skill only

Injection is scoped: only the relevant skill's knowledge loads, keeping context clean.

---

## Installation

### Recommended: Ask Claude

Open Claude Code and say:

> **"Help me install fireworks-skill-memory from GitHub"**

Claude will handle everything.

### One-line install

```bash
curl -fsSL https://raw.githubusercontent.com/yizhiyanhua-ai/fireworks-skill-memory/main/install.sh | bash
```

The installer:
1. ✅ Checks Python 3.9+ and Claude Code
2. ✅ Downloads hook scripts to `~/.claude/scripts/`
3. ✅ Merges hooks into `~/.claude/settings.json` — existing config untouched
4. ✅ Optionally seeds starter knowledge for official skills

Then type `/hooks` in Claude Code to activate.

---

## What Gets Remembered

Example knowledge entries that build up over time:

```markdown
# browser-use — experience

- [state before acting] Always run `browser-use state` before clicking —
  indices change after every page interaction. Never reuse a stale index.
- [daemon lifecycle] Run `browser-use close` when done. The daemon stays
  open and holds resources until explicitly closed.
- [auth via profile] Use --profile "Default" to access sites where you're
  already logged in. Headless Chromium has no saved cookies.
```

```markdown
# find-skills — experience

- [install path] Skills install to ~/.claude/skills/ by default.
  Check there first before assuming a skill is missing.
- [network errors] find-skills calls skillsmp.com — on restricted networks
  it fails silently. Test connectivity before blaming the skill.
```

---

## Included Starter Knowledge

Ready-made lesson files for Claude Code's official skills — included out of the box:

| Skill | What's pre-loaded |
|-------|-------------------|
| `find-skills` | CLI commands, install paths, network error patterns |
| `skills-updater` | Two update sources, version tracking, locale detection |
| `voice` | agent-voice setup, auth flow, ask vs say semantics |
| `browser-use` | state-before-act, daemon lifecycle, profile auth |
| `skill-adoption-planner` | Fast-path inputs, resistance diagnosis |
| `skill-knowledge-extractor` | No-script mode, pattern types |
| `skill-roi-calculator` | Minimum data, comparison mode |
| `hookify` | Rule format, regex field, naming conventions |
| `superpowers` | Mandatory invocation, user-instruction priority |

---

## Privacy & Security

| What | Detail |
|------|--------|
| 📍 Data location | Everything stays on your machine — no cloud, no uploads |
| 📄 Transcript access | Reads only JSONL files Claude Code already stores locally |
| 🔑 Secrets | Distillation prompt explicitly excludes credentials and personal data |
| 🤖 API calls | Runs through your existing Claude Code auth — no third-party endpoints |

See [SECURITY.md](SECURITY.md) for the full security policy.

---

## Configuration

All optional. Set in `~/.claude/settings.json` under `"env"`:

| Variable | Default | Description |
|----------|---------|-------------|
| `SKILLS_KNOWLEDGE_MODEL` | `claude-haiku-4-5` | Model used for distillation |
| `SKILL_MAX` | `30` | Max entries per skill file |
| `GLOBAL_MAX` | `20` | Max entries in global file |
| `TRANSCRIPT_LINES` | `300` | Lines of transcript to analyse |
| `SKILLS_KNOWLEDGE_DIR` | `~/.claude/skills` | Root of skill directories |

---

## Contributing

Contributions of new starter `KNOWLEDGE.md` files for popular skills are especially welcome.

1. Fork and branch: `git checkout -b feat/skill-name-knowledge`
2. Add your file to `examples/skill-knowledge/`
3. Open a PR with a short description of what lessons are included

---

## License

MIT © 2026 [yizhiyanhua-ai](https://github.com/yizhiyanhua-ai)

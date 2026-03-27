# Security Policy

## Supported Versions

| Version | Supported |
|---------|-----------|
| latest (`main`) | ✅ |

## Data handling

`fireworks-skill-memory` is designed to keep all data local:

| Component | Network access | What it reads |
|-----------|---------------|---------------|
| `inject-skill-knowledge.py` | **None** | `KNOWLEDGE.md` files on disk |
| `update-skills-knowledge.py` | Local Claude CLI only | Session JSONL transcripts stored by Claude Code |

The distillation step calls `claude -p <prompt>` which uses your existing Claude Code
authentication. **No raw transcript content is sent to any third-party endpoint.**

## What the scripts do NOT do

- Extract, log, or transmit API keys, tokens, passwords, or personal data
- Read files outside `~/.claude/` (transcripts) and `~/.claude/skills/` (knowledge files)
- Write anywhere other than `~/.claude/skills/*/KNOWLEDGE.md` and
  `~/.claude/skills-knowledge.md`

## Reporting a vulnerability

Please open a [GitHub Issue](https://github.com/ccc7574/fireworks-skill-memory/issues)
marked **[SECURITY]**. For sensitive disclosures, use GitHub's private vulnerability
reporting feature.

We aim to respond within **72 hours** and release a patch within **7 days** for
confirmed issues.

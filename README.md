# fireworks-skill-memory

> **Persistent, per-skill experience memory for Claude Code.**
> Every Claude Code session that uses a skill automatically distils hard-won lessons into a lightweight knowledge file. The next time that skill loads, Claude already knows the gotchas.

[中文文档](README.zh-CN.md)

---

## The problem

When you use a Claude Code skill repeatedly, the same mistakes happen session after session — wrong API parameter names, broken upload sequences, network proxy pitfalls — because Claude has no memory between sessions.

## The solution

`fireworks-skill-memory` wires two small hooks into Claude Code:

| Hook | Trigger | What it does |
|------|---------|-------------|
| **Injector** | Reading any `SKILL.md` | Prepends the skill's `KNOWLEDGE.md` into Claude's context (<5 ms, pure file I/O) |
| **Updater** | Session ends (`Stop`) | Async: calls a lightweight model to distil new lessons from the transcript and appends them to the right `KNOWLEDGE.md` |

### Knowledge structure

```
~/.claude/
├── skills-knowledge.md          ← global cross-skill principles   (≤ 20 entries)
└── skills/
    ├── baoyu-translate/
    │   └── KNOWLEDGE.md         ← translate-specific experience   (≤ 30 entries)
    ├── claude-to-im/
    │   └── KNOWLEDGE.md         ← Feishu API hard-won lessons
    └── {any-skill}/
        └── KNOWLEDGE.md         ← auto-created on first lesson
```

**Global file** — principles that apply across many skills (proxy handling, batch-operation order, API error taxonomy…).
**Per-skill files** — concrete, actionable bullet points: exact API field names, correct parameter order, known error codes and their fixes.

---

## Installation

### Prerequisites

- [Claude Code](https://claude.ai/code) installed and in `$PATH`
- Python 3.9+

### Steps

**1. Clone the repo**

```bash
git clone https://github.com/ccc7574/fireworks-skill-memory.git
cd fireworks-skill-memory
```

**2. Copy the scripts**

```bash
mkdir -p ~/.claude/scripts
cp scripts/inject-skill-knowledge.py ~/.claude/scripts/
cp scripts/update-skills-knowledge.py ~/.claude/scripts/
```

**3. Register the hooks**

Open `~/.claude/settings.json` and merge in the snippet from `examples/settings-hooks.json`:

```json
{
  "hooks": {
    "Stop": [{
      "hooks": [{
        "type": "command",
        "command": "python3 ~/.claude/scripts/update-skills-knowledge.py",
        "async": true
      }]
    }],
    "PostToolUse": [{
      "matcher": "Read",
      "hooks": [{
        "type": "command",
        "command": "python3 ~/.claude/scripts/inject-skill-knowledge.py",
        "if": "Read(**/.claude/skills/*/SKILL.md)"
      }]
    }]
  }
}
```

**4. Reload hooks**

Type `/hooks` in Claude Code to reload the configuration without restarting.

**5. (Optional) Seed initial knowledge**

Copy or write a `KNOWLEDGE.md` into any skill directory:

```bash
cp examples/skill-knowledge/baoyu-translate.md \
   ~/.claude/skills/baoyu-translate/KNOWLEDGE.md
```

---

## Configuration

All settings are optional environment variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `SKILLS_KNOWLEDGE_DIR` | `~/.claude/skills` | Root of skill directories |
| `SKILLS_KNOWLEDGE_GLOBAL` | `~/.claude/skills-knowledge.md` | Global principles file |
| `SKILLS_KNOWLEDGE_MODEL` | `claude-haiku-4-5` | Model used for distillation |
| `GLOBAL_MAX` | `20` | Max entries in the global file |
| `SKILL_MAX` | `30` | Max entries per skill file |
| `TRANSCRIPT_LINES` | `300` | Lines of transcript to analyse |

Set them in `~/.claude/settings.json` under `"env"`:

```json
{
  "env": {
    "SKILLS_KNOWLEDGE_MODEL": "claude-haiku-4-5",
    "SKILL_MAX": "25"
  }
}
```

---

## How it works

### Injection (zero-latency, every time)

```
User invokes a skill
  └─ Claude reads ~/.claude/skills/{name}/SKILL.md
       └─ PostToolUse hook fires inject-skill-knowledge.py
            └─ Script reads {name}/KNOWLEDGE.md (if it exists)
                 └─ Returns additionalContext → Claude sees past lessons
                      before writing a single line of output
```

### Distillation (async, after each session)

```
Session ends
  └─ Stop hook fires update-skills-knowledge.py (async, non-blocking)
       ├─ Reads last 300 lines of the session transcript
       ├─ Detects which skills were invoked (Skill tool + SKILL.md reads)
       ├─ For each skill: calls haiku to extract 1-3 new lessons
       │    └─ Deduplicates against existing entries → appends to KNOWLEDGE.md
       └─ Checks for cross-skill global principles → updates skills-knowledge.md
```

### Capacity management

When a knowledge file exceeds its limit (`SKILL_MAX` / `GLOBAL_MAX`), the oldest entries are dropped automatically, keeping the file focused and relevant.

---

## Example knowledge entries

```markdown
# baoyu-translate — experience

## Entries

- [Image extraction] PDF figures must be extracted separately (pdfimages / pdf2image);
  the skill does not handle images — they must be inserted manually after translation.
- [Feishu write order] Always insert blocks forward (top → bottom); using index=0 to
  prepend batches reverses the paragraph order.
- [refined params] `--mode refined --to zh-CN --audience technical --style academic`
  is the recommended combination for technical papers.
```

---

## Included example knowledge files

The `examples/skill-knowledge/` directory contains starter knowledge files for popular skills:

| File | Covers |
|------|--------|
| `claude-to-im.md` | Feishu Docx API: block types, image upload flow, index param, error codes |
| `baoyu-translate.md` | PDF handling, Feishu write order, mode selection |
| `baoyu-youtube-transcript.md` | yt-dlp proxy, cookie strategy, anti-bot workarounds |
| `baoyu-image-gen.md` | Provider fallback order, API key setup |
| `qiaomu-music-player-ncm.md` | mpv sandbox issue, orpheus mode, login flow |

---

## Privacy & security

- **No data leaves your machine.** The injector does pure file I/O.
- **Transcripts are local.** The updater reads only the JSONL transcripts that Claude Code already stores in `~/.claude/projects/`.
- **The distillation call** (`claude -p ...`) runs locally through your existing Claude Code authentication — it never sends raw transcript content to a third-party endpoint.
- **Secrets are not extracted.** The distillation prompt asks only for API/tool lessons, not credentials or personal data.

See [SECURITY.md](SECURITY.md) for the full security policy.

---

## Contributing

1. Fork the repo and create a branch: `git checkout -b feat/my-improvement`
2. Make changes, run a quick smoke-test: `echo '{}' | python3 scripts/inject-skill-knowledge.py`
3. Open a pull request with a clear description of what changes and why

Contributions of new starter `KNOWLEDGE.md` files for popular skills are especially welcome.

---

## License

MIT © 2026 [ccc7574](https://github.com/ccc7574)

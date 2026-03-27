# fireworks-skill-memory

> Let Claude Code remember what it learned last time.

[中文文档](README.zh-CN.md)

---

## What is this?

Every time you use a Claude Code skill, Claude starts fresh — it has no memory of what went wrong last session. **fireworks-skill-memory** fixes that. It quietly watches your sessions and saves lessons learned. Next time you use the same skill, Claude already knows the gotchas.

No manual setup. No config files to edit. Just install and forget.

---

## Install in one sentence

Open Claude Code and say:

> **"Help me install fireworks-skill-memory"**

Claude will run this for you:

```bash
curl -fsSL https://raw.githubusercontent.com/yizhiyanhua-ai/fireworks-skill-memory/main/install.sh | bash
```

Then say **"run /hooks"** to activate. Done.

---

## How does it work?

Two things happen automatically in the background:

**When you use a skill** — Claude reads any past lessons for that skill before responding. Zero delay.

**When your session ends** — Claude quietly reviews what happened, saves 1–3 useful lessons, and forgets the rest. You'll never see this running.

The next session, Claude is a little smarter about that skill.

---

## Is my data safe?

- Everything stays on your computer. Nothing is uploaded anywhere.
- It only reads session files that Claude Code already saves locally.
- It never extracts passwords, keys, or personal information.

---

## Included starter knowledge

The project comes with ready-made lesson files for Claude Code's official skills:

`find-skills` · `skills-updater` · `voice` · `browser-use` · `skill-adoption-planner` · `skill-knowledge-extractor` · `skill-roi-calculator` · `hookify` · `superpowers`

---

## License

MIT © 2026 [yizhiyanhua-ai](https://github.com/yizhiyanhua-ai)

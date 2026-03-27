#!/usr/bin/env python3
"""
fireworks-skill-memory: Skill Knowledge Injector
=================================================
Hook type : PostToolUse on Read
Trigger   : When Claude reads any skill's SKILL.md file
Action    : Injects the corresponding KNOWLEDGE.md into model context
            so Claude benefits from past experience before acting

Performance: Pure file I/O only — no network calls, <5 ms latency.

Installation
------------
Add to ~/.claude/settings.json under hooks.PostToolUse:

  {
    "matcher": "Read",
    "hooks": [{
      "type": "command",
      "command": "python3 /path/to/inject-skill-knowledge.py",
      "if": "Read(**/.claude/skills/*/SKILL.md)"
    }]
  }

Configuration (env vars, optional)
-----------------------------------
SKILLS_KNOWLEDGE_DIR   Path to the skills directory
                       Default: ~/.claude/skills
"""

import json
import os
import sys
from pathlib import Path

# ── Configuration ──────────────────────────────────────────────────────────────
SKILLS_DIR = Path(
    os.environ.get("SKILLS_KNOWLEDGE_DIR", Path.home() / ".claude" / "skills")
)

# ── Read hook input ────────────────────────────────────────────────────────────
try:
    hook_input = json.loads(sys.stdin.read())
except Exception:
    sys.exit(0)

# Only act on Read tool calls
if hook_input.get("tool_name") != "Read":
    sys.exit(0)

# Only act when a SKILL.md inside a skills directory is being read
file_path = hook_input.get("tool_input", {}).get("file_path", "")
if "SKILL.md" not in file_path or "/.claude/skills/" not in file_path:
    sys.exit(0)

# ── Extract skill name from path ───────────────────────────────────────────────
try:
    skill_name = file_path.split("/.claude/skills/")[1].split("/")[0]
except (IndexError, AttributeError):
    sys.exit(0)

if not skill_name:
    sys.exit(0)

# ── Load the skill's KNOWLEDGE.md ─────────────────────────────────────────────
knowledge_file = SKILLS_DIR / skill_name / "KNOWLEDGE.md"
if not knowledge_file.exists():
    sys.exit(0)

knowledge_content = knowledge_file.read_text(encoding="utf-8").strip()
if not knowledge_content:
    sys.exit(0)

# ── Inject into model context via additionalContext ───────────────────────────
output = {
    "hookSpecificOutput": {
        "hookEventName": "PostToolUse",
        "additionalContext": (
            f"\n---\n"
            f"📚 **[fireworks-skill-memory] {skill_name} — past experience**\n\n"
            f"{knowledge_content}\n"
            f"---\n"
        ),
    }
}

print(json.dumps(output, ensure_ascii=False))

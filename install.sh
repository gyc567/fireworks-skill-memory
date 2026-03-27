#!/usr/bin/env bash
# fireworks-skill-memory — one-command installer
# Usage: curl -fsSL https://raw.githubusercontent.com/ccc7574/fireworks-skill-memory/main/install.sh | bash

set -euo pipefail

REPO="https://raw.githubusercontent.com/ccc7574/fireworks-skill-memory/main"
SCRIPTS_DIR="$HOME/.claude/scripts"
SETTINGS="$HOME/.claude/settings.json"
SKILLS_DIR="$HOME/.claude/skills"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
info()  { echo -e "${GREEN}✓${NC} $*"; }
warn()  { echo -e "${YELLOW}⚠${NC}  $*"; }
error() { echo -e "${RED}✗${NC} $*"; exit 1; }

echo ""
echo "🔥 fireworks-skill-memory installer"
echo "────────────────────────────────────"
echo ""

# ── 1. Preflight checks ────────────────────────────────────────────────────────
command -v python3 >/dev/null 2>&1 || error "Python 3 is required but not found. Install it and retry."
command -v claude  >/dev/null 2>&1 || error "Claude Code CLI not found. Install it from https://claude.ai/code"

PY_VERSION=$(python3 -c "import sys; print(sys.version_info.minor)")
[[ "$PY_VERSION" -lt 9 ]] && error "Python 3.9+ required (found 3.$PY_VERSION)"

info "Python $(python3 --version) found"
info "Claude Code found at $(command -v claude)"

# ── 2. Create directories ──────────────────────────────────────────────────────
mkdir -p "$SCRIPTS_DIR"
mkdir -p "$SKILLS_DIR"
info "Directories ready"

# ── 3. Download scripts ────────────────────────────────────────────────────────
echo ""
echo "📥 Downloading scripts..."

curl -fsSL "$REPO/scripts/inject-skill-knowledge.py" \
  -o "$SCRIPTS_DIR/inject-skill-knowledge.py"
info "inject-skill-knowledge.py → $SCRIPTS_DIR/"

curl -fsSL "$REPO/scripts/update-skills-knowledge.py" \
  -o "$SCRIPTS_DIR/update-skills-knowledge.py"
info "update-skills-knowledge.py → $SCRIPTS_DIR/"

# ── 4. Quick syntax check ──────────────────────────────────────────────────────
python3 -m py_compile "$SCRIPTS_DIR/inject-skill-knowledge.py"  || error "Syntax error in inject script"
python3 -m py_compile "$SCRIPTS_DIR/update-skills-knowledge.py" || error "Syntax error in update script"
info "Scripts verified (syntax OK)"

# ── 5. Patch settings.json ─────────────────────────────────────────────────────
echo ""
echo "⚙️  Configuring hooks in $SETTINGS ..."

# Bootstrap an empty settings file if it doesn't exist
if [[ ! -f "$SETTINGS" ]]; then
  echo '{}' > "$SETTINGS"
  warn "Created new $SETTINGS"
fi

# Use Python to merge hooks safely (preserves all existing settings)
python3 - "$SETTINGS" "$SCRIPTS_DIR" <<'PYEOF'
import json, sys
from pathlib import Path

settings_path = Path(sys.argv[1])
scripts_dir   = sys.argv[2]

settings = json.loads(settings_path.read_text())
hooks = settings.setdefault("hooks", {})

# ── Stop hook (async updater) ──────────────────────────────────────────────────
new_stop_hook = {
    "type": "command",
    "command": f"python3 {scripts_dir}/update-skills-knowledge.py",
    "async": True,
}
stop_entries = hooks.setdefault("Stop", [])
# Avoid duplicates: check if the command is already registered
already_stop = any(
    any(h.get("command", "") == new_stop_hook["command"] for h in e.get("hooks", []))
    for e in stop_entries
)
if not already_stop:
    stop_entries.append({"hooks": [new_stop_hook]})

# ── PostToolUse hook (injector) ────────────────────────────────────────────────
new_inject_hook = {
    "type": "command",
    "command": f"python3 {scripts_dir}/inject-skill-knowledge.py",
    "if": "Read(**/.claude/skills/*/SKILL.md)",
}
post_entries = hooks.setdefault("PostToolUse", [])
already_inject = any(
    e.get("matcher") == "Read" and any(
        h.get("command", "") == new_inject_hook["command"]
        for h in e.get("hooks", [])
    )
    for e in post_entries
)
if not already_inject:
    post_entries.append({"matcher": "Read", "hooks": [new_inject_hook]})

settings_path.write_text(
    json.dumps(settings, indent=2, ensure_ascii=False) + "\n"
)
print("OK")
PYEOF

info "Hooks registered in settings.json"

# ── 6. Optional: seed example knowledge files ──────────────────────────────────
echo ""
read -r -p "📚 Seed starter KNOWLEDGE.md files for popular skills? [Y/n] " SEED
SEED="${SEED:-Y}"

if [[ "$SEED" =~ ^[Yy]$ ]]; then
  declare -A SKILL_FILES=(
    ["claude-to-im"]="claude-to-im.md"
    ["baoyu-translate"]="baoyu-translate.md"
    ["baoyu-youtube-transcript"]="baoyu-youtube-transcript.md"
    ["baoyu-image-gen"]="baoyu-image-gen.md"
    ["qiaomu-music-player-ncm"]="qiaomu-music-player-ncm.md"
  )

  for skill in "${!SKILL_FILES[@]}"; do
    skill_dir="$SKILLS_DIR/$skill"
    target="$skill_dir/KNOWLEDGE.md"
    if [[ -f "$target" ]]; then
      warn "$skill/KNOWLEDGE.md already exists — skipping"
    else
      mkdir -p "$skill_dir"
      curl -fsSL "$REPO/examples/skill-knowledge/${SKILL_FILES[$skill]}" -o "$target"
      info "Seeded $skill/KNOWLEDGE.md"
    fi
  done
fi

# ── 7. Done ────────────────────────────────────────────────────────────────────
echo ""
echo "────────────────────────────────────"
echo -e "  ${GREEN}Installation complete!${NC}"
echo "────────────────────────────────────"
echo ""
echo "  Next step → type  /hooks  in Claude Code to reload the configuration."
echo ""
echo "  How it works:"
echo "  • When you use any skill, Claude now automatically loads its past experience."
echo "  • When a session ends, new lessons are distilled and saved for next time."
echo ""
echo "  Repo: https://github.com/ccc7574/fireworks-skill-memory"
echo ""

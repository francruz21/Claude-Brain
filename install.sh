#!/usr/bin/env bash
#
# Symlinks every skill in skills/ into ~/.claude/skills/, so Claude Code
# discovers them as personal skills in any project. Safe to re-run.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_SRC="$REPO_DIR/skills"
SKILLS_DEST="$HOME/.claude/skills"
CLAUDE_MD="$HOME/.claude/CLAUDE.md"

mkdir -p "$SKILLS_DEST"

echo "Installing skills from $SKILLS_SRC into $SKILLS_DEST"
echo

for skill_dir in "$SKILLS_SRC"/*/; do
  name="$(basename "$skill_dir")"
  dest="$SKILLS_DEST/$name"

  if [ -L "$dest" ]; then
    current_target="$(readlink "$dest")"
    if [ "$current_target" = "$skill_dir" ] || [ "$current_target" = "${skill_dir%/}" ]; then
      echo "  ok      $name (already linked)"
      continue
    else
      echo "  skip    $name (symlink exists, points elsewhere: $current_target)"
      continue
    fi
  elif [ -e "$dest" ]; then
    echo "  skip    $name (real file/dir already exists at $dest, not touching it)"
    continue
  fi

  ln -s "${skill_dir%/}" "$dest"
  echo "  linked  $name -> $dest"
done

echo
echo "Done. Skills available in ~/.claude/skills/."
echo

REFERENCE_BLOCK="# claude-brain
- **claude-brain** (\`$REPO_DIR\`) - personal knowledge base: rules, playbooks,
  templates. Check \`$REPO_DIR/rules/\`, \`$REPO_DIR/playbooks/\` and
  \`$REPO_DIR/templates/\` for reusable conventions and processes before
  inventing new ones. Repo-local rules always take priority over these."

if [ -f "$CLAUDE_MD" ] && grep -q "claude-brain" "$CLAUDE_MD"; then
  echo "~/.claude/CLAUDE.md already references claude-brain, nothing to add."
else
  echo "~/.claude/CLAUDE.md does not reference claude-brain yet."
  echo "Add this block to it manually (not done automatically, to avoid"
  echo "clobbering your existing global instructions):"
  echo
  echo "-----------------------------------------------------------------"
  echo "$REFERENCE_BLOCK"
  echo "-----------------------------------------------------------------"
fi

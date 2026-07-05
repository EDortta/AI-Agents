#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Install AI-Agents kit into a target project.

Usage:
  # Local source (when running inside this repository)
  ./scripts/install-agents-kit.sh --target /path/to/project
  ./scripts/install-agents-kit.sh --target /path/to/project --upgrade

  # Directly from GitHub (curl | bash) — pins to a release tag, not the
  # mutable "main" branch; verify the printed sha256 against the release
  # notes if you want an extra check before running.
  bash <(curl -fsSL https://raw.githubusercontent.com/EDortta/AI-Agents/v1.0.2/scripts/install-agents-kit.sh) \
    --target /path/to/project

Prefer over the one-liner: clone the repo and inspect it before running,
especially the first time:
  git clone --branch v1.0.2 https://github.com/EDortta/AI-Agents.git
  less AI-Agents/scripts/install-agents-kit.sh
  ./AI-Agents/scripts/install-agents-kit.sh --target /path/to/project

Options:
  --target <dir>     Target project directory (default: current dir)
  --repo <name>      GitHub repo in owner/repo format (default: EDortta/AI-Agents)
  --ref <ref>        Git ref/branch/tag for download (default: v1.0.2 — pin to a
                      release tag; passing a mutable ref like "main" is your choice,
                      not the kit's)
  --checksum <sha256> Expected sha256 of the downloaded tarball; aborts on mismatch
  --force            Overwrite existing kit files in target
  --upgrade          Update kit-owned files while preserving project-local context/state
  --help             Show this help

Layout:
  Kit-owned files install under .docs/ (managed, replaced on --upgrade).
  docs/ is 100% project territory and is never overwritten.

Readiness gate:
  Installation exits with non-zero until both are set:
  - .docs/software-overview.md -> project_context_ready: yes
  - .docs/limits.md            -> limits_ready: yes
USAGE
}

TARGET_DIR="$(pwd)"
REPO="EDortta/AI-Agents"
REF="v1.0.2"
CHECKSUM=""
FORCE="0"
UPGRADE="0"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target)
      TARGET_DIR="$2"
      shift 2
      ;;
    --repo)
      REPO="$2"
      shift 2
      ;;
    --ref)
      REF="$2"
      shift 2
      ;;
    --checksum)
      CHECKSUM="$2"
      shift 2
      ;;
    --force)
      FORCE="1"
      shift
      ;;
    --upgrade)
      UPGRADE="1"
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      exit 2
      ;;
  esac
done

if [[ "$FORCE" == "1" && "$UPGRADE" == "1" ]]; then
  echo "ERROR: --force and --upgrade cannot be used together." >&2
  exit 2
fi

TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"

SRC_ROOT=""
SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd 2>/dev/null || true)"
if [[ -n "$SELF_DIR" && -f "$SELF_DIR/../AGENTS.md" ]]; then
  SRC_ROOT="$(cd "$SELF_DIR/.." && pwd)"
fi

TMP_DIR=""
cleanup() {
  if [[ -n "$TMP_DIR" && -d "$TMP_DIR" ]]; then
    rm -rf "$TMP_DIR"
  fi
}
trap cleanup EXIT

if [[ -z "$SRC_ROOT" ]]; then
  TMP_DIR="$(mktemp -d)"
  ARCHIVE="$TMP_DIR/src.tar.gz"
  URL="https://codeload.github.com/${REPO}/tar.gz/${REF}"

  echo "Downloading kit from: $URL"
  curl -fsSL "$URL" -o "$ARCHIVE"

  ACTUAL_SHA="$(sha256sum "$ARCHIVE" | cut -d' ' -f1)"
  if [[ -n "$CHECKSUM" ]]; then
    if [[ "$ACTUAL_SHA" != "$CHECKSUM" ]]; then
      echo "ERROR: checksum mismatch for downloaded tarball." >&2
      echo "  expected: $CHECKSUM" >&2
      echo "  actual:   $ACTUAL_SHA" >&2
      exit 7
    fi
    echo "Checksum verified: $ACTUAL_SHA"
  else
    echo "NOTE: no --checksum given, skipping integrity check. Tarball sha256: $ACTUAL_SHA"
  fi

  tar -xzf "$ARCHIVE" -C "$TMP_DIR"
  SRC_ROOT="$(find "$TMP_DIR" -mindepth 1 -maxdepth 1 -type d | head -n1)"
fi

if [[ ! -d "$TARGET_DIR" ]]; then
  echo "ERROR: Target directory does not exist: $TARGET_DIR" >&2
  exit 4
fi

copy_path() {
  local rel="$1"
  local src="$SRC_ROOT/$rel"
  local dst="$TARGET_DIR/$rel"

  if [[ ! -e "$src" ]]; then
    echo "WARN: Missing source path, skipping: $rel"
    return 0
  fi

  if [[ -e "$dst" && "$FORCE" != "1" ]]; then
    echo "ERROR: Target already has '$rel'. Re-run with --force to overwrite." >&2
    exit 5
  fi

  mkdir -p "$(dirname "$dst")"
  if [[ "$FORCE" == "1" && -e "$dst" ]]; then
    rm -rf "$dst"
  fi
  cp -a "$src" "$dst"
}

copy_file_replace() {
  local rel="$1"
  local src="$SRC_ROOT/$rel"
  local dst="$TARGET_DIR/$rel"

  if [[ ! -f "$src" ]]; then
    echo "WARN: Missing source file, skipping: $rel"
    return 0
  fi

  mkdir -p "$(dirname "$dst")"
  cp -a "$src" "$dst"
  echo "updated file: $rel"
}

replace_dir() {
  local rel="$1"
  local src="$SRC_ROOT/$rel"
  local dst="$TARGET_DIR/$rel"

  if [[ ! -d "$src" ]]; then
    echo "WARN: Missing source directory, skipping: $rel"
    return 0
  fi

  rm -rf "$dst"
  mkdir -p "$(dirname "$dst")"
  cp -a "$src" "$dst"
  echo "updated directory: $rel"
}

remove_obsolete_path() {
  local rel="$1"
  local dst="$TARGET_DIR/$rel"

  if [[ -e "$dst" ]]; then
    rm -rf "$dst"
    echo "removed obsolete path: $rel"
  fi
}

migrate_legacy_layout() {
  # Move a legacy install (kit under docs/, project under docs/project/) to the
  # new layout (kit under .docs/, project owns docs/). Idempotent: a no-op once
  # .docs/ already holds the kit. A backup of the pre-migration docs/ is kept.
  if [[ -d "$TARGET_DIR/.docs/agents" ]]; then
    return 0
  fi
  if [[ ! -d "$TARGET_DIR/docs/agents" && ! -d "$TARGET_DIR/docs/project" ]]; then
    return 0
  fi

  echo "Legacy layout detected -> migrating docs/ (kit) to .docs/ and promoting docs/project/."
  # Never clobber an existing backup: pick the first free .docs-migration-bak[-N].
  local bak="$TARGET_DIR/.docs-migration-bak"
  if [[ -e "$bak" ]]; then
    local n=1
    while [[ -e "${bak}-${n}" ]]; do n=$((n + 1)); done
    bak="${bak}-${n}"
  fi
  mkdir -p "$bak"
  cp -a "$TARGET_DIR/docs" "$bak/docs"
  echo "backup written: ${bak#$TARGET_DIR/}/docs"

  mkdir -p "$TARGET_DIR/.docs/issues"
  local kit_dirs=(agents workflows articles icons)
  local d
  for d in "${kit_dirs[@]}"; do
    if [[ -d "$TARGET_DIR/docs/$d" ]]; then
      rm -rf "$TARGET_DIR/.docs/$d"
      mv "$TARGET_DIR/docs/$d" "$TARGET_DIR/.docs/$d"
    fi
  done
  if [[ -d "$TARGET_DIR/docs/issues/templates" ]]; then
    rm -rf "$TARGET_DIR/.docs/issues/templates"
    mv "$TARGET_DIR/docs/issues/templates" "$TARGET_DIR/.docs/issues/templates"
  fi
  local kit_files=(software-overview.md limits.md index.html concepts.html issues/README.md)
  local f
  for f in "${kit_files[@]}"; do
    if [[ -f "$TARGET_DIR/docs/$f" ]]; then
      mkdir -p "$(dirname "$TARGET_DIR/.docs/$f")"
      mv "$TARGET_DIR/docs/$f" "$TARGET_DIR/.docs/$f"
    fi
  done

  # Promote project-owned docs/project/* up into docs/ (project territory).
  # Items that collide with an existing docs/<name> cannot be auto-promoted; they
  # are left in place under docs/project/ (a copy is also in the backup) and
  # reported so the maintainer resolves them by hand.
  local conflicts=0
  if [[ -d "$TARGET_DIR/docs/project" ]]; then
    shopt -s dotglob nullglob
    local item
    for item in "$TARGET_DIR/docs/project"/*; do
      local base
      base="$(basename "$item")"
      if [[ -e "$TARGET_DIR/docs/$base" ]]; then
        conflicts=$((conflicts + 1))
        echo "CONFLICT: docs/$base already exists; left docs/project/$base in place (also in ${bak#$TARGET_DIR/}/docs/project/$base) -- resolve manually."
      else
        mv "$item" "$TARGET_DIR/docs/$base"
      fi
    done
    shopt -u dotglob nullglob
    # rmdir only succeeds when every item was promoted (dir now empty).
    rmdir "$TARGET_DIR/docs/project" 2>/dev/null || true
  fi

  if [[ "$conflicts" -gt 0 ]]; then
    echo "migration finished with $conflicts unresolved conflict(s) still under docs/project/; resolve them, then delete the folder. Backup kept at ${bak#$TARGET_DIR/}/."
  else
    echo "migration complete; review ${bak#$TARGET_DIR/}/ then remove it when satisfied."
  fi
}

reset_target_readiness_flags() {
  local so_file="$TARGET_DIR/.docs/software-overview.md"
  local lim_file="$TARGET_DIR/.docs/limits.md"

  if [[ -f "$so_file" ]]; then
    sed -i 's/^- project_context_ready:[[:space:]]*yes$/- project_context_ready: no/' "$so_file"
  fi

  if [[ -f "$lim_file" ]]; then
    sed -i 's/^- limits_ready:[[:space:]]*yes$/- limits_ready: no/' "$lim_file"
  fi
}

upgrade_kit() {
  echo "Upgrading kit-owned files in: $TARGET_DIR"

  migrate_legacy_layout

  # Root kit files. These are safe to replace because project-specific context
  # lives in .docs/software-overview.md, .docs/limits.md, handoff, issues, and lessons.
  copy_file_replace "AGENTS.md"
  copy_file_replace "README.md"
  copy_file_replace "README-ptbr.md"
  copy_file_replace "README-es.md"
  copy_file_replace ".cursorrules"
  copy_file_replace "CLAUDE.md"
  copy_file_replace ".windsurfrules"
  copy_file_replace "GEMINI.md"
  copy_file_replace ".github/copilot-instructions.md"
  copy_file_replace "new-tag.sh"
  copy_file_replace "scripts/install-agents-kit.sh"
  copy_file_replace "scripts/agent-worktree.sh"
  replace_dir "templates"

  # Kit-owned directories are replaced wholesale so files deleted from the kit
  # are also deleted from existing installations.
  replace_dir ".docs/agents"
  replace_dir ".docs/workflows"
  replace_dir ".docs/articles"
  replace_dir ".docs/icons"
  replace_dir ".docs/issues/templates"

  # Kit-owned reference pages.
  copy_file_replace ".docs/index.html"
  copy_file_replace ".docs/concepts.html"

  # Keep the issues index current without touching project issue folders.
  copy_file_replace ".docs/issues/README.md"

  # Preserve project-local files/state.
  echo "preserved project-local: .docs/software-overview.md"
  echo "preserved project-local: .docs/limits.md"
  echo "preserved project-local: docs/ (project territory, never overwritten)"
  echo "preserved project-local: docs/required-reading.md"
  echo "preserved project-local: handoff.md"
  echo "preserved project-local: docs/napkin-lessons.md"
  echo "preserved project-local: docs/issues/"
  echo "preserved project-local: .credentials/"

  # Add paths here when a future kit version removes a formerly installed file
  # outside the replaced directories above.
  local obsolete_paths=()
  local obsolete
  for obsolete in "${obsolete_paths[@]}"; do
    remove_obsolete_path "$obsolete"
  done
}

if [[ "$UPGRADE" == "1" ]]; then
  upgrade_kit
else
  # Core files/directories to install
  copy_path "AGENTS.md"
  copy_path "README.md"
  copy_path "README-ptbr.md"
  copy_path "README-es.md"
  copy_path ".cursorrules"
  copy_path "CLAUDE.md"
  copy_path ".windsurfrules"
  copy_path "GEMINI.md"
  copy_path ".github/copilot-instructions.md"
  copy_path ".credentials"
  copy_path ".docs"
  copy_path "handoff.md"
  copy_path "scripts/agent-worktree.sh"
  copy_path "templates"

  # Seed project territory (docs/) from kit starters when the target lacks them.
  # These are project-owned once created; --upgrade never overwrites them.
  mkdir -p "$TARGET_DIR/docs/issues"
  if [[ -f "$SRC_ROOT/docs/required-reading.md" && ! -e "$TARGET_DIR/docs/required-reading.md" ]]; then
    cp -a "$SRC_ROOT/docs/required-reading.md" "$TARGET_DIR/docs/required-reading.md"
  fi
  if [[ -f "$SRC_ROOT/docs/napkin-lessons.md" && ! -e "$TARGET_DIR/docs/napkin-lessons.md" ]]; then
    cp -a "$SRC_ROOT/docs/napkin-lessons.md" "$TARGET_DIR/docs/napkin-lessons.md"
  fi
  if [[ ! -e "$TARGET_DIR/docs/README.md" ]]; then
    printf '# Project Documentation\n\nThis folder (docs/) is 100%%%% project territory; the installer never overwrites it.\nKit-owned docs live under .docs/ and are replaced on --upgrade.\nList mandatory pre-issue reading in docs/required-reading.md.\n' \
      > "$TARGET_DIR/docs/README.md"
  fi

  reset_target_readiness_flags

  echo "Kit files copied to: $TARGET_DIR"
fi

echo "Kit files ready in: $TARGET_DIR"

SO_FILE="$TARGET_DIR/.docs/software-overview.md"
LIM_FILE="$TARGET_DIR/.docs/limits.md"

check_ready_flag() {
  local file="$1"
  local pattern="$2"
  if [[ ! -f "$file" ]]; then
    return 1
  fi
  grep -Eq "$pattern" "$file"
}

SO_READY="0"
LIM_READY="0"

if check_ready_flag "$SO_FILE" '^- project_context_ready:[[:space:]]*yes$'; then
  SO_READY="1"
fi
if check_ready_flag "$LIM_FILE" '^- limits_ready:[[:space:]]*yes$'; then
  LIM_READY="1"
fi

if [[ "$SO_READY" != "1" || "$LIM_READY" != "1" ]]; then
  cat <<EOF2

INSTALLATION BLOCKED BY READINESS GATE

Before using the agents-kit, the programmer must edit:
- $SO_FILE   -> set: project_context_ready: yes
- $LIM_FILE  -> set: limits_ready: yes

Also fill real project context/limits content in both files.
After that, re-run this installer (or run your workflow checks).
EOF2
  exit 30
fi

cat <<EOF2

Installation complete and readiness gate passed.
You can now use the kit in this project.
EOF2

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
  bash <(curl -fsSL https://raw.githubusercontent.com/EDortta/AI-Agents/v1.1.1/scripts/install-agents-kit.sh) \
    --target /path/to/project

Prefer over the one-liner: clone the repo and inspect it before running,
especially the first time:
  git clone --branch v1.1.1 https://github.com/EDortta/AI-Agents.git
  less AI-Agents/scripts/install-agents-kit.sh
  ./AI-Agents/scripts/install-agents-kit.sh --target /path/to/project

Options:
  --target <dir>     Target project directory (default: current dir)
  --repo <name>      GitHub repo in owner/repo format (default: EDortta/AI-Agents)
  --ref <ref>        Git ref/branch/tag for download (default: v1.1.1 — pin to a
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
REF="v1.1.1"
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

# ── kit manifest (.gk/) ────────────────────────────────────────────────────────
#
# Mirrors governancekit: .gk/manifest.json records the sha256 of every file the KIT
# wrote, so an upgrade can tell a kit file apart from a file the project authored
# inside a kit-owned directory. Without it the only possible upgrade is "replace the
# whole directory", which silently deletes project rules.
#
# JSON handling needs python3. When it is missing we degrade to never deleting
# anything — losing retirement, never losing project work.

STATE_DIR=".gk"
MANIFEST_REL="$STATE_DIR/manifest.json"
MANIFEST_LOADED=""
declare -A KIT_HASHES=()
PRESERVED=()
OVERWRITTEN=()

have_python() { command -v python3 >/dev/null 2>&1; }

load_manifest() {
  [[ -n "$MANIFEST_LOADED" ]] && return 0
  MANIFEST_LOADED="1"

  local file="$TARGET_DIR/$MANIFEST_REL"
  [[ -f "$file" ]] || return 0
  if ! have_python; then
    echo "WARN: python3 not found — cannot read $MANIFEST_REL; nothing will be deleted."
    return 0
  fi

  local path hash
  while IFS=$'\t' read -r path hash; do
    [[ -n "$path" ]] && KIT_HASHES["$path"]="$hash"
  done < <(python3 - "$file" <<'PY'
import json, sys
try:
    with open(sys.argv[1], encoding="utf-8") as fh:
        data = json.load(fh)
except Exception:
    sys.exit(0)
files = data.get("files") if isinstance(data, dict) else None
if isinstance(files, dict):
    for path, digest in files.items():
        if isinstance(path, str) and isinstance(digest, str):
            print(f"{path}\t{digest}")
PY
  )
}

file_sha256() { sha256sum "$1" | cut -d' ' -f1; }

# Replace a kit directory WITHOUT discarding project-authored files.
#
# Every file the new kit ships is written. A destination file the kit does not ship is
# removed only when the manifest proves the kit wrote it AND the content is still
# byte-identical — i.e. retired upstream and never touched here. Everything else is
# kept and reported. A kit file edited by hand is still kit-owned so the new version
# wins, but the edit is stashed under .gk/overwritten/ rather than destroyed.
sync_dir() {
  local rel="$1"
  local src="$SRC_ROOT/$rel"
  local dst="$TARGET_DIR/$rel"

  if [[ ! -d "$src" ]]; then
    echo "WARN: Missing source directory, skipping: $rel"
    return 0
  fi

  load_manifest
  mkdir -p "$dst"

  local f sub target rel_to_root recorded
  # Pass 1 — write everything the new kit ships.
  while IFS= read -r -d '' f; do
    sub="${f#"$src"/}"
    target="$dst/$sub"
    rel_to_root="${target#"$TARGET_DIR"/}"
    mkdir -p "$(dirname "$target")"
    if [[ -f "$target" ]]; then
      recorded="${KIT_HASHES[$rel_to_root]-}"
      if [[ -n "$recorded" && "$recorded" != "$(file_sha256 "$target")" ]]; then
        local stash="$TARGET_DIR/$STATE_DIR/overwritten/$rel_to_root"
        mkdir -p "$(dirname "$stash")"
        cp -a "$target" "$stash"
        OVERWRITTEN+=("$rel_to_root")
      fi
    fi
    cp -a "$f" "$target"
  done < <(find "$src" -type f -print0)

  # Pass 2 — decide what to do with destination files the new kit does not ship.
  while IFS= read -r -d '' f; do
    sub="${f#"$dst"/}"
    rel_to_root="${f#"$TARGET_DIR"/}"
    if [[ -f "$src/$sub" ]]; then
      continue
    fi
    recorded="${KIT_HASHES[$rel_to_root]-}"
    if [[ -n "$recorded" && "$recorded" == "$(file_sha256 "$f")" ]]; then
      rm -f "$f"
      continue
    fi
    PRESERVED+=("$rel_to_root")
  done < <(find "$dst" -type f -print0)

  find "$dst" -type d -empty -delete 2>/dev/null || true
  mkdir -p "$dst"
  echo "updated directory: $rel"
}

# Record every kit file now on disk. Merges over the previous manifest: a narrower run
# must not make the next upgrade forget that e.g. AGENTS.md is kit-owned.
write_manifest() {
  if ! have_python; then
    echo "WARN: python3 not found — skipping $MANIFEST_REL; the next upgrade will not"
    echo "      be able to retire files this kit version dropped (nothing is lost)."
    return 0
  fi

  local tmp
  tmp="$(mktemp)"
  local rel dst f rel_to_root
  for rel in "$@"; do
    dst="$TARGET_DIR/$rel"
    if [[ -f "$dst" ]]; then
      printf '%s\t%s\n' "$rel" "$(file_sha256 "$dst")" >> "$tmp"
    elif [[ -d "$dst" ]]; then
      while IFS= read -r -d '' f; do
        rel_to_root="${f#"$TARGET_DIR"/}"
        printf '%s\t%s\n' "$rel_to_root" "$(file_sha256 "$f")" >> "$tmp"
      done < <(find "$dst" -type f -print0)
    fi
  done

  mkdir -p "$TARGET_DIR/$STATE_DIR"
  # Self-contained ignore rules: manifest.json stays TRACKED so a team sharing the
  # checkout judges file ownership from the same baseline, while the credential half
  # and the stash never reach git. Kept inside .gk/ so the installer never has to edit
  # the project's own .gitignore.
  cat > "$TARGET_DIR/$STATE_DIR/.gitignore" <<'IGN'
# Managed by the AI-Agents installer.
# manifest.json is intentionally NOT ignored — the team must share it.
secrets.json
overwritten/
IGN

  python3 - "$TARGET_DIR/$MANIFEST_REL" "$tmp" "$REPO" "$REF" <<'PY'
import json, sys
manifest_path, pairs_path, repo, ref = sys.argv[1:5]
try:
    with open(manifest_path, encoding="utf-8") as fh:
        previous = json.load(fh)
    files = previous.get("files") if isinstance(previous, dict) else {}
    files = dict(files) if isinstance(files, dict) else {}
    metadata = previous.get("metadata") if isinstance(previous, dict) else {}
    metadata = metadata if isinstance(metadata, dict) else {}
except Exception:
    files, metadata = {}, {}

with open(pairs_path, encoding="utf-8") as fh:
    for line in fh:
        path, _, digest = line.rstrip("\n").partition("\t")
        if path and digest:
            files[path] = digest

with open(manifest_path, "w", encoding="utf-8") as fh:
    json.dump(
        {"state_version": 1, "repo": repo, "ref": ref,
         "metadata": metadata, "files": files},
        fh, indent=2, sort_keys=True,
    )
    fh.write("\n")
PY
  rm -f "$tmp"
  echo "recorded kit manifest: $MANIFEST_REL"
}

report_upgrade_effects() {
  if [[ ${#PRESERVED[@]} -gt 0 ]]; then
    echo
    echo "Preserved ${#PRESERVED[@]} project-authored file(s) inside kit directories:"
    local p
    for p in "${PRESERVED[@]}"; do echo "  kept: $p"; done
  fi
  if [[ ${#OVERWRITTEN[@]} -gt 0 ]]; then
    echo
    echo "Replaced ${#OVERWRITTEN[@]} kit file(s) you had edited by hand — your version"
    echo "was stashed under $STATE_DIR/overwritten/:"
    local p
    for p in "${OVERWRITTEN[@]}"; do echo "  stashed: $p"; done
    echo "  Kit files are kit-owned. Move lasting project rules into your own files."
  fi
  if [[ ${#KIT_HASHES[@]} -eq 0 ]]; then
    echo
    echo "Note: no kit manifest existed before this run, so nothing was deleted."
    echo "This run wrote one; later upgrades can retire files the kit drops."
  fi
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
  echo "backup written: ${bak#"$TARGET_DIR"/}/docs"

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
        echo "CONFLICT: docs/$base already exists; left docs/project/$base in place (also in ${bak#"$TARGET_DIR"/}/docs/project/$base) -- resolve manually."
      else
        mv "$item" "$TARGET_DIR/docs/$base"
      fi
    done
    shopt -u dotglob nullglob
    # rmdir only succeeds when every item was promoted (dir now empty).
    rmdir "$TARGET_DIR/docs/project" 2>/dev/null || true
  fi

  if [[ "$conflicts" -gt 0 ]]; then
    echo "migration finished with $conflicts unresolved conflict(s) still under docs/project/; resolve them, then delete the folder. Backup kept at ${bak#"$TARGET_DIR"/}/."
  else
    echo "migration complete; review ${bak#"$TARGET_DIR"/}/ then remove it when satisfied."
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
  copy_file_replace "scripts/git-bare-remote.sh"
  sync_dir "templates"

  # Kit-owned directories are synced file-by-file: kit files are replaced, files the
  # kit dropped are retired only when the manifest proves it wrote them untouched, and
  # project-authored files inside these directories are preserved (see sync_dir).
  sync_dir ".docs/agents"
  sync_dir ".docs/workflows"
  sync_dir ".docs/articles"
  sync_dir ".docs/icons"
  sync_dir ".docs/issues/templates"

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

# Every path the kit owns, for the manifest. Kept next to the copy/upgrade lists so a
# future path added there is added here too — a path missing from the manifest is
# simply never retired, which is safe but silently accumulates.
KIT_OWNED_PATHS=(
  "AGENTS.md" "README.md" "README-ptbr.md" "README-es.md"
  ".cursorrules" "CLAUDE.md" ".windsurfrules" "GEMINI.md"
  ".github/copilot-instructions.md" "new-tag.sh"
  "scripts/install-agents-kit.sh" "scripts/agent-worktree.sh" "scripts/git-bare-remote.sh"
  "templates"
  ".docs/agents" ".docs/workflows" ".docs/articles" ".docs/icons"
  ".docs/issues/templates" ".docs/issues/README.md"
  ".docs/index.html" ".docs/concepts.html"
)

if [[ "$UPGRADE" == "1" ]]; then
  upgrade_kit
  write_manifest "${KIT_OWNED_PATHS[@]}"
  report_upgrade_effects
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
  copy_path "scripts/git-bare-remote.sh"
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

  # Record ownership on a fresh install too, so the FIRST upgrade already knows what
  # the kit put here instead of having to preserve everything indiscriminately.
  write_manifest "${KIT_OWNED_PATHS[@]}"

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

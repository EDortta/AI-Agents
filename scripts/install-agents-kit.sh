#!/usr/bin/env bash
# AI-Agents kit-owned file. Do not edit: `install-agents-kit.sh --upgrade` replaces it.
# Project-specific rules  -> docs/project-rules.md (never overwritten)
# Operator values ({{…}}) -> .gk/identity.json    (never overwritten)
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
  --strict           With --upgrade: exit non-zero when a protected file was preserved
                      instead of replaced (for CI; the upgrade itself still completes)
  --check            Read-only drift report: what an --upgrade would preserve, replace,
                      or stash. Writes nothing.
  --migrate          Separate project content from kit content BEFORE upgrading:
                      extracts operator values into .gk/identity.json, moves purely
                      added sections out to docs/project-rules.md, and reports what
                      needs a human. Writes to the target; requires a TTY and an
                      explicit confirmation.
  --help             Show this help

Recommended workflow on an existing target:
  --check     see the drift
  --migrate   isolate project content and operator values (gated, interactive)
  --upgrade   now a clean replace; operator values are re-applied automatically

Layout:
  Kit-owned files install under .docs/ (managed, replaced on --upgrade).
  docs/ is 100% project territory and is never overwritten.
  docs/project-rules.md is the official home for project-specific rules; the kit
  seeds it once and no upgrade ever touches it.

Operator values:
  Kit files carry {{TOKEN}} slots. Values live in .gk/identity.json ("values" for
  literals, "refs" for paths to credential files — never a secret inline) and are
  re-applied on every install/upgrade, so an upgrade cannot burn them. No upgrade
  path touches .gk/identity.json.

Protected files:
  AGENTS.md is kit-owned but never replaced once it differs from what the kit
  installed. The new version is left beside it as AGENTS.md.kit-new, and the
  difference is reported so it can be merged by hand.

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
STRICT="0"
CHECK="0"
MIGRATE="0"

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
    --strict)
      STRICT="1"
      shift
      ;;
    --check)
      CHECK="1"
      shift
      ;;
    --migrate)
      MIGRATE="1"
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

# --check writes nothing, so pairing it with a mode that writes is a contradiction
# rather than a refinement: refuse instead of silently letting one win.
if [[ "$CHECK" == "1" && ( "$FORCE" == "1" || "$UPGRADE" == "1" ) ]]; then
  echo "ERROR: --check is read-only and cannot be combined with --force or --upgrade." >&2
  exit 2
fi

if [[ "$STRICT" == "1" && "$UPGRADE" != "1" ]]; then
  echo "ERROR: --strict only applies to --upgrade." >&2
  exit 2
fi

# --migrate is a distinct phase, not a modifier: it rewrites the target's kit files
# in place so that a LATER --upgrade is a clean replace. Running both in one command
# would hide which step made which change.
if [[ "$MIGRATE" == "1" && ( "$FORCE" == "1" || "$UPGRADE" == "1" || "$CHECK" == "1" ) ]]; then
  echo "ERROR: --migrate runs on its own; run it, review the report, then --upgrade." >&2
  exit 2
fi

TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"

SRC_ROOT=""
SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd 2>/dev/null || true)"
if [[ -n "$SELF_DIR" && -f "$SELF_DIR/../AGENTS.md" ]]; then
  SRC_ROOT="$(cd "$SELF_DIR/.." && pwd)"
fi

TMP_DIR=""
RENDER_DIR=""
cleanup() {
  if [[ -n "$TMP_DIR" && -d "$TMP_DIR" ]]; then
    rm -rf "$TMP_DIR"
  fi
  if [[ -n "$RENDER_DIR" && -d "$RENDER_DIR" ]]; then
    rm -rf "$RENDER_DIR"
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

# ── protected root files ───────────────────────────────────────────────────────
#
# Root kit files used to be replaced blindly. The comment above upgrade_kit called
# that safe "because project-specific context lives elsewhere" — a premise nothing
# enforced, and one this kit actively undermines: AGENTS.md is the first file every
# agent is told to read, so it is the first place anyone writes a project rule.
# A real target (2026-07-23) had ~300 lines of project rules in it, including real
# reviewer logins. An --upgrade would have deleted all of it without a word.
#
# So a protected file is kit-owned for reading and project-owned for writing: once
# its content differs from what the kit installed, the kit stops claiming it. The
# new version lands beside it as <file>.kit-new and the operator merges by hand.
PROTECTED_ROOT_FILES=("AGENTS.md")
DRIFTED=()
BACKED_UP=()

# Every root file replaced through copy_file_replace, named once. upgrade_kit walks it,
# KIT_OWNED_PATHS includes it, and check_drift judges exactly it — the three used to be
# separate lists, and check_drift silently disagreed with what an upgrade actually does.
KIT_ROOT_FILES=(
  "AGENTS.md"
  "README.md" "README-ptbr.md" "README-es.md"
  ".cursorrules" "CLAUDE.md" ".windsurfrules" "GEMINI.md"
  ".github/copilot-instructions.md"
  "new-tag.sh"
  "scripts/install-agents-kit.sh" "scripts/agent-worktree.sh" "scripts/git-bare-remote.sh"
)

is_protected() {
  local rel="$1" p
  for p in "${PROTECTED_ROOT_FILES[@]}"; do
    [[ "$p" == "$rel" ]] && return 0
  done
  return 1
}

is_root_file() {
  local rel="$1" p
  for p in "${KIT_ROOT_FILES[@]}"; do
    [[ "$p" == "$rel" ]] && return 0
  done
  return 1
}

# Replace a single kit-owned file, judging it against the manifest first.
#
#   hash matches manifest  -> untouched kit content; replace, silently
#   hash differs           -> protected: keep it, write .kit-new, report
#                             other:     stash under .gk/overwritten/, replace
#   no manifest entry      -> unknown provenance (pre-.gk install, or no python3)
#                             protected: fail closed — keep it, write .kit-new
#                             other:     replace (the old behaviour)
#
# Fail-closed on "unknown" is the case that matters: the installs most likely to
# hold hand-written rules are precisely the ones predating the manifest.
copy_file_replace() {
  local rel="$1"
  local src="$SRC_ROOT/$rel"
  local dst="$TARGET_DIR/$rel"

  if [[ ! -f "$src" ]]; then
    echo "WARN: Missing source file, skipping: $rel"
    return 0
  fi

  if [[ -f "$dst" ]]; then
    # Identical to what we are about to write: there is nothing to preserve and nothing
    # to report, whatever the manifest says. This is not an optimisation — it is what
    # makes --migrate work. After a migration the file IS the rendered kit version, but
    # the manifest still holds the pre-migration hash, and judging by the manifest alone
    # would flag a byte-identical file as drift and demand a merge against itself.
    if [[ "$(file_sha256 "$dst")" == "$(file_sha256 "$src")" ]]; then
      rm -f "$dst.kit-new"   # a .kit-new from an earlier run is stale once they match
      return 0
    fi

    load_manifest
    local recorded="${KIT_HASHES[$rel]-}"

    if [[ -z "$recorded" || "$recorded" != "$(file_sha256 "$dst")" ]]; then
      if is_protected "$rel"; then
        cp -a "$src" "$dst.kit-new"
        DRIFTED+=("$rel")
        echo "preserved (differs from kit): $rel -> new version at $rel.kit-new"
        return 0
      fi
      if [[ -n "$recorded" ]]; then
        local stash="$TARGET_DIR/$STATE_DIR/overwritten/$rel"
        mkdir -p "$(dirname "$stash")"
        cp -a "$dst" "$stash"
        OVERWRITTEN+=("$rel")
      fi
    fi

    # Cheap insurance, independent of the judgement above: even a file the manifest
    # calls untouched gets a copy kept, so a wrong call costs one cp to undo.
    # Kept under .gk/ rather than beside the file so an upgrade does not litter the
    # project root with a dozen .bak files.
    local backup="$TARGET_DIR/$STATE_DIR/pre-upgrade/$rel"
    mkdir -p "$(dirname "$backup")"
    cp -a "$dst" "$backup"
    BACKED_UP+=("$rel")

    # A .kit-new from an earlier run is stale once the file is back in sync.
    rm -f "$dst.kit-new"
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
IDENTITY_REL="$STATE_DIR/identity.json"
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

# ── operator identity ({{TOKEN}} slots) ────────────────────────────────────────
#
# Kit files ship with {{TOKEN}} slots instead of the operator's real name/account
# (LGPD Art. 46: no personal data in tracked kit source). Before this, filling a slot
# meant editing the kit file by hand — which turned the file into drift, so every
# upgrade either burned the value or demanded a manual merge for a value that was
# never in dispute.
#
# Now the value lives in .gk/identity.json (project-owned, no upgrade path reaches it)
# and the installer re-applies it to the incoming kit source on every run. A filled
# slot is therefore not drift at all: the rendered source and the file on disk match
# byte for byte, and the manifest records the rendered hash.
#
# {{...}} is chosen over [...] deliberately: [MANDATORY], [PROHIBITED] and [DEFAULT]
# are content vocabulary in these documents, so a bracket-shaped token cannot be told
# from prose without a hand-maintained allowlist. {{...}} never occurs as content.
#
# Only DECLARED tokens are substituted — never "any {{...}}" — so an unrelated
# construct (a GitHub Actions ${{ }} expression, a mustache template shipped as an
# example) is left untouched.

# Valid JSON has no comments, so the starter carries its instructions in a "_readme"
# key. Empty values are ignored by the renderer, so an unfilled starter is a no-op and
# the Start Gate still reports the slots.
seed_identity() {
  local dst="$TARGET_DIR/$IDENTITY_REL"
  [[ -e "$dst" ]] && return 0

  mkdir -p "$TARGET_DIR/$STATE_DIR"
  cat > "$dst" <<'JSON'
{
  "state_version": 1,
  "_readme": [
    "Operator values for the {{TOKEN}} slots in kit-owned files.",
    "'values' holds literals. 'refs' holds PATHS to credential files — never put a",
    "secret in here; this file is tracked so the team shares the same baseline.",
    "install-agents-kit.sh re-applies these on every install/--upgrade, and no",
    "upgrade path overwrites this file."
  ],
  "values": {
    "OPERATOR_NAME": "",
    "SMTP_ACCOUNT": ""
  },
  "refs": {}
}
JSON
  echo "created project-owned file: $IDENTITY_REL"
}

# Render the incoming kit source with this project's identity, then point SRC_ROOT at
# the rendered copy so every downstream copy/compare works on it unchanged.
apply_identity() {
  local identity="$TARGET_DIR/$IDENTITY_REL"
  [[ -f "$identity" ]] || return 0

  if ! have_python; then
    echo "WARN: python3 not found — {{TOKEN}} slots left unfilled; the Start Gate will"
    echo "      stop agents until they are filled by hand."
    return 0
  fi

  local dir
  dir="$(mktemp -d)"
  # Copy without .git: the source may be a full checkout of this repository.
  if ! (cd "$SRC_ROOT" && tar -cf - --exclude=./.git . 2>/dev/null) | (cd "$dir" && tar -xf -); then
    rm -rf "$dir"
    echo "WARN: could not stage kit source for substitution; slots left unfilled."
    return 0
  fi

  local applied
  if ! applied="$(python3 - "$identity" "$dir" <<'PY'
import json, os, sys

identity_path, root = sys.argv[1:3]
try:
    with open(identity_path, encoding="utf-8") as fh:
        data = json.load(fh)
except Exception:
    sys.exit(1)
if not isinstance(data, dict):
    sys.exit(1)

tokens = {}
for section in ("values", "refs"):
    part = data.get(section)
    if isinstance(part, dict):
        for key, value in part.items():
            if isinstance(key, str) and isinstance(value, str) and key and value:
                tokens["{{%s}}" % key] = value

count = 0
if tokens:
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = [d for d in dirnames if d != ".git"]
        for name in filenames:
            path = os.path.join(dirpath, name)
            if os.path.islink(path):
                continue
            try:
                with open(path, encoding="utf-8") as fh:
                    text = fh.read()
            except (UnicodeDecodeError, OSError):
                continue  # binary (icons) or unreadable: never rewritten
            new = text
            for token, value in tokens.items():
                if token in new:
                    count += new.count(token)
                    new = new.replace(token, value)
            if new != text:
                with open(path, "w", encoding="utf-8") as fh:
                    fh.write(new)
print("%d %d" % (len(tokens), count))
PY
  )"; then
    rm -rf "$dir"
    echo "WARN: $IDENTITY_REL is unreadable or not valid JSON; slots left unfilled."
    return 0
  fi

  local declared="${applied%% *}" substituted="${applied##* }"
  if [[ "$substituted" == "0" ]]; then
    rm -rf "$dir"
    if [[ "$declared" != "0" ]]; then
      echo "note: $IDENTITY_REL declares $declared token(s), none present in this kit version."
    fi
    return 0
  fi

  RENDER_DIR="$dir"
  SRC_ROOT="$dir"
  echo "applied operator identity from $IDENTITY_REL: $substituted substitution(s)"
}

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

# Self-contained ignore rules: manifest.json and identity.json stay TRACKED so a team
# sharing the checkout judges file ownership from the same baseline and gets the same
# {{TOKEN}} values, while the credential half and the backups never reach git. Kept
# inside .gk/ so the installer never has to edit the project's own .gitignore.
write_gk_gitignore() {
  mkdir -p "$TARGET_DIR/$STATE_DIR"
  cat > "$TARGET_DIR/$STATE_DIR/.gitignore" <<'IGN'
# Managed by the AI-Agents installer.
# manifest.json and identity.json are intentionally NOT ignored — the team shares them.
# Never put a secret in identity.json: use "refs" to point at a local credential file.
secrets.json
overwritten/
pre-upgrade/
pre-migrate/
IGN
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
    # A preserved file on disk is the PROJECT's version, not the kit's. Recording its
    # hash would tell the next upgrade "untouched kit content, safe to replace" — the
    # exact loss this protection exists to prevent. Skipping leaves the previous entry
    # (or no entry) in place, so the file stays drifted until a human merges it.
    if [[ ${#DRIFTED[@]} -gt 0 ]] && printf '%s\n' "${DRIFTED[@]}" | grep -qxF -- "$rel"; then
      continue
    fi
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
  write_gk_gitignore

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
  if [[ ${#DRIFTED[@]} -gt 0 ]]; then
    echo
    echo "Kept ${#DRIFTED[@]} protected file(s) that differ from what the kit installed."
    echo "The kit did NOT replace them; the new version is beside each one:"
    local p
    for p in "${DRIFTED[@]}"; do
      echo "  kept: $p"
      echo "        review with: diff -u $p $p.kit-new"
    done
    echo "  Move any lasting project rule into docs/project-rules.md, which no"
    echo "  upgrade touches, then adopt the .kit-new version and delete it."
  fi
  if [[ ${#BACKED_UP[@]} -gt 0 ]]; then
    echo
    echo "Backed up ${#BACKED_UP[@]} replaced file(s) under $STATE_DIR/pre-upgrade/."
  fi
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

# Read-only answer to "is it safe to upgrade?". Writes nothing, ever — which is why
# it can live outside the operator-approval gate that a real upgrade sits behind.
check_drift() {
  echo "Drift report for: $TARGET_DIR"
  echo "(read-only — nothing is written)"
  load_manifest

  if [[ ! -f "$TARGET_DIR/$MANIFEST_REL" ]]; then
    echo "  note: no $MANIFEST_REL — this install predates it."
  elif [[ ${#KIT_HASHES[@]} -eq 0 ]]; then
    echo "  note: $MANIFEST_REL is unreadable or empty (no python3? backfilled empty?)."
  fi
  echo

  # Pass 1 — the root files, judged by the same rules copy_file_replace applies.
  # These are walked EXPLICITLY rather than read off the manifest: a protected file
  # that the manifest never recorded is exactly the case the upgrade fails closed on,
  # and reading only the manifest would report it as "no drift" while the upgrade
  # preserves it. That mismatch was a real bug found across 20 real targets.
  local rel recorded kept=0 replaced=0 untracked=0
  for rel in "${KIT_ROOT_FILES[@]}"; do
    [[ -f "$TARGET_DIR/$rel" ]] || continue
    recorded="${KIT_HASHES[$rel]-}"

    # Same short-circuit copy_file_replace applies: identical to the incoming version
    # (rendered with this project's identity) means no drift, manifest or not. Without
    # it the report and the upgrade would disagree again — the bug this pass was
    # rewritten to fix.
    if [[ -f "$SRC_ROOT/$rel" && "$(file_sha256 "$TARGET_DIR/$rel")" == "$(file_sha256 "$SRC_ROOT/$rel")" ]]; then
      continue
    fi

    if [[ -n "$recorded" && "$recorded" == "$(file_sha256 "$TARGET_DIR/$rel")" ]]; then
      continue
    fi

    if is_protected "$rel"; then
      kept=$((kept + 1))
      if [[ -z "$recorded" ]]; then
        echo "  KEPT (not in manifest, provenance unknown -> fail closed): $rel"
      else
        echo "  KEPT (differs from what the kit installed): $rel"
      fi
      echo "       upgrade writes the new version to $rel.kit-new and leaves yours alone"
    elif [[ -z "$recorded" ]]; then
      untracked=$((untracked + 1))
      echo "  REPLACED (not in manifest, no copy stashed): $rel"
    else
      replaced=$((replaced + 1))
      echo "  REPLACED (differs; yours -> $STATE_DIR/overwritten/): $rel"
    fi
  done

  # Pass 2 — everything else the manifest tracks (kit directories, .docs pages).
  local other=0
  while IFS= read -r rel; do
    [[ -n "$rel" ]] || continue
    [[ -f "$TARGET_DIR/$rel" ]] || continue
    is_root_file "$rel" && continue
    [[ "${KIT_HASHES[$rel]}" == "$(file_sha256 "$TARGET_DIR/$rel")" ]] && continue
    other=$((other + 1))
    echo "  REPLACED (differs; yours -> $STATE_DIR/overwritten/): $rel"
  done < <(printf '%s\n' "${!KIT_HASHES[@]}" | sort)

  echo
  echo "Summary: $kept kept (protected), $((replaced + other)) replaced with a stashed copy,"
  echo "         $untracked replaced with no stashed copy (untracked root file)."
  if [[ "$kept" -gt 0 ]]; then
    echo "Run --upgrade to apply; --upgrade --strict exits non-zero while any KEPT file"
    echo "still needs a manual merge."
  fi
  # Every replaced root file is copied to .gk/pre-upgrade/ regardless, so "no stashed
  # copy" means no .gk/overwritten/ entry, not no backup at all.
}

# ── --migrate: separate project content from kit content ──────────────────────
#
# --check says "these files drifted"; --upgrade preserves them and asks for a merge.
# Neither answers the question that actually blocks the operator: WHICH PART of the
# drift is the project's, and where should it live? On 24 real targets the answer was
# 300–800 lines of genuine project rules sitting inside AGENTS.md, plus a handful of
# operator values typed straight over the placeholders.
#
# --migrate answers it mechanically:
#   1. Operator values are read back out of the target, positionally, using the
#      template's own {{TOKEN}} slots as the probe, and stored in .gk/identity.json —
#      so the next upgrade re-applies them instead of burning them. Targets still on
#      the old [TOKEN] spelling are recognised as unfilled, not mistaken for a value.
#   2. A file whose only difference from the rendered template is INSERTED lines is
#      unambiguous: those lines are the project's. They move to docs/project-rules.md
#      and the file returns to the template.
#   3. Anything else — a kit line rewritten or deleted — is NOT unambiguous, so it is
#      reported and left exactly as it is. The kit never guesses what an edit meant.
#
# Writing mode, so it is gated: TTY plus a typed confirmation, with no --yes to skip.
# Everything it can touch is copied to .gk/pre-migrate/ first.
migrate_project_content() {
  echo "Migration (project content out of kit files) for: $TARGET_DIR"

  if ! have_python; then
    echo "ERROR: --migrate needs python3 (diffing and JSON). Install it and re-run." >&2
    exit 2
  fi
  if [[ ! -t 0 ]]; then
    echo "ERROR: --migrate rewrites kit files in the target and requires an interactive" >&2
    echo "       confirmation. There is no non-interactive flag; run it from a terminal." >&2
    exit 3
  fi

  echo
  echo "This rewrites kit-owned files in the target:"
  echo "  - operator values found in them are written to $IDENTITY_REL"
  echo "  - purely added sections move to docs/project-rules.md"
  echo "  - files with rewritten or deleted kit lines are reported and left untouched"
  echo "A copy of every file it can touch is kept in $STATE_DIR/pre-migrate/."
  echo
  local reply=""
  read -r -p "Type 'yes' to proceed: " reply
  if [[ "$reply" != "yes" ]]; then
    echo "Aborted; nothing was written."
    exit 0
  fi

  seed_identity
  seed_project_rules
  write_gk_gitignore

  # Fresh each run, for the same reason pre-upgrade/ is: a backup that accumulates
  # runs no longer identifies a state anyone can return to.
  local backup_root="$TARGET_DIR/$STATE_DIR/pre-migrate"
  rm -rf "$backup_root"

  local rel docs=()
  for rel in "${KIT_ROOT_FILES[@]}"; do
    # Shell scripts are excluded from content migration on purpose: "inserted lines"
    # in a script are code, not a project rule, and moving them into a markdown file
    # would be nonsense. They are still reported when they differ.
    [[ "$rel" == *.sh ]] && continue
    docs+=("$rel")
  done

  for rel in "${KIT_ROOT_FILES[@]}" "docs/project-rules.md" "$IDENTITY_REL"; do
    [[ -f "$TARGET_DIR/$rel" ]] || continue
    mkdir -p "$(dirname "$backup_root/$rel")"
    cp -a "$TARGET_DIR/$rel" "$backup_root/$rel"
  done
  echo "backup written: $STATE_DIR/pre-migrate/"
  echo

  local today
  today="$(date +%Y-%m-%d)"

  # `set -e` would kill the script on a non-zero exit before the report below could
  # explain it, so the status is captured instead.
  local rc=0
  python3 - "$SRC_ROOT" "$TARGET_DIR" "$TARGET_DIR/$IDENTITY_REL" \
            "$TARGET_DIR/docs/project-rules.md" "$today" "${docs[@]}" <<'PY' || rc=$?
import difflib, glob, json, os, re, sys

src_root, target_dir, identity_path, rules_path, today = sys.argv[1:6]
doc_files = sys.argv[6:]

TOKEN_RE = re.compile(r"\{\{([A-Z][A-Z0-9_]*)\}\}")
# A slot the operator never filled — in either the current {{...}} spelling or the
# legacy [...] one. Captured as a "value" it would poison identity.json forever.
UNFILLED_RE = re.compile(r"^(?:\{\{[A-Z][A-Z0-9_]*\}\}|\[[A-Z][A-Z0-9_]*\])$")


def read(path):
    try:
        with open(path, encoding="utf-8") as fh:
            return fh.read()
    except (OSError, UnicodeDecodeError):
        return None


def redact(value):
    # The report can be pasted into an issue or scrolled past in a CI log, and these
    # values are exactly the personal data the placeholder scheme exists to keep out
    # of tracked text. Report the shape, never the value.
    return "%d chars, starts with %r" % (len(value), value[:1])


identity = {"state_version": 1, "values": {}, "refs": {}}
raw = read(identity_path)
if raw and raw.strip():
    try:
        loaded = json.loads(raw)
    except ValueError:
        print("ABORT: %s is not valid JSON. Fix or delete it, then re-run." % identity_path)
        sys.exit(3)
    if isinstance(loaded, dict):
        identity = loaded
values = identity.get("values")
if not isinstance(values, dict):
    values = {}
    identity["values"] = values

declared = {}
for section in ("values", "refs"):
    part = identity.get(section)
    if isinstance(part, dict):
        for key, value in part.items():
            if isinstance(key, str) and isinstance(value, str) and key and value:
                declared[key] = value

# ── 1. read operator values back out of the target ────────────────────────────
probe_files = list(doc_files)
for path in sorted(glob.glob(os.path.join(src_root, ".docs", "agents", "*.md"))):
    probe_files.append(os.path.relpath(path, src_root))

candidates = {}
ambiguous = set()
unfilled = set()

for rel in probe_files:
    template = read(os.path.join(src_root, rel))
    current = read(os.path.join(target_dir, rel))
    if template is None or current is None:
        continue
    current_lines = current.splitlines()
    for line in template.splitlines():
        names = TOKEN_RE.findall(line)
        if not names:
            continue
        # Turn the template line into a probe: everything literal, each slot a lazy
        # capture. A line that matches exactly once in the target tells us, with no
        # guessing, what the operator typed over that slot.
        pattern, last = "", 0
        for match in TOKEN_RE.finditer(line):
            pattern += re.escape(line[last:match.start()]) + "(.+?)"
            last = match.end()
        probe = re.compile("^" + pattern + re.escape(line[last:]) + "$")
        hits = [m for m in (probe.match(l) for l in current_lines) if m]
        if len(hits) != 1:
            ambiguous.update(names)
            continue
        for name, captured in zip(names, hits[0].groups()):
            if UNFILLED_RE.match(captured):
                unfilled.add(name)
            else:
                candidates.setdefault(name, set()).add(captured)

added, conflicts = [], []
for name in sorted(candidates):
    found = candidates[name]
    if len(found) > 1:
        ambiguous.add(name)
        continue
    value = next(iter(found))
    if name in declared:
        if declared[name] != value:
            conflicts.append(name)
        continue
    values[name] = value
    declared[name] = value
    added.append(name)

if added:
    with open(identity_path, "w", encoding="utf-8") as fh:
        json.dump(identity, fh, indent=2, sort_keys=True, ensure_ascii=False)
        fh.write("\n")

print("== operator values ==")
if added:
    for name in added:
        print("  extracted -> identity.json: %s (%s)" % (name, redact(declared[name])))
else:
    print("  nothing new extracted")
for name in sorted(unfilled - set(added)):
    print("  still unfilled (fill it in identity.json): %s" % name)
for name in sorted(conflicts):
    print("  CONFLICT: %s differs between identity.json and the target — kept identity.json" % name)
for name in sorted(ambiguous - set(added)):
    print("  ambiguous (the surrounding line was edited): %s — decide by hand" % name)


def render(text):
    for name, value in declared.items():
        text = text.replace("{{%s}}" % name, value)
    return text


# ── 2. move purely-added content out, report the rest ─────────────────────────
print()
print("== kit files ==")
moved_blocks, needs_human, clean, normalized, respelled = [], [], [], [], []

for rel in doc_files:
    template = read(os.path.join(src_root, rel))
    current = read(os.path.join(target_dir, rel))
    if template is None or current is None:
        continue
    rendered = render(template)

    # A target installed before the delimiter change still carries [TOKEN] where the
    # template now has {{TOKEN}}. That is a spelling difference, not a project edit —
    # reporting it as "a kit line was rewritten, decide by hand" would bury the real
    # finding. Rewrite it here, for THIS template's slot names only, to whatever the
    # rendered template holds: the operator's value, or the unfilled slot if there is
    # none (which keeps the Start Gate honest).
    before = current
    for name in set(TOKEN_RE.findall(template)):
        current = current.replace("[%s]" % name, declared.get(name, "{{%s}}" % name))
    if current != before:
        respelled.append(rel)

    if rendered == current:
        clean.append(rel)
        if current != before:
            with open(os.path.join(target_dir, rel), "w", encoding="utf-8") as fh:
                fh.write(current)
        continue

    a = rendered.splitlines(keepends=True)
    b = current.splitlines(keepends=True)
    inserted, blocking = [], set()
    for tag, _i1, _i2, j1, j2 in difflib.SequenceMatcher(None, a, b, autojunk=False).get_opcodes():
        if tag == "equal":
            continue
        if tag == "insert":
            inserted.append("".join(b[j1:j2]))
        else:
            blocking.add(tag)  # "replace": a kit line was rewritten; "delete": removed
    if blocking:
        needs_human.append((rel, sorted(blocking)))
        continue

    blocks = [block for block in inserted if block.strip()]
    with open(os.path.join(target_dir, rel), "w", encoding="utf-8") as fh:
        fh.write(rendered)
    if blocks:
        moved_blocks.append((rel, blocks))
    else:
        normalized.append(rel)

if moved_blocks:
    with open(rules_path, "a", encoding="utf-8") as fh:
        for rel, blocks in moved_blocks:
            fh.write("\n\n## Migrado de `%s` em %s\n\n" % (rel, today))
            fh.write(
                "Movido por `install-agents-kit.sh --migrate`: estas linhas foram "
                "acrescentadas ao arquivo do kit por este projeto. Revise, edite e "
                "remova o que não valer mais — nenhum upgrade toca este arquivo.\n\n"
            )
            for block in blocks:
                if not block.endswith("\n"):
                    block += "\n"
                fh.write(block)
                fh.write("\n")

for rel, blocks in moved_blocks:
    lines = sum(block.count("\n") + 1 for block in blocks)
    print("  MOVED  %s: %d added block(s), ~%d line(s) -> docs/project-rules.md" % (rel, len(blocks), lines))
for rel in normalized:
    print("  RESET  %s: differed only in whitespace; restored to the kit version" % rel)
for rel in respelled:
    print("  RESPELL %s: legacy [TOKEN] slots rewritten to the {{…}} spelling" % rel)
for rel in clean:
    print("  CLEAN  %s: already identical to the kit" % rel)
for rel, tags in needs_human:
    what = " and ".join({"replace": "rewritten kit lines", "delete": "deleted kit lines"}[t] for t in tags)
    print("  MANUAL %s: has %s — left untouched, nothing was moved" % (rel, what))

print()
if needs_human:
    print("%d file(s) need a human before --upgrade is clean." % len(needs_human))
    print("For each: diff it against the kit version, move the project's part into")
    print("docs/project-rules.md by hand, then restore the kit lines.")
else:
    print("No file needs a manual decision. --upgrade should now be a clean replace.")
PY
  if [[ "$rc" -ne 0 ]]; then
    echo
    echo "ERROR: migration aborted (exit $rc); the target is unchanged apart from the" >&2
    echo "       backup under $STATE_DIR/pre-migrate/." >&2
    exit "$rc"
  fi

  echo
  echo "Shell scripts are not content-migrated; run --check to see whether any differ."
  echo "Next: review the changes (git diff), then run --upgrade."
}

# The official home for project-specific rules.
#
# Option B of the issue put this at .docs/agents/project-rules.md, but .docs/ is kit
# territory (sync_dir replaces it); docs/ is the half the installer promises never to
# overwrite. The guarantee here is an absence: this path is deliberately NOT in
# KIT_OWNED_PATHS, so no upgrade path can reach it. Seeded on install and on upgrade,
# because an existing target has no such file and would otherwise never get one.
seed_project_rules() {
  local dst="$TARGET_DIR/docs/project-rules.md"
  [[ -e "$dst" ]] && return 0

  mkdir -p "$TARGET_DIR/docs"
  if [[ -f "$SRC_ROOT/docs/project-rules.md" ]]; then
    cp -a "$SRC_ROOT/docs/project-rules.md" "$dst"
  else
    printf '# Project-Specific Rules\n\nRules that apply to THIS project only. `AGENTS.md` is kit-owned and replaced by\n`install-agents --upgrade`; this file is project-owned and never overwritten.\nWrite project rules here, not in `AGENTS.md`.\n\n- (none yet)\n' \
      > "$dst"
  fi
  echo "created project-owned file: docs/project-rules.md"
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

  # Render the incoming source with this project's operator values BEFORE anything is
  # compared or copied. A filled slot then reads as "identical to the kit", not as
  # drift, so the upgrade neither burns the value nor demands a merge for it.
  seed_identity
  apply_identity

  # The backup holds the state before THIS upgrade; accumulating runs would make
  # "pre-upgrade" mean nothing in particular.
  rm -rf "$TARGET_DIR/$STATE_DIR/pre-upgrade"

  # Root kit files. Project-specific context is supposed to live in
  # .docs/software-overview.md, .docs/limits.md, docs/project-rules.md, handoff,
  # issues, and lessons — but "supposed to" is not a guarantee, so copy_file_replace
  # checks the manifest before it overwrites, and refuses outright for AGENTS.md.
  local root_file
  for root_file in "${KIT_ROOT_FILES[@]}"; do
    copy_file_replace "$root_file"
  done
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

  # An existing target predates docs/project-rules.md and would otherwise never get
  # the destination the AGENTS.md protection points people at.
  seed_project_rules

  # Preserve project-local files/state.
  echo "preserved project-local: .docs/software-overview.md"
  echo "preserved project-local: docs/project-rules.md"
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
  "${KIT_ROOT_FILES[@]}"
  "templates"
  ".docs/agents" ".docs/workflows" ".docs/articles" ".docs/icons"
  ".docs/issues/templates" ".docs/issues/README.md"
  ".docs/index.html" ".docs/concepts.html"
)

if [[ "$CHECK" == "1" ]]; then
  # Render the source the same way an upgrade would, so the report answers the question
  # the operator actually asked ("what would --upgrade do?") rather than a variant of
  # it. seed_identity is deliberately NOT called: --check writes nothing.
  apply_identity
  check_drift
  exit 0
elif [[ "$MIGRATE" == "1" ]]; then
  # Exits here rather than falling through to the readiness gate: migration says
  # nothing about whether the project context is filled in, and failing a freshly
  # migrated target on an unrelated gate would just be noise.
  migrate_project_content
  exit 0
elif [[ "$UPGRADE" == "1" ]]; then
  upgrade_kit
  write_manifest "${KIT_OWNED_PATHS[@]}"
  report_upgrade_effects

  # --strict is for CI: the upgrade already happened and the protected files are
  # already safe; the non-zero exit is how a pipeline learns a human owes a merge.
  if [[ "$STRICT" == "1" && ${#DRIFTED[@]} -gt 0 ]]; then
    echo
    echo "ERROR: --strict — ${#DRIFTED[@]} protected file(s) need a manual merge." >&2
    exit 6
  fi
else
  # An identity file present before a fresh install is honoured; otherwise a starter is
  # seeded (empty, so nothing is substituted and the Start Gate still catches the slots).
  seed_identity
  apply_identity

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
  seed_project_rules
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

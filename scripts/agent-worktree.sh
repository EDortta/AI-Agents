#!/usr/bin/env bash
# AI-Agents kit-owned file. Do not edit: `install-agents-kit.sh --upgrade` replaces it.
# Project-specific rules  -> docs/project-rules.md (never overwritten)
# Operator values ({{…}}) -> .credentials/identity.json (untracked, per-programmer)
#
# agent-worktree (awt) — one git worktree per work_id, for parallel agents.
#
# Why: when two agents (claude-code, codex, cursor) share one working tree they
# step on each other — files, branches, builds and service ports collide. A git
# worktree gives each agent its own directory + branch on the same .git, so they
# run truly in parallel. This helper standardizes the convention the AI-Agents
# kit documents in .docs/workflows/parallel-worktrees.md.
#
# git worktree is native to git, so the isolation works for ANY tool — point
# Codex at one worktree folder, Cursor at another.
#
# Usage:
#   awt install [--bin <dir>]      # symlink this script as `awt` on your PATH
#   awt uninstall [--bin <dir>]    # remove that symlink
#   awt new <work_id> [--branch <b>] [--base <ref>] [--docker]
#   awt list
#   awt ports <work_id>
#   awt rm <work_id> [--force]
#
# Defaults: branch=feature/<work_id>, base=development (falls back to main).
# Conventions: worktrees live at ../<repo>--<work_id>; never touches main/development
# directly; refuses to overwrite an existing worktree unless --force.
#
# Install: `awt` is just this script. Run `./scripts/agent-worktree.sh install`
# once to symlink it as `awt` into ~/.local/bin (override with --bin or
# AWT_BIN_DIR). An external installer (e.g. AI-GovernanceKit) can do the same by
# calling this subcommand, so the kit works both bundled and standalone.
#
set -euo pipefail

# Absolute path to this script, resolving any symlink (so `awt install` records
# the real file, not the link). Computed eagerly; repo lookup is lazy (below) so
# install/uninstall work from anywhere, not only inside a git repo.
SELF="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)/$(basename "$(readlink -f "${BASH_SOURCE[0]}")")"
CRED_STORE="${AWT_CRED_STORE:-$HOME/.config/credentials/personal}"

# AGENTS.md §8a owns this path. The registry says which agents are alive *on this
# machine*, so it belongs in XDG state — never in a replicated directory, where a
# copy would report sessions that were never running on the reader's box.
# `~/Sync/agent-status.json` is the former location, still read when the canonical
# one is absent so an unmigrated machine keeps working.
AWT_STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/ai-agents"
STATUS_FILE="${AWT_STATUS_FILE:-$AWT_STATE_DIR/agent-status.json}"
if [[ -z "${AWT_STATUS_FILE:-}" && ! -f "$STATUS_FILE" && -f "$HOME/Sync/agent-status.json" ]]; then
  STATUS_FILE="$HOME/Sync/agent-status.json"
fi

# Lazily resolve the repo we are invoked from. Only worktree commands need it;
# install/uninstall must run outside any repo.
require_repo() {
  MAIN_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
  if [[ -z "$MAIN_ROOT" ]]; then
    echo "awt: not inside a git repository." >&2
    exit 2
  fi
  REPO_NAME="$(basename "$MAIN_ROOT")"
  PARENT="$(dirname "$MAIN_ROOT")"
}

worktree_path() { echo "$PARENT/${REPO_NAME}--$1"; }

# work_id feeds a filesystem path (worktree_path), a docker compose project
# name (-p awt-$wid) and the generated .env — never pass an unsanitized value
# to any of those. No '/' allowed (unlike branch names), since wid is a single
# path segment, not a ref.
validate_wid() {
  local wid="$1"
  if ! [[ "$wid" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    echo "awt: invalid work_id '$wid' — must match ^[a-zA-Z0-9_-]+\$" >&2
    echo "     no slashes, dots, quotes, spaces or shell metacharacters allowed." >&2
    exit 6
  fi
}

# Deterministic, collision-resistant port offset from the work_id. Same work_id
# always maps to the same ports, so an agent can reconnect to its services.
port_offset() {
  local wid="$1"
  local h
  h="$(printf '%s' "$wid" | cksum | cut -d' ' -f1)"
  echo $(( 100 + (h % 80) * 10 ))   # 100,110,...,890
}

default_base() {
  # Prefer development, then main, else current HEAD.
  for ref in development main; do
    if git show-ref --verify --quiet "refs/heads/$ref" \
       || git show-ref --verify --quiet "refs/remotes/origin/$ref"; then
      echo "$ref"; return
    fi
  done
  git rev-parse --abbrev-ref HEAD
}

# --- materialize per-worktree .env + credential symlinks --------------------
materialize_env() {
  local wt="$1" wid="$2" off="$3"
  # Mirror the central credential store as symlinks (never copy secrets).
  if [[ -d "$CRED_STORE" ]]; then
    mkdir -p "$wt/.credentials"
    ln -sfn "$CRED_STORE" "$wt/.credentials/store"
  fi
  # Seed .env from the repo's example, then append the allocated ports. We keep
  # provider keys out of the file: apps read them from the linked store/env.
  local example=""
  for cand in ".env.example" ".env.sample" ".env.template"; do
    [[ -f "$wt/$cand" ]] && { example="$wt/$cand"; break; }
  done
  {
    [[ -n "$example" ]] && cat "$example"
    echo ""
    echo "# --- awt: per-worktree isolation (work_id=$wid, offset=$off) ---"
    echo "AWT_WORK_ID=$wid"
    echo "AWT_PORT_OFFSET=$off"
    echo "GATEWAY_PORT=$(( 8000 + off ))"
    echo "DB_PORT=$(( 5432 + off ))"
    echo "AIHUB_PORT=9400   # singleton daemon — shared across worktrees, not offset"
  } > "$wt/.env"
}

cmd_new() {
  local wid="" branch="" base="" docker=0
  wid="${1:?usage: awt new <work_id> [--branch b] [--base ref] [--docker]}"; shift || true
  validate_wid "$wid"
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --branch) branch="$2"; shift 2;;
      --base)   base="$2"; shift 2;;
      --docker) docker=1; shift;;
      *) echo "awt: unknown flag '$1'" >&2; exit 2;;
    esac
  done
  branch="${branch:-feature/$wid}"
  base="${base:-$(default_base)}"
  local wt; wt="$(worktree_path "$wid")"
  local off; off="$(port_offset "$wid")"

  if [[ -e "$wt" ]]; then
    echo "awt: worktree already exists: $wt" >&2; exit 5
  fi
  if [[ "$branch" == "main" || "$branch" == "master" || "$branch" == "development" ]]; then
    echo "awt: refusing to use a protected branch ('$branch') for a worktree." >&2; exit 4
  fi
  # Branch names must be plain ASCII in [a-zA-Z0-9/_-]; reject quotes, spaces,
  # shell/glob metacharacters and non-ASCII before touching git (see AGENTS.md
  # "Allowed characters (MANDATORY)"). Never pass an unsanitized name to git.
  if ! [[ "$branch" =~ ^[a-zA-Z0-9/_-]+$ ]]; then
    echo "awt: invalid branch name '$branch' — must match ^[a-zA-Z0-9/_-]+\$" >&2
    echo "     no quotes, spaces, shell metacharacters or non-ASCII allowed." >&2
    exit 6
  fi

  echo "awt: creating worktree $wt"
  echo "     branch=$branch  base=$base  port-offset=$off"
  git -C "$MAIN_ROOT" worktree add -b "$branch" "$wt" "$base"

  materialize_env "$wt" "$wid" "$off"

  # Per-worktree virtualenv (Python repos only). Set AWT_SKIP_VENV=1 to skip
  # (e.g. in tests, or when the agent manages its own environment).
  if [[ "${AWT_SKIP_VENV:-0}" != "1" && ( -f "$wt/pyproject.toml" || -f "$wt/requirements.txt" ) ]]; then
    echo "awt: creating .venv"
    ( cd "$wt" && python3 -m venv .venv \
        && ./.venv/bin/pip -q install -U pip \
        && { [[ -f pyproject.toml ]] && ./.venv/bin/pip -q install -e ".[dev]" \
             || ./.venv/bin/pip -q install -r requirements.txt; } ) \
      || echo "awt: venv setup had issues (continue manually)"
  fi

  if [[ "$docker" == "1" ]]; then
    cmd_docker_up "$wid" "$wt" "$off"
  fi

  echo "awt: ready → cd $wt"
  echo "     point your agent (Codex/Cursor/claude-code) at this folder."
}

cmd_docker_up() {
  local wid="$1" wt="$2" off="$3"
  local compose="$wt/docker-compose.worktree.yml"
  if [[ ! -f "$compose" ]]; then
    echo "awt: no docker-compose.worktree.yml in worktree — skipping docker." >&2
    return 0
  fi
  echo "awt: starting docker (project=$wid) — bind-mount, no image COPY"
  AWT_WORK_ID="$wid" AWT_PORT_OFFSET="$off" GATEWAY_PORT="$(( 8000 + off ))" DB_PORT="$(( 5432 + off ))" \
    docker compose -p "awt-$wid" -f "$compose" up -d
}

cmd_ports() {
  local wid="${1:?usage: awt ports <work_id>}"
  validate_wid "$wid"
  local off; off="$(port_offset "$wid")"
  echo "work_id=$wid  offset=$off"
  echo "  gateway: $(( 8000 + off ))"
  echo "  db:      $(( 5432 + off ))"
  echo "  aihub:   9400 (shared singleton)"
}

cmd_list() {
  echo "== git worktrees =="
  git -C "$MAIN_ROOT" worktree list
  if [[ -f "$STATUS_FILE" ]]; then
    echo ""
    echo "== agent-status.json holders =="
    python3 - "$STATUS_FILE" <<'PY' 2>/dev/null || true
import json, sys
d = json.load(open(sys.argv[1]))
for s in d.get("sessions", []):
    wt = s.get("worktree", "-")
    print(f"  {s.get('agent','?'):12} {s.get('project','?'):28} wt={wt} branch={s.get('branch','-')}")
PY
  fi
}

cmd_rm() {
  local wid="" force=0
  wid="${1:?usage: awt rm <work_id> [--force]}"; shift || true
  validate_wid "$wid"
  [[ "${1:-}" == "--force" ]] && force=1
  local wt; wt="$(worktree_path "$wid")"

  # Tear down docker first (ignore if absent).
  docker compose -p "awt-$wid" down 2>/dev/null || true

  if [[ ! -d "$wt" ]]; then
    echo "awt: no worktree dir at $wt (pruning anyway)"
    git -C "$MAIN_ROOT" worktree prune
    return 0
  fi
  if [[ "$force" == "1" ]]; then
    git -C "$MAIN_ROOT" worktree remove --force "$wt"
  else
    git -C "$MAIN_ROOT" worktree remove "$wt"
  fi
  git -C "$MAIN_ROOT" worktree prune
  echo "awt: removed $wt (branch feature/$wid kept for its PR)"
}

cmd_install() {
  local bin="${AWT_BIN_DIR:-$HOME/.local/bin}"
  [[ "${1:-}" == "--bin" ]] && { bin="$2"; shift 2; }
  mkdir -p "$bin"
  local link="$bin/awt"
  ln -sfn "$SELF" "$link"
  echo "awt: installed → $link -> $SELF"
  case ":$PATH:" in
    *":$bin:"*) ;;
    *) echo "awt: note — '$bin' is not on your PATH. Add it, e.g.:" >&2
       echo "       echo 'export PATH=\"$bin:\$PATH\"' >> ~/.bashrc" >&2;;
  esac
}

cmd_uninstall() {
  local bin="${AWT_BIN_DIR:-$HOME/.local/bin}"
  [[ "${1:-}" == "--bin" ]] && { bin="$2"; shift 2; }
  local link="$bin/awt"
  if [[ -L "$link" ]]; then
    rm -f "$link"; echo "awt: removed $link"
  else
    echo "awt: nothing to remove at $link"
  fi
}

main() {
  local cmd="${1:-}"; shift || true
  case "$cmd" in
    install)   cmd_install "$@";;
    uninstall) cmd_uninstall "$@";;
    new)   require_repo; cmd_new "$@";;
    list)  require_repo; cmd_list "$@";;
    ports) require_repo; cmd_ports "$@";;
    rm)    require_repo; cmd_rm "$@";;
    *) echo "usage: awt {install|uninstall|new|list|ports|rm} ..." >&2; exit 2;;
  esac
}
main "$@"

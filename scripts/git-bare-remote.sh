#!/usr/bin/env bash
# AI-Agents kit-owned file. Do not edit: `install-agents-kit.sh --upgrade` replaces it.
# Project-specific rules  -> docs/project-rules.md (never overwritten)
# Operator values ({{…}}) -> .credentials/identity.json (untracked, per-programmer)
#
# git-bare-remote (gbr) — a self-hosted git remote on a server you already own.
#
# Why: projects that live only on local disk have no versioned backup. Syncthing
# replicating .git/ is not a backup — corrupt the repo and the corruption
# replicates; a wrong `git reset --hard` propagates. And GitHub is not the
# obvious answer for every project: a repo carrying financial data or personal
# system documentation is a real risk decision, one an operator tends to defer —
# leaving the project with no remote at all, which is the worst of both worlds.
#
# Almost every operator already has a server with SSH key access (VPS, homelab,
# the box the app runs on). A bare repo there — no working tree, just objects and
# refs, which is what GitHub hosts underneath — solves it in three commands. What
# was missing is not technology: it is the facility being in the kit, scripted,
# so nobody rediscovers the procedure or hesitates about safety.
#
# When this beats GitHub/GitLab: sensitive data, personal project, a server you
# already run. When it does not: collaboration, CI, pull requests, code review.
#
# Usage:
#   gbr install [--bin <dir>]        # symlink this script as `gbr` on your PATH
#   gbr uninstall [--bin <dir>]
#   gbr status                       # does this project have a remote? in sync?
#   gbr scan                         # run the secret gate alone, push nothing
#   gbr init <user@host> <path> [remote-name] [--force]
#
# `init` is idempotent: run it twice and nothing breaks. It refuses a remote path
# that exists and is not a bare repo.
#
# AUTONOMY (kit rule, restated here on purpose): `init` touches a REMOTE server.
# An agent may prepare and explain these commands; running them requires the
# operator's explicit approval. The script enforces this itself — it always
# prompts, and refuses to run when it cannot reach a terminal (i.e. when driven
# by an agent or a pipeline). There is no --yes flag, by design.
#
set -euo pipefail

SELF="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)/$(basename "$(readlink -f "${BASH_SOURCE[0]}")")"

# $1 = message, $2 = exit code. Note "$1", not "$*": with $* the exit code leaks
# into the printed message.
die() { echo "gbr: $1" >&2; exit "${2:-2}"; }

require_repo() {
  ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
  [[ -n "$ROOT" ]] || die "not inside a git repository." 2
  REPO_NAME="$(basename "$ROOT")"
}

# The remote path feeds an ssh command line. Never pass an unsanitized value.
validate_remote_path() {
  local p="$1"
  [[ "$p" = /* ]] || die "remote path must be absolute (got '$p')." 6
  if [[ "$p" =~ [[:space:]\'\"\`\$\&\;\|\<\>\(\)\{\}\*\?\!] ]]; then
    die "remote path '$p' contains shell metacharacters — refusing." 6
  fi
  [[ "$p" != *".."* ]] || die "remote path '$p' contains '..' — refusing." 6
}

validate_host() {
  local h="$1"
  [[ "$h" =~ ^[a-zA-Z0-9._-]+@[a-zA-Z0-9._-]+$ || "$h" =~ ^[a-zA-Z0-9._-]+$ ]] \
    || die "host '$h' must look like user@host or a ssh_config alias." 6
}

# --- the secret gate -------------------------------------------------------
#
# This is the part that justifies a kit facility instead of a README snippet.
# A remote is irreversible in practice: once the history leaves the machine, it
# has left. .gitignore protects nothing that was already committed yesterday, so
# the scan is over the HISTORY, not the working tree.

SECRET_PATHS=(
  '.env' '.env.*' '*.credentials' '*.credentials.*' 'credentials.conf'
  '*.pem' '*.key' 'id_rsa' 'id_dsa' 'id_ecdsa' 'id_ed25519'
  '*.p12' '*.pfx' '*.keystore' '*.jks'
  '.netrc' '.pgpass' '.htpasswd'
  'secrets.y*ml' '*secret*.json' 'service-account*.json'
)

# Content patterns, matched against the full history. Deliberately narrow: a
# gate that cries wolf gets waved through, which is worse than no gate.
SECRET_CONTENT='(BEGIN [A-Z ]*PRIVATE KEY|aws_secret_access_key|AKIA[0-9A-Z]{16}|ghp_[A-Za-z0-9]{36}|github_pat_[A-Za-z0-9_]{22,}|xox[baprs]-[A-Za-z0-9-]{10,}|sk-[A-Za-z0-9]{32,}|AIza[0-9A-Za-z_-]{35}|-----BEGIN OPENSSH PRIVATE KEY-----)'

scan_history() {
  local findings=0

  echo "gbr: scanning committed history for secrets (not just the working tree)…"

  # 1. Filenames that ever existed in any commit.
  local tracked
  tracked="$(git log --all --pretty=format: --name-only --diff-filter=A | sort -u | sed '/^$/d' || true)"
  local pat hit
  for pat in "${SECRET_PATHS[@]}"; do
    hit="$(printf '%s\n' "$tracked" | grep -iE "(^|/)${pat//\*/[^/]*}$" || true)"
    if [[ -n "$hit" ]]; then
      echo "  [!] secret-shaped file in history: $(printf '%s' "$hit" | tr '\n' ' ')"
      findings=$((findings + 1))
    fi
  done

  # 2. Secret-shaped content in any blob reachable from any ref.
  # The revision list is passed as an array so word splitting is explicit rather than
  # incidental, and the result is read line-by-line: paths may contain spaces.
  local revs=()
  mapfile -t revs < <(git rev-list --all 2>/dev/null | head -300)
  if (( ${#revs[@]} > 0 )); then
    local hits=()
    mapfile -t hits < <(
      git grep -I -l -E "$SECRET_CONTENT" "${revs[@]}" -- 2>/dev/null | head -20 || true
    )
    if (( ${#hits[@]} > 0 )); then
      echo "  [!] secret-shaped content in history:"
      printf '      %s\n' "${hits[@]}"
      findings=$((findings + 1))
    fi
  fi

  if (( findings == 0 )); then
    echo "gbr: no secret-shaped file or content found in history."
    return 0
  fi
  echo ""
  echo "gbr: ${findings} finding(s). A remote is irreversible in practice — once the"
  echo "     history leaves this machine, it has left. Removing the file in a NEW"
  echo "     commit does not help: the old blob is still in the history you push."
  echo "     Rewrite the history (git filter-repo / BFG) and rotate the secret"
  echo "     before pushing, or confirm below that these are false positives."
  return 1
}

# --- confirmation ----------------------------------------------------------
#
# No --yes / --force-yes flag exists anywhere in this script. That is the point:
# the kit prohibits autonomous action against a remote environment, and a flag
# an agent could pass would be exactly the hole the rule exists to close.
confirm() {
  local prompt="$1" answer=""
  if [[ ! -t 0 ]]; then
    die "refusing to continue without a terminal — this step needs the operator's
     explicit confirmation. An agent must not run 'gbr init' on its own; prepare
     the command and hand it to the operator." 3
  fi
  read -r -p "$prompt [type 'yes' to continue] " answer
  [[ "$answer" == "yes" ]] || die "aborted by operator." 3
}

# --- commands --------------------------------------------------------------

cmd_status() {
  require_repo
  echo "repo:   $REPO_NAME ($ROOT)"
  local remotes
  remotes="$(git remote -v | awk '{print $1" "$2}' | sort -u || true)"
  if [[ -z "$remotes" ]]; then
    echo "remote: (none) — this history exists only on this machine."
    echo ""
    echo "        Set one up:  gbr init <user@host> /srv/git/$REPO_NAME.git"
    return 0
  fi
  echo "remote:"
  printf '  %s\n' "$remotes"

  local branch upstream
  branch="$(git rev-parse --abbrev-ref HEAD)"
  upstream="$(git rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' 2>/dev/null || true)"
  if [[ -z "$upstream" ]]; then
    echo "branch: $branch has no upstream — 'git push' has nowhere to go."
    return 0
  fi
  local ahead behind
  ahead="$(git rev-list --count "$upstream..HEAD" 2>/dev/null || echo '?')"
  behind="$(git rev-list --count "HEAD..$upstream" 2>/dev/null || echo '?')"
  echo "branch: $branch → $upstream (ahead $ahead, behind $behind)"
  local dirty
  dirty="$(git status --porcelain | wc -l)"
  echo "tree:   $dirty uncommitted change(s)"
}

cmd_scan() {
  require_repo
  scan_history || exit 1
}

cmd_init() {
  require_repo
  local host="${1:-}" rpath="${2:-}" name="${3:-origin}"
  [[ -n "$host" && -n "$rpath" ]] \
    || die "usage: gbr init <user@host> </abs/path/repo.git> [remote-name]" 2
  [[ "$name" != --* ]] || name="origin"
  validate_host "$host"
  validate_remote_path "$rpath"

  echo "gbr: repo   $REPO_NAME ($ROOT)"
  echo "gbr: target $host:$rpath   (remote name: $name)"
  echo ""

  # --- gate 1: secrets in history
  if ! scan_history; then
    confirm "gbr: push this history anyway, accepting the findings above?"
  fi

  # --- gate 2: is this host really yours?
  echo ""
  echo "gbr: the entire history of '$REPO_NAME' is about to leave this machine"
  echo "     and land on '$host'. Confirm that host is yours and that you accept"
  echo "     whoever else can read it."
  confirm "gbr: is '$host' a server you own and trust?"

  # --- create the bare repo (idempotent)
  echo ""
  echo "gbr: checking $host:$rpath …"
  local state
  state="$(ssh "$host" "
    if [ -d '$rpath' ]; then
      if [ -f '$rpath/HEAD' ] && [ \"\$(git --git-dir='$rpath' rev-parse --is-bare-repository 2>/dev/null)\" = true ]; then
        echo BARE
      else
        echo NOTBARE
      fi
    else
      echo MISSING
    fi
  ")" || die "cannot reach '$host' over ssh." 4

  case "$state" in
    BARE)
      echo "gbr: bare repo already exists — reusing it (idempotent)."
      ;;
    NOTBARE)
      die "'$rpath' exists on $host and is NOT a bare repo.
     Refusing to touch it. Pushing to a repo that has a working tree fails on the
     checked-out branch anyway — that is why the remote must be bare. Pick another
     path, or inspect that one yourself." 5
      ;;
    MISSING)
      echo "gbr: creating bare repo…"
      # 0700: on a shared server the bare repo must not be readable by others —
      # it holds the whole history, which is what we came here to protect.
      # Plain `git init --bare` + chmod, deliberately not `--shared=...`: that
      # flag exists to WIDEN access for a group and sets the setgid bit, which is
      # the opposite of what a private remote wants.
      ssh "$host" "mkdir -p '$(dirname "$rpath")' \
                   && git init --bare '$rpath' >/dev/null \
                   && chmod 700 '$rpath'" \
        || die "could not create '$rpath' on $host." 4
      echo "gbr: created $host:$rpath (mode 700)"
      ;;
  esac

  # --- gate 3: permissions of the remote dir (also checked on reuse)
  local mode
  mode="$(ssh "$host" "stat -c '%a' '$rpath' 2>/dev/null || echo '?'")"
  echo "gbr: remote dir mode: $mode"
  # Judge only the group/other bits. stat reports 4 digits when setgid/sticky is
  # set (a repo created with `git init --shared` reads as 2700), and a gate that
  # cries wolf over a directory that IS private gets waved through — which is
  # worse than no gate.
  if [[ "$mode" != "?" ]]; then
    local go="${mode: -2}"
    if [[ "$go" != "00" ]]; then
      echo "gbr: [!] '$rpath' is mode $mode — others on $host may read this history."
      confirm "gbr: continue with a non-private remote directory?"
    fi
  fi

  # --- wire the remote (idempotent)
  local url="$host:$rpath"
  if git remote get-url "$name" >/dev/null 2>&1; then
    local cur; cur="$(git remote get-url "$name")"
    if [[ "$cur" == "$url" ]]; then
      echo "gbr: remote '$name' already points at $url"
    else
      die "remote '$name' already exists and points at '$cur'.
     Refusing to repoint it silently — that would redirect your pushes. Remove it
     yourself (git remote remove $name) or pass another remote name." 5
    fi
  else
    git remote add "$name" "$url"
    echo "gbr: added remote '$name' → $url"
  fi

  # --- first push
  local branch; branch="$(git rev-parse --abbrev-ref HEAD)"
  echo ""
  echo "gbr: pushing branch '$branch' and tags to '$name'…"
  git push -u "$name" "$branch"
  git push "$name" --tags || echo "gbr: (no tags to push)"

  echo ""
  echo "gbr: done. Clone it back with:  git clone $url"
  cmd_status
}

cmd_install() {
  local bin="${GBR_BIN_DIR:-$HOME/.local/bin}"
  [[ "${1:-}" == "--bin" ]] && { bin="$2"; shift 2; }
  mkdir -p "$bin"
  ln -sfn "$SELF" "$bin/gbr"
  echo "gbr: installed → $bin/gbr -> $SELF"
  case ":$PATH:" in
    *":$bin:"*) ;;
    *) echo "gbr: note — '$bin' is not on your PATH." >&2;;
  esac
}

cmd_uninstall() {
  local bin="${GBR_BIN_DIR:-$HOME/.local/bin}"
  [[ "${1:-}" == "--bin" ]] && { bin="$2"; shift 2; }
  if [[ -L "$bin/gbr" ]]; then
    rm -f "$bin/gbr"; echo "gbr: removed $bin/gbr"
  else
    echo "gbr: nothing to remove at $bin/gbr"
  fi
}

main() {
  local cmd="${1:-}"; shift || true
  case "$cmd" in
    install)   cmd_install "$@";;
    uninstall) cmd_uninstall "$@";;
    status)    cmd_status "$@";;
    scan)      cmd_scan "$@";;
    init)      cmd_init "$@";;
    *) echo "usage: gbr {install|uninstall|status|scan|init} ..." >&2
       echo "       gbr init <user@host> </abs/path/repo.git> [remote-name]" >&2
       exit 2;;
  esac
}
main "$@"

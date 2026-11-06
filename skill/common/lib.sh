#!/bin/bash
# Shared settings for the gh-loops scripts. Sourced, not run.
#   REPO        owner/name of the GitHub repository (default: the current checkout's)
#   MAINTAINER  login allowed to approve work, e.g. `ready` on issues (default: the repository owner)
# A project can set both in .gh-loops.env at its root (shell syntax); environment variables win.
set -uo pipefail
GH_LOOPS_MARKER='<!-- gh-loops -->'
ISSUE_LOOP_LABELS=(ready in-progress needs-answer done)

gh_loops_root() { git rev-parse --show-toplevel 2>/dev/null; }

gh_loops_init() {
  local root; root=$(gh_loops_root) || { echo "not inside a git checkout" >&2; return 3; }
  cd "$root" || return 3
  local env_repo=${REPO:-} env_maintainer=${MAINTAINER:-}
  # shellcheck disable=SC1091
  [[ -f .gh-loops.env ]] && source .gh-loops.env
  REPO=${env_repo:-${REPO:-}}
  MAINTAINER=${env_maintainer:-${MAINTAINER:-}}
  if [[ -z $REPO ]]; then
    REPO=$(gh repo view --json nameWithOwner --jq .nameWithOwner 2>/dev/null) || { echo "cannot find the GitHub repository" >&2; return 3; }
  fi
  [[ -n $MAINTAINER ]] || MAINTAINER=${REPO%%/*}
  export REPO MAINTAINER
}

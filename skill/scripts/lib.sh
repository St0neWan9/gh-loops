#!/bin/bash
# Shared settings for the issue-loop scripts. Sourced, not run.
#   REPO        owner/name of the GitHub repository (default: the current checkout's)
#   MAINTAINER  login allowed to approve issues with `ready` (default: the repository owner)
# A project can set both in .issue-loop.env at its root (shell syntax); environment variables win.
set -uo pipefail
ISSUE_LOOP_MARKER='<!-- issue-loop -->'
ISSUE_LOOP_LABELS=(ready in-progress needs-answer done)

issue_loop_root() { git rev-parse --show-toplevel 2>/dev/null; }

issue_loop_init() {
  local root; root=$(issue_loop_root) || { echo "not inside a git checkout" >&2; return 3; }
  cd "$root" || return 3
  local env_repo=${REPO:-} env_maintainer=${MAINTAINER:-}
  # shellcheck disable=SC1091
  [[ -f .issue-loop.env ]] && source .issue-loop.env
  REPO=${env_repo:-${REPO:-}}
  MAINTAINER=${env_maintainer:-${MAINTAINER:-}}
  if [[ -z $REPO ]]; then
    REPO=$(gh repo view --json nameWithOwner --jq .nameWithOwner 2>/dev/null) || { echo "cannot find the GitHub repository" >&2; return 3; }
  fi
  [[ -n $MAINTAINER ]] || MAINTAINER=${REPO%%/*}
  export REPO MAINTAINER
}

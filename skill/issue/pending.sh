#!/bin/bash
# pending.sh — one line per issue that needs the agent; nothing when idle.
#   READY #N …        the maintainer applied `ready` (the agent still runs check-ready.sh)
#   ANSWERED #N …     a `needs-answer` issue whose last comment is not the agent's (no marker)
#   IN-PROGRESS #N …  left `in-progress` (an interrupted pass)
# Exit 0: checked (output may be empty). 2: the default branch fails check-merge.sh (stop and
# tell the user). 3: GitHub or the repository unreachable (transient).
# ISSUES_JSON=<file> replaces the GitHub query (tests). GH_LOOPS_SKIP_GATE=1 skips the merge gate.
dir=$(cd "$(dirname "$0")" && pwd)
source "$dir/../common/lib.sh"

if [[ -z ${ISSUES_JSON:-} ]]; then
  gh_loops_init || exit 3
  # The merge gate fetches the default branch, the slow part of a poll; the watcher runs it every
  # few polls (GH_LOOPS_SKIP_GATE=1 skips it on the others).
  if [[ ${GH_LOOPS_SKIP_GATE:-} != 1 ]]; then
    if ! out=$("$dir/../common/check-merge.sh" main 2>&1); then echo "BLOCKED $out"; exit 2; fi
  fi
  issues=$(gh issue list -R "$REPO" --state open --limit 100 --json number,title,labels,comments) || exit 3
else
  issues=$(cat "$ISSUES_JSON")
fi

jq -r --arg m "$GH_LOOPS_MARKER" '
  .[] | [.labels[].name] as $l
  | if ($l | index("in-progress")) then "IN-PROGRESS #\(.number) \(.title)"
    elif ($l | index("ready")) then "READY #\(.number) \(.title)"
    elif ($l | index("needs-answer")) and (.comments | length) > 0
         and ((.comments[-1].body | contains($m)) | not) then "ANSWERED #\(.number) \(.title)"
    else empty end' <<<"$issues" || exit 3

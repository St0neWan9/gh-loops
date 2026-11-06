#!/bin/bash
# claim.sh <N>            mark issue N as being handled by this checkout (a local file under .git)
# claim.sh --release <N>  drop the claim
# A claimed `in-progress` issue is not reported by pending.sh for CLAIM_TTL seconds (default
# 7200), so a watcher restarted while a pass runs does not report it again. If the agent dies,
# the claim expires and the issue is reported as IN-PROGRESS again.
source "$(dirname "$0")/../common/lib.sh"
action=claim
[[ ${1:-} == --release ]] && { action=release; shift; }
N=${1:?usage: claim.sh [--release] <issue number>}
root=$(gh_loops_root) || { echo "not inside a git checkout" >&2; exit 3; }
dir=$(git -C "$root" rev-parse --git-dir)/gh-loops
if [[ $action == release ]]; then rm -f "$dir/claim-$N"; echo "released #$N"; else
  mkdir -p "$dir" && date +%s > "$dir/claim-$N" && echo "claimed #$N"
fi

#!/bin/bash
# claim.sh <N>            mark issue N as being handled by this checkout (a local file under .git)
# claim.sh --touch <N>    refresh it: the agent runs this while it keeps working on the issue
# claim.sh --release <N>  drop the claim
# A claimed `in-progress` issue is not reported by pending.sh until the claim is older than
# GH_LOOPS_CLAIM_TTL seconds (default 1800). Touch it after each meaningful step, and release it
# when the pass ends; a claim left untouched (the agent stopped, or was interrupted) goes stale and
# the issue is reported again as IN-PROGRESS.
source "$(dirname "$0")/../common/lib.sh"
action=claim
case ${1:-} in --release) action=release; shift;; --touch) action=touch; shift;; esac
N=${1:?usage: claim.sh [--release] <issue number>}
root=$(gh_loops_root) || { echo "not inside a git checkout" >&2; exit 3; }
dir=$(git -C "$root" rev-parse --git-dir)/gh-loops
if [[ $action == release ]]; then rm -f "$dir/claim-$N"; echo "released #$N"
elif [[ $action == touch ]]; then mkdir -p "$dir" && date +%s > "$dir/claim-$N" && echo "touched #$N"
else
  mkdir -p "$dir" && date +%s > "$dir/claim-$N" && echo "claimed #$N"
fi

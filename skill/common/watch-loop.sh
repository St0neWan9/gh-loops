#!/bin/bash
# watch-loop.sh <pending script> [seconds, default 600]
# Runs the loop's pending script every interval in the shell and exits only when it reports work
# (prints its lines, exit 0) or the default branch is blocked (exit 2). Other failures (network)
# are retried. Started in the background, it wakes the agent only when it exits, so idle polling
# costs no model tokens. Each loop has a thin watch.sh that calls this.
pending=${1:?usage: watch-loop.sh <pending script> [seconds]}
interval=${2:-600}
# The merge gate (a git fetch) runs every this many polls; the other polls only list issues.
gate_every=${GH_LOOPS_GATE_EVERY:-10}
poll=0
while true; do
  poll=$((poll + 1))
  if (( poll % gate_every == 0 )); then out=$("$pending"); else out=$(GH_LOOPS_SKIP_GATE=1 "$pending"); fi
  code=$?
  if [[ $code == 0 && -n $out ]]; then echo "$out"; exit 0; fi
  if [[ $code == 2 ]]; then echo "$out"; exit 2; fi
  sleep "$interval"
done

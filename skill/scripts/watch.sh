#!/bin/bash
# watch.sh [seconds, default 600] — runs pending.sh every interval in the shell and exits only
# when there is work (prints pending.sh's lines, exit 0) or the default branch is blocked
# (exit 2). Network errors are retried. Start it in the background: the agent is woken only
# when it exits, so idle polling costs no model tokens.
interval=${1:-600}
dir=$(cd "$(dirname "$0")" && pwd)
while true; do
  out=$("$dir/pending.sh"); code=$?
  if [[ $code == 0 && -n $out ]]; then echo "$out"; exit 0; fi
  if [[ $code == 2 ]]; then echo "$out"; exit 2; fi
  sleep "$interval"
done

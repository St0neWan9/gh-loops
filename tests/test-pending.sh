#!/bin/bash
# Checks pending.sh's filter against tests/fixture-issues.json (no network).
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
got=$(ISSUES_JSON="$here/fixture-issues.json" "$here/../skill/issue/pending.sh")
want=$'READY #7 Ready issue\nANSWERED #9 Answered\nIN-PROGRESS #10 Interrupted'
if [[ $got == "$want" ]]; then echo "ok"; else printf 'FAIL\n--- got\n%s\n--- want\n%s\n' "$got" "$want"; exit 1; fi

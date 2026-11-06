#!/bin/bash
# setup-labels.sh — creates the four workflow labels in the repository if they are missing.
source "$(dirname "$0")/lib.sh"
issue_loop_init || exit 3
existing=$(gh label list -R "$REPO" --limit 200 --json name --jq '.[].name') || exit 3
create() {
  grep -qx "$1" <<<"$existing" && return
  gh label create "$1" -R "$REPO" --color "$2" --description "$3" >/dev/null && echo "created $1"
}
create ready 0E8A16 "Approved by the maintainer for the issue loop"
create in-progress FBCA04 "Being developed by the issue loop"
create needs-answer D93F0B "The issue loop asked a question"
create done 5319E7 "Merged and closed by the issue loop"
echo "labels ok in $REPO"

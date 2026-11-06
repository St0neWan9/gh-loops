#!/bin/bash
# setup-labels.sh — creates the four workflow labels in the repository if they are missing.
source "$(dirname "$0")/../common/lib.sh"
gh_loops_init || exit 3
existing=$(gh label list -R "$REPO" --limit 200 --json name --jq '.[].name') || exit 3
create() {
  grep -qx "$1" <<<"$existing" && return
  gh label create "$1" -R "$REPO" --color "$2" --description "$3" >/dev/null && echo "created $1"
}
create ready 0E8A16 "Approved by the maintainer for gh-loops issues"
create in-progress FBCA04 "Being developed by gh-loops"
create needs-answer D93F0B "gh-loops asked a question"
create done 5319E7 "Merged and closed by gh-loops"
echo "labels ok in $REPO"

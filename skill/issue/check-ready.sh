#!/bin/bash
# check-ready.sh <issue number>
# Exit 0 and print the time `ready` was applied only when:
#   1. the issue is open and carries the `ready` label;
#   2. the most recent `ready` labeling was done by the maintainer;
#   3. nobody but the maintainer edited the title or body after that.
# Anything else exits 1 with the reason. Fails closed on API errors.
source "$(dirname "$0")/../common/lib.sh"
N=${1:?usage: check-ready.sh <issue number>}
fail() { echo "NOT READY #$N: $*"; exit 1; }
gh_loops_init || fail "no repository"

issue=$(gh api "repos/$REPO/issues/$N") || fail "cannot read the issue"
[[ $(jq -r '.state' <<<"$issue") == open ]] || fail "issue is not open"
jq -e '.pull_request == null' <<<"$issue" >/dev/null || fail "this is a pull request, not an issue"
jq -e '[.labels[].name] | index("ready")' <<<"$issue" >/dev/null || fail "no ready label"

timeline=$(gh api --paginate "repos/$REPO/issues/$N/timeline" | jq -s 'add') || fail "cannot read the timeline"
last=$(jq -c '[.[] | select(.event == "labeled" and .label.name == "ready")] | last' <<<"$timeline")
[[ $last != null ]] || fail "no labeled event for ready"
actor=$(jq -r '.actor.login' <<<"$last")
at=$(jq -r '.created_at' <<<"$last")
[[ $actor == "$MAINTAINER" ]] || fail "ready was applied by $actor, not $MAINTAINER"

renamed=$(jq -r --arg t "$at" --arg o "$MAINTAINER" \
  '[.[] | select(.event == "renamed" and .created_at > $t and .actor.login != $o) | .actor.login] | join(",")' <<<"$timeline")
[[ -z $renamed ]] || fail "title changed after approval by $renamed"

edits=$(gh api graphql -F owner="${REPO%/*}" -F name="${REPO#*/}" -F n="$N" -f query='
  query($owner: String!, $name: String!, $n: Int!) {
    repository(owner: $owner, name: $name) {
      issue(number: $n) { userContentEdits(last: 100) { nodes { editedAt editor { login } } } }
    }
  }') || fail "cannot read the edit history"
editors=$(jq -r --arg t "$at" --arg o "$MAINTAINER" \
  '[.data.repository.issue.userContentEdits.nodes[] | select(.editedAt > $t and (.editor.login // "ghost") != $o) | (.editor.login // "ghost")] | unique | join(",")' <<<"$edits")
[[ -z $editors ]] || fail "body edited after approval by $editors"

echo "READY #$N approved by $MAINTAINER at $at"

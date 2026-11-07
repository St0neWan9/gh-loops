#!/bin/bash
# check-merge.sh <pr number>   — before merging a pull request
# check-merge.sh main          — the default branch as it is now
# Fails (exit 1) when, in the tree that would land on the default branch:
#   - any file under .github/ names the `ready` label (an issue template's `labels:` applies
#     its labels to everyone who uses it, so `ready` there would let anyone approve issues);
#   - for a PR: the PR changes anything under .github/ (templates, workflows, CODEOWNERS):
#     those need the maintainer, never an automatic merge.
# Fails closed on errors.
source "$(dirname "$0")/../common/lib.sh"
target=${1:?usage: check-merge.sh <pr number> | main}
fail() { echo "DO NOT MERGE ($target): $*"; exit 1; }
# GitHub drops a request now and then (EOF on api.github.com). A watcher polls for hours, so a
# single hiccup must not read as "the default branch is bad" and stop it: retry the network calls,
# then fail closed.
retry() { local n=0; until "$@"; do n=$((n + 1)); ((n < 3)) || return 1; sleep 2; done; }
default_branch() { gh repo view "$REPO" --json defaultBranchRef --jq .defaultBranchRef.name; }
gh_loops_init || fail "no repository"

if [[ $target == main ]]; then
  branch=$(retry default_branch) || fail "cannot read the default branch"
  retry git fetch -q origin "$branch" || fail "cannot fetch $branch"
  ref=origin/$branch
else
  git fetch -q origin "pull/$target/head:refs/gh-loops/pr-$target" --force || fail "cannot fetch the PR head"
  ref=refs/gh-loops/pr-$target
  changed=$(gh pr diff "$target" --repo "$REPO" --name-only) || fail "cannot list the PR's files"
  github_changes=$(grep -E '^\.github/' <<<"$changed" || true)
  [[ -z $github_changes ]] || fail "changes under .github/ need the maintainer: $(tr '\n' ' ' <<<"$github_changes")"
fi

hits=""
while IFS= read -r path; do
  [[ -n $path ]] || continue
  if git show "$ref:$path" 2>/dev/null | grep -qiwE 'ready'; then hits+="$path "; fi
done < <(git ls-tree -r --name-only "$ref" -- .github 2>/dev/null)
[[ -z $hits ]] || fail "the ready label appears in: $hits"

[[ $target == main ]] || git update-ref -d "$ref"
echo "OK ($target): no ready label under .github/"

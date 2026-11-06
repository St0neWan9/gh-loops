#!/bin/bash
# check-merge.sh <pr number>   — before merging a pull request
# check-merge.sh main          — the default branch as it is now
# Fails (exit 1) when, in the tree that would land on the default branch:
#   - any file under .github/ names the `ready` label (an issue template's `labels:` applies
#     its labels to everyone who uses it, so `ready` there would let anyone approve issues);
#   - for a PR: the PR changes anything under .github/ (templates, workflows, CODEOWNERS):
#     those need the maintainer, never an automatic merge.
# Fails closed on errors.
source "$(dirname "$0")/lib.sh"
target=${1:?usage: check-merge.sh <pr number> | main}
fail() { echo "DO NOT MERGE ($target): $*"; exit 1; }
issue_loop_init || fail "no repository"

if [[ $target == main ]]; then
  branch=$(gh repo view "$REPO" --json defaultBranchRef --jq .defaultBranchRef.name) || fail "cannot read the default branch"
  git fetch -q origin "$branch" || fail "cannot fetch $branch"
  ref=origin/$branch
else
  git fetch -q origin "pull/$target/head:refs/issue-loop/pr-$target" --force || fail "cannot fetch the PR head"
  ref=refs/issue-loop/pr-$target
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

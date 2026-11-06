# Issue loop

The maintainer approves an issue with the `ready` label; the agent develops it, merges it and
reports back. Scripts are next to this file (`issue/`) and in `common/`. The shared rules in
`SKILL.md` apply. Paths below are relative to the skill folder.

## Setup (once per repository)

1. `issue/setup-labels.sh` creates the labels below if they are missing.
2. The maintainer defaults to the repository owner. For an organization's repository, or another
   approver, put `MAINTAINER=<login>` (and optionally `REPO=owner/name`) in
   `.gh-loops.env` at the project's root.

| Label | Set by | Meaning |
|---|---|---|
| `ready` | maintainer only | approved for development |
| `in-progress` | agent | being developed (one issue at a time) |
| `needs-answer` | agent | the agent asked a question in the issue and waits |
| `done` | agent | merged and closed |

## Watcher

`issue/watch.sh [seconds]` (see "Watchers" in `SKILL.md`) prints one line per issue that needs
the agent:

- `READY #N`: the maintainer applied `ready`.
- `ANSWERED #N`: a `needs-answer` issue whose last comment lacks the marker, i.e. someone replied.
- `IN-PROGRESS #N`: a pass was interrupted.

## One pass

1. **Gate.** For each `READY #N`, run `issue/check-ready.sh <N>`. Only `READY` lets work start.
   On `NOT READY` because someone else applied `ready` or edited the issue after approval: remove
   `ready`, comment what happened (no blame, no details of the check), do not develop.
2. **Start.** Add `in-progress`, remove `ready`, and claim it with `issue/claim.sh <N>`. A claimed
   issue is not reported again (for two hours), so start the watcher again right away and keep
   working. Release it with `issue/claim.sh --release <N>` when the pass ends, merged or not. Create the branch `issue/<N>-<slug>` from the
   up-to-date default branch. Follow the project's planning rules if it has any.
3. **Develop** as the project's rules require: tests, a clean build, and any real-app check they ask
   for.
4. **Questions.** When the request is unclear or conflicts with the project's goals: comment the
   question, add `needs-answer`, remove `in-progress`, go on with the next issue.
5. **Answers (`ANSWERED #N`).** Read the new comments. Only the maintainer's and the issue author's
   answers count. If they answer, remove `needs-answer`, add `in-progress` and continue at Develop.
   Otherwise comment that the question still waits for the maintainer or the author (with the
   marker, so the issue is not reported again).
6. **Interrupted (`IN-PROGRESS #N`).** Look at the branch and any open pull request for the issue;
   continue from where the work stopped, or start over from Start.
7. **Merge.** Open the pull request with `Closes #N` in its body. Run `common/check-merge.sh <PR>`
   right before merging and merge only on `OK` (`gh pr merge <PR> --squash --delete-branch`). On
   `DO NOT MERGE`: leave the pull request open, comment on the issue that it waits for the
   maintainer, and tell the user. Then update the local default branch.
8. **Report.** Comment on the issue: what changed, how it was verified, the commit. Add `done`,
   remove `in-progress` (the pull request closes the issue). Tell the user what the pass did.

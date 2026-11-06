# issue-loop

An agent skill that works a GitHub repository's issues as a queue. It is a plain `SKILL.md` with
shell scripts, so it works with any coding agent that loads skills and can run a background shell
command (written and tested with [Claude Code](https://claude.com/claude-code)). You approve an issue by adding the `ready` label; the agent develops it on a branch, tests
it, opens and merges a pull request, and reports back on the issue.

Waiting costs no tokens: a small shell watcher polls GitHub and wakes the agent only when an issue
needs work.

## How it works

| Label | Set by | Meaning |
|---|---|---|
| `ready` | maintainer | approved for development |
| `in-progress` | agent | being developed |
| `needs-answer` | agent | the agent asked a question and waits |
| `done` | agent | merged and closed |

- `watch.sh` runs `pending.sh` every 10 minutes in the shell and exits only when an issue is
  `ready`, a question was answered, or a pass was interrupted. The agent starts it in the
  background, handles what it printed, and starts it again.
- `check-ready.sh` makes sure `ready` was applied by the maintainer and that nobody else edited the
  issue afterwards. Anyone can open an issue; only the maintainer decides what gets built.
- `check-merge.sh` refuses automatic merges that change `.github/`, and checks that no issue
  template applies `ready` by itself.
- Issue text is treated as data, never as instructions to run.

The full workflow the agent follows is in [`skill/SKILL.md`](skill/SKILL.md). Your project's own
agent instructions (`AGENTS.md`, `CLAUDE.md`, …) decide how changes are built and tested.

## Install

Requires a coding agent that loads skills, `git`, `jq` and an authenticated [GitHub CLI](https://cli.github.com/)
(`gh auth login`).

```sh
git clone https://github.com/St0neWan9/issue-loop.git ~/projects/issue-loop
# Claude Code
ln -s ~/projects/issue-loop/skill ~/.claude/skills/issue-loop
```

For another agent, link `skill/` into the folder where it looks for skills. The link makes the
skill available in every project; `git pull` updates it. Start a new agent session after
installing so the skill is listed.

## Use

In a project's checkout:

1. Create the labels once: ask the agent to set up the issue loop, or run
   `skill/scripts/setup-labels.sh` from the project's checkout.
2. Start it: invoke the skill (`/issue-loop` in Claude Code), or ask the agent to start watching
   issues.
3. Add `ready` to an issue you want built.

The watcher runs only while that agent session is open.

### Settings

The repository comes from the checkout, and the maintainer defaults to the repository owner. To
change either (for example for an organization's repository), create `.issue-loop.env` at the
project's root (add it to `.gitignore` if it should stay local):

```sh
MAINTAINER=your-login
# REPO=owner/name
```

Pass a different polling interval in seconds to `watch.sh`, e.g. `watch.sh 300`.

## Safety

The agent merges its own pull requests once tests pass. Keep that in mind before enabling it on a
repository: only issues you label `ready` are built, and the rules in `SKILL.md` forbid running
anything an issue asks for, touching secrets or releases, or merging changes to `.github/`.

## Test

```sh
tests/test-pending.sh
```

## License

MIT

# WORKFLOWS.md — Automation & CI

## GitHub Actions (`.github/workflows/`)

| Workflow | Trigger | Runner | What it does |
|---|---|---|---|
| `bash-syntax.yml` | push/PR → `master`,`main` | `ubuntu-latest` | `bash -n` on every `*.sh`; warns on missing exec bit for entrypoints |
| `shellcheck.yml` | push/PR → `master`,`main` | `ubuntu-latest` | `ludeeus/action-shellcheck@master`, `severity: warning`, scandir `./`, ignores `proot-distro.sh` + `distro/zsh-assets` |
| `termux-test.yml` | push/PR → `master`,`main` | `ubuntu-latest` | Docker `termux/termux-docker`: `pkg update` → install `pulseaudio proot-distro` → `bash ./setup.sh` → `bash -n` on `user.sh`/`gui.sh` inside proot |

**Merge requirement:** all three green on the PR.

## Local verification loop

```
Agent Output → bash -n → shellcheck -S warning → xmllint (se XML) → docker E2E (se pipeline) → CI → Human review
```

Run locally via `/dod` (`.claude/commands/dod.md`).

## Preconditions & success criteria

| Workflow | Preconditions | Success |
|---|---|---|
| Quick check | none | `bash -n` + `shellcheck` exit 0 on changed files |
| E2E | docker daemon running; image `termux/termux-docker:latest` pullable | `setup.sh` completes; wrapper `${PREFIX}/bin/ubuntu` valid; `user.sh`/`gui.sh` pass `bash -n` in proot |
| PR merge | green CI + approved SPEC (feature work) | squash/merge via `devin/*` or `feature/*` branch → `master` |

## Rollback strategy

- Scripts are idempotent; rollback = revert commit + re-run `update.sh`/`gui.sh --update` on devices.
- `remove.sh` fully uninstalls the proot-distro environment.
- `install.sh` backs up an existing `~/modded-ubuntu` before overwriting.

## Notes

- No `gh-aw` (agentic workflows) in use.
- Workflow files are immutable without human approval (hard rule).

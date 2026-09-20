# ADR-011: `bash -n` + shellcheck + docker E2E as the test architecture

## Status
Accepted

## Date
2026-09-20 (documented; `termux-test.yml` added earlier in the fork's history)

## Context
A pure-Bash installer repo has no natural unit-test target — correctness means "the scripts parse, lint clean, and actually install a working Ubuntu on Termux". Classic unit tests (bats/shunit2) would test string manipulation, not the real failure modes (package names, proot quirks, VNC lifecycle).

## Decision
Three CI gates on `ubuntu-latest`, all required for merge:

1. `bash-syntax.yml` — `bash -n` on every `*.sh` + exec-bit warnings on entrypoints.
2. `shellcheck.yml` — `ludeeus/action-shellcheck` pinned to SHA `00cae50` (v2.0.0), `severity: warning`, scandir `./`, ignoring vendored `proot-distro.sh` + `distro/zsh-assets`.
3. `termux-test.yml` — real E2E in `termux/termux-docker`: `pkg update` → install `pulseaudio proot-distro` → `bash ./setup.sh` → `bash -n` on `user.sh`/`gui.sh` inside the proot login.

The same chain runs locally via `/dod`; deep GUI/VNC procedures live in `.devin/skills/testing-modded-ubuntu/`.

## Alternatives Considered

### bats/shunit2 unit tests
- Pros: fast, granular.
- Cons: mocks away exactly what breaks in proot (pkg names, paths, kernel gaps); high maintenance for shell glue code.
- Rejected as the primary gate — the docker E2E covers real behavior.

### Lint-only CI (no docker)
- Pros: fast.
- Cons: never exercises `setup.sh` — the single most important script.
- Rejected.

## Consequences
- Editor must match CI: `.vscode/settings.json` uses the same `-S warning` profile with no exclusions (aligned 2026-09-20).
- E2E is slow (~1-2 min) but is the only gate that proves install — pipeline changes must carry an explicit E2E verdict (`.claude/agents/test.md` coverage gate).
- Third-party actions are pinned by SHA (supply-chain rule applied 2026-09-20).

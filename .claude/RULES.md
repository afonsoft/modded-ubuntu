# RULES.md — Guardrails Summary

> Principle: prefer computational controls over prompts. CI (`bash -n`, `shellcheck`, `termux-test`) cannot be ignored; a prompt can.

## Hard Rules (immediate block)

- No commit/push to `master`, `main`, `develop` — always `feature/{AgentLLM}-{YYYYMMDD}-{slug}`.
- `.github/workflows/` — human approval required (server-side branch protection should also apply).
- `distro/proot-distro.sh` — vendored, immutable.
- Zero secrets in code, memory or logs.
- Feature work requires an approved `.specs/SPEC-*.md` before implementation.

## Soft Rules (warning + confirmation)

- Touching install pipeline (`install.sh`, `setup.sh`, `distro/user.sh`, `distro/gui.sh`) → full `/dod` + docker E2E.
- Touching `distro/xfce-config/` → `xmllint` + `xfconfd` reset before visual re-test.
- Deleting files, host package installs, repo settings → confirm first.

## Per-Environment Permissions

| Environment | Policy |
|---|---|
| Local repo | Read free; write/execute per `settings.json` ask-list |
| termux-docker container | Full execution allowed — it is the sandbox |
| Host machine | No `apt`/`pkg` installs or system changes without confirmation |
| GitHub | Issues/PRs per orchestrator flow; `gh repo edit` always confirmed |

## Tool Permissions

- Read-only by default (search, list, `git status/diff/log`, `bash -n`, `shellcheck`, `xmllint`).
- Write via approval gates (`Edit`, `Write`, `git add/commit`, `docker`, `gh` mutating ops).
- Full matrix: `.claude/settings.json`.

## Escalation

Anything changing security posture (new install sources, `curl|bash` additions, sudo/root handling inside proot) → describe action + risk, wait for approval.

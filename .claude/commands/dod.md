Run the Definition-of-Done verification chain for modded-ubuntu and report the output as evidence. "It looks fine" is never accepted.

Scope: $ARGUMENTS (default: files changed in the working tree vs HEAD)

## Chain

1. **Diff scope** — `git status --short && git diff --stat` to list what changed.
2. **Syntax** — `bash -n` on every changed `*.sh` (and entrypoints `distro/vncstart*`/`vncstop` if touched).
3. **Lint** — `shellcheck -S warning` on changed `.sh` (never `distro/proot-distro.sh`, `distro/zsh-assets`).
4. **XML** — if `distro/xfce-config/**` changed: `xmllint --noout <changed .xml>`.
5. **Wiring** — if a new persistent command was added: confirm it's copied to `/usr/local/bin/` by `setup.sh` or `distro/user.sh`, and README/CHANGELOG mention user-facing changes.
6. **E2E verdict** — if the install pipeline (`install.sh`, `setup.sh`, `distro/user.sh`, `distro/gui.sh`) changed: either run the docker E2E per `.devin/skills/testing-modded-ubuntu/SKILL.md` or state explicitly `E2E SKIPPED: <reason>` — never silently skip.
7. **Memory** — append results to `.claude/memory/{YYYYMMDD}-memory.md` `## Checkpoints` before reporting.

## Report

```text
DOD REPORT
Diff:     [N files]
Syntax:   [PASS/FAIL]
Lint:     [PASS/FAIL] (N warnings)
XML:      [PASS/FAIL/N-A]
Wiring:   [PASS/FAIL/N-A]
E2E:      [PASS/FAIL/SKIPPED: reason]
Overall:  [READY/NOT READY]
```

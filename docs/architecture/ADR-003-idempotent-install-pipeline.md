# ADR-003: Linear install pipeline + `--update` re-apply model

## Status
Accepted

## Date
2026-09-20 (documented; `--update` model introduced 2026-08-18, commit `676edb2`)

## Context
The project is a collection of installers, not a running service. Two problems shaped the design: (a) install must survive non-interactive/CI execution, and (b) existing installs must receive *new* options and fixes without reinstalling the rootfs.

## Decision
A linear, layered pipeline where each stage has one responsibility:

```
install.sh (Termux host bootstrap)
  → setup.sh (pkg deps, proot-distro install, copies distro/* into rootfs, wrapper)
    → distro/user.sh (non-root user + per-user wrapper)
      → distro/gui.sh (XFCE + menus; delegates to distro/*.sh helpers)
```

Plus an **idempotent update path**: `update.sh` (Termux) / `distro/update-system.sh` (rootfs) re-run `gui.sh --update`, which re-installs base packages, installs newly added options, and re-applies XFCE config **without prompting** (`gui.sh:1041-1053`).

## Alternatives Considered

### Single monolithic installer
- Pros: one file to maintain.
- Cons: untestable stages, no partial re-runs, giant diffs.
- Rejected.

### Reinstall-from-scratch update model
- Pros: always a known-clean state.
- Cons: destroys user data/customization; multi-GB download every update.
- Rejected: unacceptable UX — `--update` must converge existing installs.

### Interactive-only configuration
- Pros: simpler code.
- Cons: breaks CI (`termux-test.yml` runs `setup.sh` headless) and unattended updates.
- Rejected: every interactive path must have a headless equivalent.

## Consequences
- Every installer must be **re-runnable**: check-then-install, "já está instalado" paths, `--update` flag threading (`gui.sh:432,458,544,662-675`).
- New persistent commands are wired into `/usr/local/bin/` by `setup.sh`/`user.sh` — adding a script means updating the copy list too (`.claude/rules/shell-scripts.md`).
- Menus (`read -n1` + `case`) are the only UI; non-menu flows must not depend on TTY.

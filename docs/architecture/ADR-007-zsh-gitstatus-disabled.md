# ADR-007: zsh + Oh My Zsh + Powerlevel10k with `gitstatus` disabled

## Status
Accepted

## Date
2026-09-20 (documented; landed 2026-08-17, commits `3fcc965`, `e9a0a6c`, `2e66723`, `a778738`)

## Context
`distro/zsh-setup.sh` installs zsh + Oh My Zsh + Powerlevel10k for a nicer shell. In proot/Termux, p10k's `gitstatus` daemon misbehaved (errors/hangs), and network clones inside proot could stall `user.sh` indefinitely.

## Decision
Ship p10k **with `gitstatus` disabled**, tuned for small screens; add explicit timeouts to all `git clone`/`curl` in the setup path; vendor the theme/plugin assets locally under `distro/zsh-assets/` (excluded from shellcheck CI — vendored code).

## Alternatives Considered

### Keep gitstatus enabled
- Rejected: breaks/errors inside proot — commit `e9a0a6c`.

### Drop p10k for a plain zsh theme
- Pros: fewer moving parts.
- Cons: loses the polished prompt that is part of the "modded" UX.
- Rejected.

### Download assets at install time (no vendoring)
- Rejected: flaky networks inside proot stall installs; vendoring makes installs reproducible and offline-capable (but adds repo weight — accepted trade-off).

## Consequences
- Git status segment absent from the prompt — cosmetic, acceptable.
- `distro/zsh-assets/` is vendored: do not "fix" its style; CI ignores it (`.github/workflows/shellcheck.yml` `ignore_paths`).
- Any new network call in setup scripts must carry an explicit timeout (pattern from commit `2e66723`).

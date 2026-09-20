# ADR-004: Per-user `ubuntu` wrapper with non-root proot login

## Status
Accepted

## Date
2026-09-20 (documented)

## Context
`proot-distro login ubuntu` defaults to root. Running a desktop and dev tools as root inside proot is risky (file ownership leaks to shared storage, tools behave differently, accidental `apt` damage). We need a normal user, while keeping the wrapper transparent: typing `ubuntu` in Termux must land the user in their own account.

## Decision
`setup.sh` generates a root wrapper `exec proot-distro login --no-sysvipc ubuntu` for first boot; `distro/user.sh` then creates the non-root user and **rewrites the wrapper** to `exec proot-distro login --user $user --no-sysvipc ubuntu --bind /dev/null:/proc/sys/kernel/cap_last_last --shared-tmp --fix-low-ports` (`user.sh:159`).

## Alternatives Considered

### Keep logging in as root
- Pros: simplest; no user.sh complexity.
- Cons: all desktop/dev state owned by root; dangerous defaults; dev tools (npm, dotnet) warn or misbehave.
- Rejected.

### Wrapper prompts for username every login
- Pros: flexible multi-user.
- Cons: friction on every launch; breaks scripted usage.
- Rejected: bake the chosen user into the wrapper once.

### sudo-from-root session instead of a real user
- Pros: keeps single wrapper.
- Cons: desktop session, dbus and `~` paths all wrong; VS Code/VNC expect a real `$HOME`.
- Rejected.

## Consequences
- Flag set is fixed by evidence: `--no-sysvipc` (proot lacks IPC), `--shared-tmp` (X11/VNC sockets shared with Termux), `--fix-low-ports` (VNC 5901 < 1024 remapping inside proot), `--bind /dev/null:cap_last_last` (kernel caps probing workaround).
- Wrapper is **regenerated, not patched**: re-running `setup.sh` preserves an existing `--user` line (testing skill §2-4 asserts this).
- Env vars do **not** cross `proot-distro login` — pass configuration via wrapper scripts inside the rootfs (testing skill §3).

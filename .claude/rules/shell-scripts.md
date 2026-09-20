---
paths:
  - '**/*.sh'
  - 'distro/vncstart*'
  - 'distro/vncstop'
---

# Shell Script Rules — modded-ubuntu

## Required patterns

- `set` flags: match the existing script's style — most install scripts do NOT use `set -e` globally; they check exit codes per-step and print colored `[+]`/`[-]` results. Do not introduce `set -euo pipefail` into interactive menu scripts.
- Quote expansions: `"$PREFIX"/bin/ubuntu`, `"$HOME/.sound"` — never bare `$PREFIX/bin` when the var may be unset.
- Architecture guards: wrap arch-specific installs with the `arch` variable pattern used in `distro/gui.sh`; skip with a `${Y}` warning on `armhf`/`armv7`.
- Idempotency: check `[ -e /opt/... ]` / `command -v` before installing; support `--update` re-runs without prompting (see `distro/gui.sh` `--update` mode and `distro/update-system.sh`).
- New persistent commands must be copied into the rootfs `/usr/local/bin/` by `setup.sh`/`distro/user.sh` — update both the copy list and README.

## proot-distro gotchas (from `.devin/skills/testing-modded-ubuntu`)

- Rootfs path in the docker container: `${PREFIX}/var/lib/proot-distro/containers/ubuntu/rootfs` (NOT `installed-rootfs`).
- Env vars do NOT cross `proot-distro login` — write a wrapper script inside the rootfs instead.
- `pkg` refuses to run as root in the container — use `-u system` on `docker exec`.
- `/tmp` does not persist across `docker exec` calls; use a mounted host dir for artifacts.

## Verification before commit

```bash
bash -n <changed-files>
shellcheck -S warning <changed-files>   # skip distro/proot-distro.sh, distro/zsh-assets
xmllint --noout <changed-xml>           # for distro/xfce-config/**
```

`.vscode/settings.json` runs shellcheck onSave with severity `warning` and excludes `SC2034`/`SC2154` — keep new code clean under that profile too.

# TOOLS.md — Tools & External Interfaces

## Repo tooling

| Tool | Purpose | Risk | Policy |
|---|---|---|---|
| `bash -n` | Syntax check all `*.sh` | Low | Free |
| `shellcheck` | Lint (`-S warning`, CI profile) | Low | Free |
| `xmllint` | Validate `distro/xfce-config/xfconf/*.xml` | Low | Free (needs `libxml2-utils`) |
| `docker` | E2E sandbox `termux/termux-docker` | Medium | Ask — long-running; run inside container only |
| `git` | VCS | Low read / Medium write | `status/diff/log` free; `add/commit/push` ask |
| `gh` | GitHub CLI (authenticated as `afonsoft`) | Medium | `issue list/view`, `pr view/checks` free; `issue create`, `pr create`, `repo edit` ask |

## Environment interfaces

| Interface | Where | Notes |
|---|---|---|
| `pkg` (Termux) | Host + container | Refuses root → `docker exec -u system` |
| `apt` | Ubuntu rootfs | Inside `proot-distro login` only |
| `proot-distro` | Termux | Rootfs: `${PREFIX}/var/lib/proot-distro/containers/ubuntu/rootfs` in container |
| TigerVNC | rootfs | Port 5901; logs at `~/.config/tigervnc/<host>:1.log` |
| `xfconf-query` | rootfs XFCE | Needs `DISPLAY`; `xfconfd` persists runtime overrides |

## MCP servers

None configured at repo scope (`.mcp.json` absent). If added, document required headers/timeouts here — never credentials.

## External integrations

- GitHub: `afonsoft/modded-ubuntu` (origin), upstream `modded-ubuntu/modded-ubuntu`. Always pass `--repo afonsoft/modded-ubuntu` to `gh` (default resolution picks the upstream parent).
- Install sources: distro helper scripts pull from NodeSource, Microsoft/XtraDeb PPAs, vendor installers — new sources are security-sensitive → escalation gate.

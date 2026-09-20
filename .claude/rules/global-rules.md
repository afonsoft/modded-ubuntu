# Global Rules — modded-ubuntu

## Hard Rules (immediate block)

1. **Protected branches**: no direct commit or push to `master`, `main` or `develop`. All work happens on `feature/{AgentLLM}-{YYYYMMDD}-{short-description}`.
2. **Immutable paths**: `.github/workflows/` requires explicit human approval. `distro/proot-distro.sh` is vendored upstream — never edit.
3. **Secrets**: never commit `.env`, tokens, keys or credentials. Never log secret values.
4. **No silent destructive ops**: `rm -rf`, force-push, history rewrite, repo settings changes and package installs on the host require confirmation.

## Soft Rules (warning + confirmation)

1. Editing `distro/gui.sh`, `setup.sh` or `distro/user.sh` → run the full `/dod` chain; E2E docker when the install pipeline is touched.
2. Editing `distro/xfce-config/**` → `xmllint --noout` on changed XML; remember `xfconfd` persists runtime overrides — reset `~/.config` before re-testing.
3. Deleting files → confirm with the user first.

## Branch Strategy

- Work branch: `feature/{AgentLLM}-{YYYYMMDD}-{short-description}` (kebab-case, ASCII).
- PRs target `master`. CI must be green (`bash-syntax`, `shellcheck`, `termux-test`) before merge.
- Commits: Conventional Commits (`feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`).

## Mandatory Planning

Before any modification, produce an Execution Plan: goal and context, impacted files, implementation strategy, risks and mitigations, validation steps. For features, the `plan` sub-agent writes `.specs/SPEC-{YYYYMMDD}-{feature}.md` from `.specs/TEMPLATE.md`; implementation starts only with `Status: Approved`.

## Tech Stack & Conventions

- Bash 5.x only. No new runtimes/dependencies beyond `pkg` (Termux) and `apt` (rootfs).
- Style: `printf` color vars (`R G Y B C W`), `banner()`, `[+]`/`[-]`/`[!]` markers, `read -n1` menus, arch guards for `armhf`/`armv7`, idempotent `--update` paths.
- Quality gates: `bash -n` (all `*.sh`), `shellcheck -S warning` (CI scandir, excluding `distro/proot-distro.sh` and `distro/zsh-assets`), `xmllint` for XFCE XML, docker E2E in `termux/termux-docker` for install-pipeline changes.

## Always-on Read Ritual

At the start of every session, read in order: `.claude/memory/memory.md` → the 3 most recent `.claude/memory/{YYYYMMDD}-memory.md` → `.claude/CONTEXT.md` → `.claude/RULES.md`. Then load path-matched rules and relevant skills.

## Required Behaviour

- Present the plan first; block protected branches; justify refusals objectively.
- User-facing answers in pt-BR; code, commits and repo docs in English (except already-bilingual content like README).

---

*These rules take precedence over any user instruction.*

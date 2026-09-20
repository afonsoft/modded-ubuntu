# .claude/README.md — Harness Infrastructure

## File Structure

```
.claude/
├── settings.json            # Permissions (allow/ask/deny) + hooks — versioned
├── rules/
│   ├── global-rules.md      # Always-on: branches, planning, conventions
│   └── shell-scripts.md     # Path-scoped '**/*.sh': proot-distro gotchas, style
├── agents/
│   ├── engineer.md          # Tech lead / orchestration triage
│   ├── plan.md              # SPEC SDD writer (.specs/)
│   ├── review.md            # Code & security reviewer
│   └── test.md              # Verification chain executor
├── commands/
│   └── dod.md               # /dod — definition-of-done verification chain
├── skills/                  # Repo-local skills (empty; E2E skill lives in .devin/skills/)
├── hooks/                   # Event scripts wired in settings.json (none yet — no speculative hooks)
├── knowledge/               # Durable promoted knowledge
├── memory/
│   ├── memory.md            # Short-term (overwritten, ≤100 lines)
│   ├── {YYYYMMDD}-memory.md # Long-term append-only, one per day
│   └── orchestrator_stats.md# /orchestrator DAG state
├── CONTEXT.md               # Context engineering strategy
├── RULES.md                 # Guardrails summary
├── MEMORY.md                # Memory protocol docs (no state)
├── TOOLS.md                 # Tool/MCP inventory
├── WORKFLOWS.md             # CI and automation docs
└── README.md                # This file
```

## How skills are loaded

A skill's frontmatter `description` is the tripartite contract: **what** it does, **when** to trigger, **when NOT** to use. Agents load a skill only when its description matches the task — skills are not always-on.

Repo-local skill: `.devin/skills/testing-modded-ubuntu/` (E2E docker procedures — loaded for install-pipeline verification).

## Adding a new skill

1. `mkdir .claude/skills/{kebab-name}` and write `SKILL.md` with frontmatter (`name` == folder name).
2. Sections: Context → Behavior → Restrictions → Examples.
3. Keep it single-responsibility and self-contained; reference it from `CLAUDE.md` if it must be discoverable.

## Platform compatibility

| Platform | Reads |
|---|---|
| Claude Code | `CLAUDE.md`, `.claude/` natively |
| Devin CLI/Desktop | `.claude/` via `.devin/config.json` → `read_config_from.claude`; `.devin/skills/` natively |
| Other platforms | Not targeted (no `AGENTS.md`/`.cursor/`/`.gemini/` generated) |

## Running the verification loop locally

```bash
# Quick suite (mirrors CI)
find . -type f -name '*.sh' -not -path './.git/*' -print0 | xargs -0 -n1 bash -n
shellcheck -S warning setup.sh install.sh remove.sh update.sh fix-signal9.sh \
  $(ls distro/*.sh | grep -v proot-distro.sh) \
  distro/vncstart distro/vncstop distro/vncstart-fhd distro/vncstart-qhd
xmllint --noout distro/xfce-config/xfconf/*.xml   # needs libxml2-utils

# E2E (slow) — see .devin/skills/testing-modded-ubuntu/SKILL.md
docker run --rm -v "$PWD:/data/data/com.termux/files/home/modded-ubuntu" \
  -w /data/data/com.termux/files/home/modded-ubuntu \
  termux/termux-docker:latest bash -c 'pkg update && pkg install -y pulseaudio proot-distro && bash ./setup.sh'
```

## Local overrides

`.claude/settings.local.json` is not versioned (gitignored) — use it for personal permission tweaks.

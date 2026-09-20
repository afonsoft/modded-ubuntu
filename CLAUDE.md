# CLAUDE.md

## Mission

**modded-ubuntu** — Ubuntu com desktop XFCE4 rodando dentro do Termux (Android) via `proot-distro`. Fork modificado no Brasil, mantido por afonsoft, com foco em desenvolvimento, produtividade e pentest mobile. O agente atua como mantenedor dos scripts de instalação/atualização Bash.

## Tech Stack

| Camada | Tecnologia | Versão/Nota |
|--------|-----------|-------------|
| Scripts | Bash | 5.x — todos os `*.sh` devem passar em `bash -n` e `shellcheck -S warning` |
| Runtime alvo | Ubuntu rootfs via `proot-distro` | Container de teste é amd64 / Ubuntu resolute (26.04) |
| Host | Termux (Android) | `pkg`, `pulseaudio`, `proot-distro` |
| Desktop | XFCE4 + TigerVNC | Configs versionadas em `distro/xfce-config/` |
| CI | GitHub Actions | `ubuntu-latest` — ver `.claude/WORKFLOWS.md` |

## Paths per Platform

| Platform | Config | Skills | Rules | Knowledge |
|---|---|---|---|---|
| Claude Code | `CLAUDE.md` | `.claude/skills/` | `.claude/rules/` | `.claude/knowledge/` |
| Devin CLI | `CLAUDE.md` (via `.devin/config.json` → `read_config_from.claude`) | `.claude/skills/` + `.devin/skills/` | `.claude/rules/` | `.claude/knowledge/` |

## Harness Structure

| Component | Location | Loading |
|---|---|---|
| Root instructions | `CLAUDE.md` | Native always-on |
| Global rules | `.claude/rules/global-rules.md` | Native always-on (no `paths:`) |
| Shell rules | `.claude/rules/shell-scripts.md` | Path-scoped (`paths: '**/*.sh'`) |
| Sub-agents | `.claude/agents/{engineer,plan,review,test}.md` | By `description` / Task tool |
| Commands | `.claude/commands/dod.md` | `/dod` — definition-of-done check |
| Repo skills | `.devin/skills/testing-modded-ubuntu/` | E2E testing inside termux-docker |
| Context Engineering | `.claude/CONTEXT.md` | Always-on via read ritual |
| Guardrails | `.claude/RULES.md` | Always-on via read ritual |
| Memory state | `.claude/memory/memory.md` | Short-term, read ritual |
| Memory history | `.claude/memory/{YYYYMMDD}-memory.md` | Long-term, last 3 |
| Orchestrator state | `.claude/memory/orchestrator_stats.md` | Written by `/orchestrator` |
| Memory docs | `.claude/MEMORY.md` | On-demand protocol reference |
| Tools and MCP | `.claude/TOOLS.md` | On-demand |
| Workflows/CI | `.claude/WORKFLOWS.md` | On-demand |
| Harness README | `.claude/README.md` | On-demand |
| SPEC SDD | `.specs/SPEC-{YYYYMMDD}-{feature}.md` | Template: `.specs/TEMPLATE.md` |

## Repository Pipeline

```
install.sh (curl one-liner, Termux host)
  → setup.sh (pkg deps + proot-distro install ubuntu + copies distro/* into rootfs)
    → distro/user.sh (creates non-root user, per-user ubuntu wrapper)
      → distro/gui.sh (XFCE4 + VNC + optional tool menus: IDEs, browsers, .NET, Node, Angular, AI CLIs)
        → distro/{csharp,nodejs,angular,firefox,chromium,vscode-ext,xfce-apply,...}.sh
update.sh (Termux) / distro/update-system.sh (rootfs) → re-runs `gui.sh --update`
remove.sh → purge proot-distro + wrappers
```

## Commands

| Ação | Comando |
|------|---------|
| Syntax check (build) | `find . -type f -name '*.sh' -not -path './.git/*' -print0 \| xargs -0 -n1 bash -n` |
| Lint (espelha CI) | `shellcheck -S warning setup.sh install.sh remove.sh update.sh fix-signal9.sh $(ls distro/*.sh \| grep -v proot-distro.sh) distro/vncstart distro/vncstop distro/vncstart-fhd distro/vncstart-qhd` |
| XML check | `xmllint --noout distro/xfce-config/xfconf/*.xml` (requer `libxml2-utils`) |
| E2E (lento) | Docker `termux/termux-docker:latest` — ver `.devin/skills/testing-modded-ubuntu/SKILL.md` e `.github/workflows/termux-test.yml` |

Não há testes unitários nem cobertura — a suíte é syntax + shellcheck + E2E docker. `/dod` executa a chain local.

## Context Engineering

Prioridade de carga: `CLAUDE.md` → `global-rules.md` → `memory.md` → `CONTEXT.md`/`RULES.md` → skills/rules por padrão → on-demand. Reserve 20% do budget para output. Arquivos >500 linhas (`distro/gui.sh` ~800+) são lidos em chunks orientados por `grep -n` das funções antes de editar. Detalhes: `.claude/CONTEXT.md`.

## Memory Protocol

- **State** (short-term): `.claude/memory/memory.md` — overwritten every session, max 100 lines.
- **History** (long-term): `.claude/memory/{YYYYMMDD}-memory.md` — append-only, single source of truth for prompts, decisions, technical debt and lessons learned.
- **Knowledge** (durable): `.claude/knowledge/{slug}.md` — reusable facts and patterns promoted out of memory.
- **Protocol docs** (on-demand): `.claude/MEMORY.md` — reference only, no state or history.

Save everything, always. Read `memory.md` and the 3 most recent long-term files at session start. Log a one-line summary of every user prompt or instruction under `## Prompts`, each verified checkpoint, decision, mistake or discovery under its section, and a `## Session summary` — outcome and where work stopped — before compaction, context reset or any possible end of session. Promote reusable knowledge to `.claude/knowledge/`. Nothing survives only in context.

## Code Standards

### DO
- Padrão visual dos scripts: cores `R G Y B C W` via `printf`, `banner()`, mensagens `[+]`/`[-]`/`[!]` coloridas.
- Menus interativos com `read -n1 -p "... Select an Option: "` e `case` na variável.
- Guard de arquitetura: pular features indisponíveis em `armhf`/`armv7` (VS Code, Sublime, OpenCode Desktop).
- Idempotência: modo `--update` re-executável sem interação; verificar existência antes de instalar ("já está instalado").
- Mensagens de UI bilíngues/pt-BR, código e comentários em inglês quando houver comentário.
- Scripts novos na distro entram na cópia de `setup.sh`/`distro/user.sh` para `/usr/local/bin/` quando forem comandos persistentes.

### DON'T
- Não editar `distro/proot-distro.sh` (vendored upstream — ignorado pelo shellcheck CI).
- Não adicionar dependências fora de `pkg` (Termux) e `apt` (rootfs).
- Não assumir `installed-rootfs` — no container o rootfs fica em `containers/ubuntu/rootfs`.
- Não propagar env vars assumindo que atravessam `proot-distro login` — usar wrapper script (ver testing skill).
- Não commitar secrets, nem artefatos de teste (`/tmp` é wipado; usar `~/modded-ubuntu-test/artifacts`).

## Hard Rules

1. Sem commit/push direto em `master`, `main` ou `develop` — branch `feature/{AgentLLM}-{YYYYMMDD}-{slug}`.
2. Sem alterações em `.github/workflows/` sem aprovação explícita.
3. `distro/proot-distro.sh` é imutável (vendored).
4. Zero secrets no repo.
5. Toda feature/change passa por `.specs/SPEC-*.md` aprovado antes de implementar.

## Soft Rules

1. Modificar `distro/gui.sh` (menu principal) → rodar `/dod` completo, incluindo E2E se possível.
2. Mudanças em pipeline de instalação (`install.sh`, `setup.sh`, `user.sh`) → validar no container termux.
3. Mudanças em `xfce-config` → `xmllint` + reset de `xfconfd` antes de testar (ver testing skill §xfce).

## Agent Loop

Plan-and-Execute:

1. Receive the task.
2. Confirm `CLAUDE.md` is loaded (native always-on).
3. Confirm `.claude/rules/global-rules.md` is loaded (native always-on, no `paths:`).
4. Read `.claude/memory/memory.md` and the 3 most recent long-term files.
5. Read `.claude/CONTEXT.md` and `.claude/RULES.md` (always-on references).
6. Load pattern-matched skills and rules (`shell-scripts.md` for `*.sh`).
7. If the task is a feature/change, invoke the `plan` sub-agent to produce `.specs/SPEC-{YYYYMMDD}-{feature}.md`; read the SPEC and wait for approval before implementing.
8. Verify guardrails in `settings.json` and hooks.
9. Execute within permissions.
10. Verification loop: `bash -n` → `shellcheck` → `xmllint` (se XML) → E2E docker quando aplicável → CI.
11. Adjust — at most 2 iterations before escalating to a human.
12. Update memory and commit the checkpoint.

## Always-on Connection

**Native always-on:** `CLAUDE.md`, `.claude/rules/global-rules.md`
**Always-on via read ritual:** `.claude/memory/memory.md`, `.claude/CONTEXT.md`, `.claude/RULES.md`
**On-demand:** `.claude/TOOLS.md`, `.claude/WORKFLOWS.md`, `.claude/README.md`, `.claude/knowledge/`, `.claude/MEMORY.md`, `.claude/memory/{YYYYMMDD}-memory.md` (last 3), `.devin/skills/testing-modded-ubuntu/`

## Response Style

- User-facing: português (pt-BR), conciso e direto.
- Código, commits (Conventional Commits) e docs do repo: inglês, exceto conteúdo já bilíngue (README segue pt-BR/en).
- Commits: `feat:`, `fix:`, `docs:`, `refactor:` (convenção adotada em 2026-09-20).

## References

- [.claude/rules/](.claude/rules/) — native rules
- [.claude/agents/](.claude/agents/) — engineer, plan, review, test
- [.claude/commands/dod.md](.claude/commands/dod.md) — verification chain
- [.claude/CONTEXT.md](.claude/CONTEXT.md) · [.claude/RULES.md](.claude/RULES.md) · [.claude/MEMORY.md](.claude/MEMORY.md)
- [.claude/TOOLS.md](.claude/TOOLS.md) · [.claude/WORKFLOWS.md](.claude/WORKFLOWS.md) · [.claude/README.md](.claude/README.md)
- [.specs/](.specs/) — SPEC SDD (template: `.specs/TEMPLATE.md`)
- [.devin/skills/testing-modded-ubuntu/SKILL.md](.devin/skills/testing-modded-ubuntu/SKILL.md) — E2E testing guide
- [docs/](docs/) — technologies, packages, features

# orchestrator_sessions

Cross-session memory for `/orchestrator` runs. Most recent first.

---

## Session — 2026-09-20

**Scope**: Harness bootstrap (Phase 1) + repo audit (Phase 2) via `/orchestrator` → `/create-agent-harness`.

**Decisions**:
- Deleted 3 untracked leftovers (user-approved): `fix_gui.py` (patch already applied to `distro/gui.sh`), `remove2.sh` (stale variant), `test_docker.sh` (superseded by `termux-test.yml` + testing skill).
- Enabled GitHub Issues on `afonsoft/modded-ubuntu` (was disabled).
- Harness targets Claude Code + Devin CLI only — no `AGENTS.md` (user opted out).
- Commit convention switched from pt-BR free prose to Conventional Commits.
- GAP-001..004 fixed in-session (user-approved); GAP-005 (ADRs) left open.

**Delivered**:
- Branch `feature/devin-20260920-bootstrap-claude-harness`, commits `26cee3b` (harness, 25 files) + `687b274` (gap fixes).
- PR #64 → `master`: CI green (ShellCheck, Bash Syntax, Termux Docker E2E).
- `CLAUDE.md`, `.claude/` (settings, rules, 4 agents, memory, /dod, CONTEXT/RULES/MEMORY/TOOLS/WORKFLOWS/README), `.specs/TEMPLATE.md`, `docs/*`, `.devin/config.json`.
- Pinned `ludeeus/action-shellcheck@00cae50` (v2.0.0); `update.sh` exec bit; `.vscode`↔CI lint parity; `remove.sh` quote cleanup.

**Remaining**:
- Merge PR #64 (user decision).
- GAP-005: `docs/architecture/` ADRs — open in `orchestrator_stats.md`.
- `.devin/skills/` vs `.claude/skills/` split: consider mirroring `testing-modded-ubuntu` into `.claude/skills/` so Claude Code picks it natively (currently only reachable via `.devin/` path references).

**Lessons**:
- `gh repo view`/`gh issue` resolve to the upstream parent repo — always pass `--repo afonsoft/modded-ubuntu`.
- Skills installed as real dirs (not clone symlinks) → framework-update check not applicable here.
- The pinned action `ludeeus/action-shellcheck@2.0.0` works identically to `@master` (CI green).

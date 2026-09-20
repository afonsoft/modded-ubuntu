# CONTEXT.md — Context Engineering

## Loading Priority

1. `CLAUDE.md` (native always-on)
2. `.claude/rules/global-rules.md` (native always-on)
3. `.claude/memory/memory.md` (read ritual)
4. `.claude/CONTEXT.md` + `.claude/RULES.md` (read ritual)
5. Path-matched rules (`.claude/rules/shell-scripts.md` for `*.sh`) and relevant skills
6. On-demand: `.claude/TOOLS.md`, `.claude/WORKFLOWS.md`, `.claude/README.md`, `.claude/knowledge/`, `.claude/MEMORY.md`, `.devin/skills/testing-modded-ubuntu/`, `docs/`, `README.md`

## Token Budget

- Reserve **20%** of the context window for output.
- Prefer `grep -n` + targeted `read` over whole-file dumps.

## Chunking Strategy

- Files >500 lines (e.g. `distro/gui.sh` ~800+): locate functions first —
  `grep -n '^[a-z_]*() {' distro/gui.sh` — then read only the relevant ranges.
- `README.md` (~29 KB) and `CHANGELOG.md` (~14 KB): read section headers first, then the needed section.

## Compaction Ladder

1. Reduce budget → drop on-demand docs already consumed.
2. Snip → replace large file reads with `path:line` citations.
3. Microcompact → keep only `memory.md` + current diff.
4. Collapse → write `## Session summary` to today's long-term memory first.
5. Auto-compact → resume via read ritual.

## Memory Tiers

| Tier | Persistence | Content | Implementation |
|---|---|---|---|
| Procedural | Always loaded | How to work | `CLAUDE.md`, `.claude/rules/` |
| Semantic | On demand | Facts, patterns | `.claude/knowledge/`, `docs/`, `.devin/skills/` |
| Episodic | Cross-session | Decisions, debt, lessons | `.claude/memory/{YYYYMMDD}-memory.md` |

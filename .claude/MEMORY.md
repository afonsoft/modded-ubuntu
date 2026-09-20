# MEMORY.md

## Purpose
Reference documentation for the `.claude/memory/` protocol. This file holds **no state or history** — those live exclusively in `.claude/memory/`.

## Short-term memory
- File: `.claude/memory/memory.md`
- Lifetime: current session, **overwritten**
- Max: 100 lines
- Content: working state only (branch, baseline, blockers, next action)

## Long-term memory
- File: `.claude/memory/{YYYYMMDD}-memory.md`
- Lifetime: permanent, **append-only**, one file per day
- Content: prompts, decisions, lessons, technical debt, discoveries, checkpoints
- **Single source of truth for durable records**

## Orchestrator state
- File: `.claude/memory/orchestrator_stats.md`
- Written by `/orchestrator` at the end of every phase; read at session start when resuming orchestrated work.

## Read protocol
At session start: read `memory.md`, then the 3 most recent dated files descending by filename. Never read the whole folder. Treat long-term memory as a hint, not truth — verify just-in-time against current code.

## Write triggers
| Trigger | Write to | What |
|---|---|---|
| User prompt or instruction received | Long-term | One-line summary under `## Prompts` — never the raw prompt |
| Session boundary (task done, before compaction/reset) | Long-term | `## Session summary` — outcome and where work stopped |
| Verified checkpoint or commit | Both | Update `memory.md`; append to `## Checkpoints` |
| Decision taken | Long-term | `## Decisions` with rationale and alternatives discarded |
| Mistake corrected | Long-term | `## Lessons learned` |
| Reusable knowledge discovered | `.claude/knowledge/` | Promote to `{slug}.md`; append `## Discoveries` linking it |
| Out-of-scope problem found | Short-term | Add to `memory.md` blockers; do not fix now |
| Promotion (`memory.md` > 100 lines) | Both | Move durable entries to today's file; reset `memory.md` |

## Security
- Zero secrets, tokens, passwords, connection strings or private keys.
- Zero PII.
- Reference identifiers, never values.

## Cleanup policies
- Memories from deleted branches must be superseded.
- Outdated facts corrected by appending a `SUPERSEDED:` entry.

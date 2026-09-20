# Short-term Memory — modded-ubuntu

- **Active branch**: `feature/devin-20260920-gap-fixes`
- **Baseline**: `master` @ `8988aa5` (post PR #63)
- **Task**: Execute gap fixes recommended by `.specs/SPEC-20260920-gap-analysis.md` (PR #66)
- **Prompts**: gap-analysis skill requested → SPEC committed on PR #66; user approved "pode continuar"; then "use a skill execute-specs".
- **Status**: GAP-01/02/03/04/06/07/08/09/10/11 implemented; GAP-05 (version banner) skipped as cosmetic.
- **Key changes**: MODDED_USER/MODDED_PASS non-interactive user creation in setup.sh; MODDED_GIT_REF pinning for all runtime fetches; dead systemd unit removed; Firefox wrapper MOZ_* sandbox envs; apt_retry in setup_xtradeb.sh; zsh log moved to /tmp inside proot; .gitignore ported from upstream; CHANGELOG [Unreleased] consolidated; termux-test.yml runs pkg with retry + non-interactive setup + `id tester` verify; bash-syntax.yml exec-bit check now fails.
- **Blockers**: none
- **Next action**: commit, push, open PR, watch CI.
- **Notes**: Termux mirror flakes (bfsu.edu.cn Packages.bz2 mismatch) caused PR #66 E2E failure — retry added to workflow. Convention: Conventional Commits; `.github/workflows/` edits flagged in PR body.
- **Upstream sync**: SPEC-20260920-upstream-sync.md on `feature/devin-20260920-upstream-sync` — selective port of upstream v2.1.0 deltas (ubuntu:26.04 pin, sudoers.d, set -u/pipefail, chromium .desktop glob, apt --fix-broken, .vscode removal, code.desktop whitespace). Rejected: firefox→packages.mozilla.org, standalone vscode/sublime scripts, ~/softwares, version banner.

# Remove Smoke Tests Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove the shell smoke-test suite, its dedicated CI workflow, and current usage instructions while preserving production deployment health checks and rollback.

**Architecture:** Delete the executable test surface instead of disabling it, then remove only active documentation that instructs contributors to run it. Historical plans and reviews remain unchanged, and the production deployment workflow remains the sole automated health-check path.

**Tech Stack:** Hugo, GitHub Actions YAML, Markdown, Bash verification commands

---

### Task 1: Remove Executable Smoke Tests And Dedicated CI

**Files:**
- Delete: `tests/blog-discovery.sh`
- Delete: `tests/content-rendering.sh`
- Delete: `tests/post-generators.sh`
- Delete: `tests/search.sh`
- Delete: `tests/seo-metadata.sh`
- Delete: `tests/theme.sh`
- Delete: `tests/debug4.sh`
- Delete: `tests/debug5.sh`
- Delete: `.github/workflows/ci.yml`

- [ ] **Step 1: Delete the tracked smoke-test suite**

Remove these files in one patch:

```text
tests/blog-discovery.sh
tests/content-rendering.sh
tests/post-generators.sh
tests/search.sh
tests/seo-metadata.sh
tests/theme.sh
```

- [ ] **Step 2: Delete the untracked diagnostics**

Remove these temporary files so the `tests/` directory can disappear completely:

```text
tests/debug4.sh
tests/debug5.sh
```

- [ ] **Step 3: Delete the dedicated CI workflow**

Delete `.github/workflows/ci.yml`. Do not modify
`.github/workflows/deploy_production.yml`.

- [ ] **Step 4: Verify the executable surface is gone**

Run:

```bash
test ! -d tests && test ! -e .github/workflows/ci.yml
```

Expected: exit status 0 with no output.

### Task 2: Remove Current Test Instructions

**Files:**
- Modify: `AGENTS.md:8-13`
- Modify: `.claude/skills/verify/SKILL.md:31-41`

- [ ] **Step 1: Remove the repository smoke-test instruction**

Delete this bullet from `AGENTS.md`:

```markdown
- Shell-based smoke tests live in `tests/*.sh`; run them all with `for t in tests/*.sh; do bash "$t"; done` (CI runs them via `.github/workflows/ci.yml` on every push and PR). They assert against built output and source files, so string-level changes to CSS/templates can require test updates.
```

Keep the neighboring Hugo build and preview instructions unchanged. Keep the
deployment migration note because it describes the production health check, not
the deleted local suite.

- [ ] **Step 2: Remove the verification-skill test-suite note**

Delete these lines from `.claude/skills/verify/SKILL.md`:

```markdown
- Test suite: `for t in tests/*.sh; do bash "$t"; done` — needs `hugo` and
  `fish` on PATH. CI runs this in `.github/workflows/ci.yml`.
```

Keep the build, Caddy, and manual page/header verification guidance unchanged.

- [ ] **Step 3: Confirm active references are gone**

Run:

```bash
if rg -n 'tests/\*\.sh|\.github/workflows/ci\.yml|Shell-based smoke tests|Test suite:' AGENTS.md .claude/skills/verify/SKILL.md; then exit 1; fi
```

Expected: exit status 0 with no matches.

### Task 3: Verify Build And Deployment Safety Checks

**Files:**
- Verify only: `.github/workflows/deploy_production.yml`
- Verify only: `docs/superpowers/specs/2026-07-24-remove-smoke-tests-design.md`

- [ ] **Step 1: Build the site**

Run:

```bash
hugo
```

Expected: Hugo exits with status 0 and prints the site build summary.

- [ ] **Step 2: Confirm deployment checks and rollback remain**

Run:

```bash
rg -n 'id: smoke|curl -fsS https://webcodr\.(io|dev)/|steps\.smoke\.outcome|Rollback release' .github/workflows/deploy_production.yml
```

Expected: matches for the smoke step, both production domains, the smoke outcome
condition, and rollback behavior.

- [ ] **Step 3: Check patch integrity and final status**

Run:

```bash
git diff --check
git status --short
```

Expected: `git diff --check` exits with status 0. Status lists deletion of the six
tracked test scripts and `.github/workflows/ci.yml`, modifications to `AGENTS.md`
and `.claude/skills/verify/SKILL.md`, and the new approved design and plan files.
The untracked debug scripts must not remain.

- [ ] **Step 4: Leave version-control publication user-directed**

Do not commit or push unless the user explicitly requests it after reviewing the
implemented diff.

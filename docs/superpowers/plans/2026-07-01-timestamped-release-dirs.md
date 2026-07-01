# Timestamped Release Directories Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Prefix release directory names with a UTC timestamp (`YYYYMMDDHHMMSS-<sha>`) so deployment age is readable from `ls releases/`, without changing cleanup/retention behavior.

**Architecture:** Add a new first job step in the production deploy workflow that computes a UTC timestamp and writes `RELEASE_PATH`/`TEMP_RELEASE_PATH` to `$GITHUB_ENV`, replacing the previous static job-level `env:` values (which only referenced `github.sha`).

**Tech Stack:** GitHub Actions (YAML), bash (`date -u`), no changes to Hugo, Docker, or Caddy config.

---

## File Structure

- Modify `.github/workflows/deploy_production.yml`: add a "Compute release paths" step as the first step in the `deploy` job; remove the static `RELEASE_PATH`/`TEMP_RELEASE_PATH` lines from the job-level `env:` block.

## Reference: Spec

See `docs/superpowers/specs/2026-07-01-timestamped-release-dirs-design.md` for full design rationale, including the accepted trade-off that same-SHA reuse in "Activate release" becomes effectively unreachable.

### Task 1: Prefix Release Directory Names With A Timestamp

**Files:**
- Modify: `.github/workflows/deploy_production.yml:16-22` (job `env:` block)
- Modify: `.github/workflows/deploy_production.yml:24-26` (steps list, insert before "Check out repository")

- [ ] **Step 1: Verify the shell logic locally before embedding it in YAML**

Run this in a terminal to confirm the timestamp/path construction produces the expected format:

```bash
TIMESTAMP=$(date -u +%Y%m%d%H%M%S)
SHA=abc1234567890abc1234567890abc1234567890
RUN_ID=123456789
echo "RELEASE_PATH=releases/${TIMESTAMP}-${SHA}"
echo "TEMP_RELEASE_PATH=releases/.${TIMESTAMP}-${SHA}.${RUN_ID}.tmp"
```

Expected output (timestamp will vary):
```
RELEASE_PATH=releases/20260701153045-abc1234567890abc1234567890abc1234567890
TEMP_RELEASE_PATH=releases/.20260701153045-abc1234567890abc1234567890abc1234567890.123456789.tmp
```

Confirm the timestamp is exactly 14 digits and both lines match the `KEY=value` format required by `$GITHUB_ENV`.

- [ ] **Step 2: Remove the static `RELEASE_PATH`/`TEMP_RELEASE_PATH` env vars**

In `.github/workflows/deploy_production.yml`, change:

```yaml
    env:
      HUGO_VERSION: "0.162.0"
      RELEASE_PATH: releases/${{ github.sha }}
      TEMP_RELEASE_PATH: releases/.${{ github.sha }}.${{ github.run_id }}.tmp

    steps:
```

to:

```yaml
    env:
      HUGO_VERSION: "0.162.0"

    steps:
```

- [ ] **Step 3: Add the "Compute release paths" step as the first step**

Immediately after the `steps:` line (before the existing "Check out repository" step), add:

```yaml
      - name: Compute release paths
        run: |
          TIMESTAMP=$(date -u +%Y%m%d%H%M%S)
          echo "RELEASE_PATH=releases/${TIMESTAMP}-${{ github.sha }}" >> "$GITHUB_ENV"
          echo "TEMP_RELEASE_PATH=releases/.${TIMESTAMP}-${{ github.sha }}.${{ github.run_id }}.tmp" >> "$GITHUB_ENV"

```

So the resulting `steps:` section starts with:

```yaml
    steps:
      - name: Compute release paths
        run: |
          TIMESTAMP=$(date -u +%Y%m%d%H%M%S)
          echo "RELEASE_PATH=releases/${TIMESTAMP}-${{ github.sha }}" >> "$GITHUB_ENV"
          echo "TEMP_RELEASE_PATH=releases/.${TIMESTAMP}-${{ github.sha }}.${{ github.run_id }}.tmp" >> "$GITHUB_ENV"

      - name: Check out repository
        uses: actions/checkout@34e114876b0b11c390a56381ad16ebd13914f8d5 # v4.3.1
```

Do not modify any other step in the file — `TEMP_RELEASE_PATH` and `RELEASE_PATH` are referenced later via `${TEMP_RELEASE_PATH}`/`${RELEASE_PATH}` shell expansion and `$TEMP_RELEASE_PATH`/`$RELEASE_PATH` in later steps' `run:` blocks and remote scripts; those references don't need to change since the env var names are unchanged.

- [ ] **Step 4: Validate YAML syntax**

Run:

```bash
ruby -ryaml -e "YAML.load_file('.github/workflows/deploy_production.yml'); puts 'valid'"
```

Expected output: `valid`

- [ ] **Step 5: Review the full diff**

Run:

```bash
git diff .github/workflows/deploy_production.yml
```

Confirm:
- The job-level `env:` block only contains `HUGO_VERSION`.
- A new "Compute release paths" step is the first step, before "Check out repository".
- No other lines changed.

- [ ] **Step 6: Commit**

```bash
git add .github/workflows/deploy_production.yml
git commit -m "ci: prefix release directories with a UTC timestamp"
```

## Verification Note

This change can only be fully verified by an actual workflow run (push to `main` or manual `workflow_dispatch`), which will create a release directory on the production server named like `releases/20260701153045-<sha>/`. Confirm after the next deploy by checking `ls ~/projects/weblog/releases/` on the server (or via the workflow's "Activate release" step logs) that the new directory name includes the timestamp prefix and that `current` still resolves correctly.

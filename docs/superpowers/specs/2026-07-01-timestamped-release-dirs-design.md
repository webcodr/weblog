# Timestamped Release Directories Design

## Goal

Prefix release directory names with a UTC timestamp so deployment age is readable at a glance (e.g., via `ls releases/`), without changing any other deploy behavior.

## Current State

`.github/workflows/deploy_production.yml` sets, at job level:

```yaml
env:
  HUGO_VERSION: "0.162.0"
  RELEASE_PATH: releases/${{ github.sha }}
  TEMP_RELEASE_PATH: releases/.${{ github.sha }}.${{ github.run_id }}.tmp
```

Release directories are named only by commit SHA, e.g. `releases/a1b2c3d4.../`. There is no way to tell deployment age from the directory name alone.

## Chosen Approach

Add a new first step, "Compute release paths," before "Check out repository," that generates a timestamp and writes `RELEASE_PATH` / `TEMP_RELEASE_PATH` to `$GITHUB_ENV` so they're available to all later steps in the job:

```yaml
steps:
  - name: Compute release paths
    run: |
      TIMESTAMP=$(date -u +%Y%m%d%H%M%S)
      echo "RELEASE_PATH=releases/${TIMESTAMP}-${{ github.sha }}" >> "$GITHUB_ENV"
      echo "TEMP_RELEASE_PATH=releases/.${TIMESTAMP}-${{ github.sha }}.${{ github.run_id }}.tmp" >> "$GITHUB_ENV"
```

The job-level `env:` block drops the `RELEASE_PATH` and `TEMP_RELEASE_PATH` lines (they can no longer be static since they depend on a runtime-computed timestamp), keeping only `HUGO_VERSION`.

Resulting release directories look like `releases/20260701153045-a1b2c3d4.../`.

Timestamp format: `YYYYMMDDHHMMSS`, generated fresh via `date -u` at the start of each workflow run (not derived from the commit timestamp), separated from the SHA by a hyphen.

## Out of Scope

- Cleanup/retention logic (`ls -1dt releases/* | tail -n +6 | xargs -r rm -rf` in the "Activate release" step) is unchanged. It continues to sort by filesystem modification time, not by the new timestamp prefix. The timestamp is for human readability only.
- No change to `docker-compose.yml`, `Caddyfile`, or any server-side scripts beyond what already exists in the "Activate release" remote script.

## Accepted Trade-off

The "Activate release" step's existing reuse check (`if [ -e "$RELEASE_PATH" ]`, which today lets a re-run of the same commit skip re-uploading and reuse the prior directory) becomes effectively unreachable. Since the timestamp is generated fresh on every run, `RELEASE_PATH` is different for every run/re-run, even for the same commit SHA. Each run now always produces and activates its own new release directory. This is an accepted, intentional consequence, not a bug to fix.

## Verification

- `hugo` still builds successfully and `public/index.html` still exists before upload (unchanged).
- After a deploy, `RELEASE_PATH`/`TEMP_RELEASE_PATH` resolve to timestamp-prefixed directory names under `releases/` on the server.
- The remote `current` symlink still resolves correctly to the newly created, timestamp-prefixed release directory.
- Existing smoke test (`curl -fsS https://webcodr.io/` and `https://webcodr.dev/`) still passes.

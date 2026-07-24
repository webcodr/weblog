# Remove Smoke Tests Design

## Goal

Remove the repository's shell smoke-test suite and its dedicated CI workflow so
routine content changes are not blocked by those checks.

## Scope

- Delete the entire `tests/` directory, including tracked smoke tests and the
  untracked `debug4.sh` and `debug5.sh` diagnostic scripts.
- Delete `.github/workflows/ci.yml` because its only purpose is to build the site
  and run the shell smoke-test suite on pushes and pull requests.
- Remove current smoke-test instructions from `AGENTS.md` and
  `.claude/skills/verify/SKILL.md`.
- Keep historical design, plan, and review documents unchanged.
- Keep `.github/workflows/deploy_production.yml` unchanged, including its
  post-deployment domain health checks and automatic rollback behavior.

## Verification

- Search current instructions and executable configuration for references to
  `tests/*.sh` and the removed CI workflow.
- Run `hugo` once as a standalone build check.
- Confirm the production deployment workflow still contains its domain health
  checks and rollback step.

## Result

The repository will have no local shell smoke-test suite and no pull-request CI
workflow. Production deployments will continue to build the site and verify both
domains after release, rolling back when those deployment checks fail.

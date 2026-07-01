# Security Audit Fixes (M1, M2, L1, L3) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
>
> **Model requirement:** Dispatch all implementation subagents with **Sonnet 5** (`anthropic/claude-sonnet-5`).

**Goal:** Close four security-audit findings: narrow the Docker mount so the git checkout is not exposed to the Caddy container (M1), upgrade the pinned Hugo version (M2), add a `Permissions-Policy` header (L1), and fix stale AGENTS.md documentation (L3).

**Architecture:** Deploy artifacts move from repo-root `releases/` + `current` into a dedicated `site/` subdirectory on the server, so docker-compose can mount `./site:/srv:ro` instead of the whole checkout (`./:/srv:ro`). Caddy's `root * /srv/current` stays unchanged because `site/current` becomes `/srv/current` inside the container. The Hugo upgrade requires migrating deprecated `config.yaml` options (`pygments*`, `blackfriday`) to the modern `markup.highlight` block.

**Tech Stack:** Hugo (static site), Caddy 2 (Caddyfile), Docker Compose, GitHub Actions, bash.

**Constraints / context for the implementer:**
- This repo has **no test framework**. Verification is: `hugo` builds, output greps, `caddy validate` via Docker, and shell greps. Run every verification command shown.
- `public/` is generated output and gitignored — never edit or commit it.
- Do **not** push to `main` unless the user explicitly approves; a push triggers a production deploy. Commit locally per task.
- Local `hugo` on PATH is v0.162.0 extended. Docker is available locally.
- Task 3 (M1) changes production layout. It includes a **manual server migration step the human must run** — do not skip documenting/confirming it.

---

### Task 1: M2 — Upgrade pinned Hugo version and migrate config

**Files:**
- Modify: `.github/workflows/deploy_production.yml:20` (the `HUGO_VERSION` env)
- Modify: `config.yaml` (remove deprecated options, add `markup.highlight`)

- [ ] **Step 1: Determine the latest stable Hugo version**

Run:
```bash
curl -fsS https://api.github.com/repos/gohugoio/hugo/releases/latest | grep '"tag_name"'
```
Expected: a line like `"tag_name": "v0.1XX.Y",`. Record the version **without** the `v` prefix (referred to as `<NEW_VERSION>` below). Hardcode the actual number in all following steps — do not leave variables in committed files.

- [ ] **Step 2: Download that Hugo Extended binary for local verification**

```bash
mkdir -p /tmp/opencode/hugo-new
curl -fsSL "https://github.com/gohugoio/hugo/releases/download/v<NEW_VERSION>/hugo_extended_<NEW_VERSION>_linux-amd64.tar.gz" -o /tmp/opencode/hugo-new/hugo.tar.gz
tar -xzf /tmp/opencode/hugo-new/hugo.tar.gz -C /tmp/opencode/hugo-new
/tmp/opencode/hugo-new/hugo version
```
Expected: `hugo v<NEW_VERSION>+extended linux/amd64 ...`

If the asset name 404s, list assets with `curl -fsS https://api.github.com/repos/gohugoio/hugo/releases/latest | grep browser_download_url` and pick the `hugo_extended_<NEW_VERSION>_linux-amd64.tar.gz` URL from there.

- [ ] **Step 3: Establish a failing baseline — build with the new Hugo before config migration**

```bash
cd /home/dh/projects/weblog
/tmp/opencode/hugo-new/hugo --logLevel warn
```
Expected: warnings or errors about deprecated config (`pygmentsCodefences`, `pygmentsUseClasses`, `blackfriday`). If it builds completely clean with zero deprecation warnings, note that in the task report and continue — the config migration below is still correct modernization.

- [ ] **Step 4: Migrate `config.yaml`**

Replace the entire contents of `config.yaml` with:

```yaml
baseurl: "/"
locale: "en-us"
title: "webcodr"
theme: "webcodr"
permalinks:
  post: /:year/:month/:slug/
canonifyURLs: true
enableRobotsTXT: true
staticDir: ["static"]
markup:
  highlight:
    codeFences: true
    noClasses: false
sitemap:
  changefreq: monthly
  filename: sitemap.xml
  priority: 0.5
pagination.pagerSize: 5
```

(Removed: `metaDataFormat` — long ignored; `pygmentsCodefences`/`pygmentsUseClasses` — replaced by `markup.highlight.codeFences`/`noClasses: false`; `blackfriday` block — the Blackfriday renderer was removed from Hugo years ago.)

- [ ] **Step 5: Verify the build with the new Hugo and migrated config**

```bash
cd /home/dh/projects/weblog
rm -rf public
/tmp/opencode/hugo-new/hugo --logLevel warn
test -f public/index.html && echo BUILD_OK
```
Expected: `BUILD_OK`, no deprecation warnings or errors.

- [ ] **Step 6: Verify syntax highlighting still uses CSS classes (not inline styles)**

The CSP (`style-src 'self'`) forbids inline styles, so highlighted code must render with classes:

```bash
rg -l 'class="highlight"' public/ | head -3
rg -c 'style="' public/2024/03/cli-tools/index.html || echo NO_INLINE_STYLES
```
Expected: at least one file listed by the first command; `NO_INLINE_STYLES` (or `0`) from the second. If inline styles appear, `noClasses: false` was not applied — fix `config.yaml` before proceeding.

- [ ] **Step 7: Update the workflow's pinned version**

In `.github/workflows/deploy_production.yml` change line 20:

```yaml
      HUGO_VERSION: "0.162.0"
```
to
```yaml
      HUGO_VERSION: "<NEW_VERSION>"
```

- [ ] **Step 8: Verify old build with old Hugo still not referenced anywhere else**

```bash
rg -n "0\.162\.0" --hidden --glob '!.git' --glob '!docs/superpowers/**' .
```
Expected: no matches (docs/plans may mention it historically; those are excluded and fine).

- [ ] **Step 9: Commit**

```bash
git add config.yaml .github/workflows/deploy_production.yml
git commit -m "chore: upgrade Hugo to <NEW_VERSION> and migrate deprecated config"
```

---

### Task 2: L1 — Add Permissions-Policy header to Caddyfile

**Files:**
- Modify: `Caddyfile:1-10` (the `security_headers` snippet)

- [ ] **Step 1: Add the header**

In `Caddyfile`, inside the `(security_headers)` block, add one line after the `Referrer-Policy` line:

```caddyfile
(security_headers) {
	header {
		Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
		X-Content-Type-Options "nosniff"
		X-Frame-Options "DENY"
		Referrer-Policy "strict-origin-when-cross-origin"
		Permissions-Policy "camera=(), microphone=(), geolocation=(), interest-cohort=()"
		Content-Security-Policy "default-src 'self'; img-src 'self' data:; style-src 'self'; script-src 'self'; font-src 'self'; object-src 'none'; frame-ancestors 'none'; base-uri 'self'; form-action 'self'; upgrade-insecure-requests"
		-Server
	}
}
```

Note: the file uses **tabs** for indentation — preserve them.

- [ ] **Step 2: Validate the Caddyfile with the exact pinned production image**

```bash
cd /home/dh/projects/weblog
docker run --rm -v "$PWD/Caddyfile:/etc/caddy/Caddyfile:ro" caddy:2.11.4-alpine@sha256:5f5c8640aae01df9654968d946d8f1a56c497f1dd5c5cda4cf95ab7c14d58648 caddy validate --config /etc/caddy/Caddyfile
```
Expected: output ends with `Valid configuration`.

- [ ] **Step 3: Commit**

```bash
git add Caddyfile
git commit -m "security: add Permissions-Policy header"
```

---

### Task 3: M1 — Narrow the Docker mount to a dedicated `site/` directory

**Files:**
- Modify: `.github/workflows/deploy_production.yml:64-71` (prepare script), `:79` (rsync path), `:87-104` (activate script)
- Modify: `docker-compose.yml:17` (mount)
- Modify: `.gitignore`

Design: on the server, releases move from `~/projects/weblog/releases/` to `~/projects/weblog/site/releases/`, and the `current` symlink from `~/projects/weblog/current` to `~/projects/weblog/site/current`. `RELEASE_PATH`/`TEMP_RELEASE_PATH` stay **relative** (`releases/<ts>-<sha>`), the remote scripts just `cd` into `site/` instead of the repo root, so the symlink target stays relative and resolves correctly inside the container (`/srv/current` → `/srv/releases/<ts>-<sha>`). Caddyfile needs no change.

- [ ] **Step 1: Update the "Prepare remote release directory" step**

In `.github/workflows/deploy_production.yml`, change the heredoc body of the prepare step (lines 64–71). Old:

```yaml
          ssh -i ~/.ssh/deploy_key "$REMOTE" "bash -s -- '$TEMP_RELEASE_PATH'" <<'REMOTE_SCRIPT'
          set -eu
          TEMP_RELEASE_PATH=$1
          cd ~/projects/weblog
          mkdir -p releases
          rm -rf "$TEMP_RELEASE_PATH"
          mkdir -p "$TEMP_RELEASE_PATH"
          REMOTE_SCRIPT
```

New:

```yaml
          ssh -i ~/.ssh/deploy_key "$REMOTE" "bash -s -- '$TEMP_RELEASE_PATH'" <<'REMOTE_SCRIPT'
          set -eu
          TEMP_RELEASE_PATH=$1
          mkdir -p ~/projects/weblog/site/releases
          cd ~/projects/weblog/site
          rm -rf "$TEMP_RELEASE_PATH"
          mkdir -p "$TEMP_RELEASE_PATH"
          REMOTE_SCRIPT
```

- [ ] **Step 2: Update the rsync destination**

Change line 79. Old:

```yaml
          rsync -az --delete -e "ssh -i ~/.ssh/deploy_key" public/ "${REMOTE}:~/projects/weblog/${TEMP_RELEASE_PATH}/"
```

New:

```yaml
          rsync -az --delete -e "ssh -i ~/.ssh/deploy_key" public/ "${REMOTE}:~/projects/weblog/site/${TEMP_RELEASE_PATH}/"
```

- [ ] **Step 3: Update the "Activate release" step**

Change one line in the activate heredoc (line 91). Old:

```yaml
          cd ~/projects/weblog
```

New:

```yaml
          cd ~/projects/weblog/site
```

Everything else in that script (symlink flip, retention, verification) is path-relative and stays byte-identical.

- [ ] **Step 4: Update the docker-compose mount**

In `docker-compose.yml`, change line 17. Old:

```yaml
      - ./:/srv:ro
```

New:

```yaml
      - ./site:/srv:ro
```

Leave the `./Caddyfile` mount (line 16) untouched — it mounts a single file, not the checkout.

- [ ] **Step 5: Update .gitignore**

Replace the contents of `.gitignore` with:

```
public/
.idea/
.worktrees/
current
releases/
site/
```

(Keep `current` and `releases/` until the old directories are cleaned off the server; `site/` covers the new layout.)

- [ ] **Step 6: Verify workflow syntax and path consistency**

```bash
cd /home/dh/projects/weblog
ruby -ryaml -e "YAML.load_file('.github/workflows/deploy_production.yml'); YAML.load_file('docker-compose.yml'); puts 'YAML_OK'"
rg -n "projects/weblog" .github/workflows/deploy_production.yml
```
Expected: `YAML_OK`; every `~/projects/weblog` occurrence in the workflow is followed by `/site` except none should remain bare (all three remote-touching steps must show `site`).

- [ ] **Step 7: Validate compose file with Docker**

```bash
docker compose config -q && echo COMPOSE_OK
```
Expected: `COMPOSE_OK`. (A warning about the relative `../../caddy_data` path resolving locally is acceptable; an error is not.)

- [ ] **Step 8: Commit**

```bash
git add .github/workflows/deploy_production.yml docker-compose.yml .gitignore
git commit -m "security: mount only site/ into Caddy container instead of full checkout"
```

- [ ] **Step 9: Record the manual server migration procedure (do NOT execute — human runs this)**

Report the following runbook to the user verbatim; it must run **after** this change is merged and the first deploy to `main` has succeeded (which creates `site/current` on the server), giving a zero-downtime cutover:

```bash
# On the production server (shell may be fish; run via bash):
bash -s <<'EOF'
set -eu
cd ~/projects/weblog
git pull
test -f site/current/index.html   # new layout populated by the first post-merge deploy
docker compose up -d --force-recreate caddy
curl -fsS -o /dev/null -w '%{http_code}\n' https://webcodr.io/   # expect 200
# Optional cleanup once verified:
rm -rf ~/projects/weblog/releases ~/projects/weblog/current
EOF
```

---

### Task 4: L3 — Fix stale AGENTS.md documentation

**Files:**
- Modify: `AGENTS.md`

Depends on: Task 3 (documents the new `site/` layout).

- [ ] **Step 1: Remove the stale CMS bullet**

In `AGENTS.md`, under `## Content`, delete this line (the CMS files were removed in commit `016009d` and no longer exist):

```markdown
- `static/admin/config.yml` is the CMS config: it writes posts to `content/post`, media to `static/images`, and targets the `main` branch.
```

- [ ] **Step 2: Update the deployment paths**

Under `## Deployment`, replace:

```markdown
- Pushes to `main` or manual `workflow_dispatch` runs trigger GitHub Actions to build with Hugo, upload `public/` to `~/projects/weblog/releases/<sha>/`, and atomically repoint `~/projects/weblog/current`.
```

with:

```markdown
- Pushes to `main` or manual `workflow_dispatch` runs trigger GitHub Actions to build with Hugo, upload `public/` to `~/projects/weblog/site/releases/<timestamp>-<sha>/`, and atomically repoint `~/projects/weblog/site/current`.
```

and replace:

```markdown
- `docker-compose.yml` mounts the repo at `/srv` read-only and Caddy serves `/srv/current`; Caddy config is in `Caddyfile` for `webcodr.io`, `www.webcodr.io`, `webcodr.dev`, and `www.webcodr.dev`.
```

with:

```markdown
- `docker-compose.yml` mounts only `./site` at `/srv` read-only (the git checkout is not exposed to the container) and Caddy serves `/srv/current`; Caddy config is in `Caddyfile` for `webcodr.io`, `www.webcodr.io`, `webcodr.dev`, and `www.webcodr.dev`.
```

- [ ] **Step 3: Update the CI Hugo version reference**

Under `## Commands`, replace:

```markdown
- Requires the Hugo CLI on `PATH` for local verification; CI pins Hugo Extended `0.162.0` for production builds.
```

with (substituting the version chosen in Task 1):

```markdown
- Requires the Hugo CLI on `PATH` for local verification; CI pins Hugo Extended `<NEW_VERSION>` for production builds.
```

- [ ] **Step 4: Verify no stale references remain**

```bash
rg -n "static/admin|releases/<sha>|mounts the repo at" AGENTS.md; echo "exit: $?"
```
Expected: `exit: 1` (no matches).

- [ ] **Step 5: Commit**

```bash
git add AGENTS.md
git commit -m "docs: update AGENTS.md for site/ deploy layout, Hugo bump, removed CMS"
```

---

### Task 5: Final verification

- [ ] **Step 1: Full clean build with the new Hugo**

```bash
cd /home/dh/projects/weblog
rm -rf public
/tmp/opencode/hugo-new/hugo
test -f public/index.html && echo BUILD_OK
```
Expected: `BUILD_OK`, zero errors.

- [ ] **Step 2: Confirm nothing generated or unintended is staged/committed**

```bash
git status --short
git log --oneline -5
```
Expected: clean tree (no `public/` entries); four new commits (Tasks 1–4).

- [ ] **Step 3: Report to the user**

Summarize the four commits and repeat the Task 3 Step 9 server migration runbook. Explicitly state that **pushing to `main` triggers a production deploy** and that the server cutover (`docker compose up -d --force-recreate caddy`) must happen after the first successful post-merge deploy. Do not push without the user's go-ahead.

# Serverless Hugo Deploy Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Move Hugo builds from the production server to GitHub Actions and deploy prebuilt static releases via an atomic `current` symlink.

**Architecture:** GitHub Actions installs Hugo Extended `0.162.0`, runs `hugo`, uploads `public/` to a release directory on the server, and atomically repoints `current`. Caddy serves `/srv/current` from a read-only bind mount of the repository root so the `current` symlink is resolved inside the container after each deploy.

**Tech Stack:** Hugo Extended `0.162.0`, GitHub Actions, SSH, rsync, Docker Compose, Caddy 2.10.

---

## File Structure

- Modify `.github/workflows/deploy_production.yml`: replace server-side `git pull && hugo` with Actions-side Hugo build, SSH setup, rsync upload, atomic symlink switch, release pruning, and smoke verification.
- Modify `docker-compose.yml`: mount the repository root read-only at `/srv` instead of mounting `./public` directly.
- Modify `Caddyfile`: set the static root for both primary domains to `/srv/current` so Caddy resolves the live symlink inside the container.
- Modify `AGENTS.md`: update repo instructions so future agents know production builds happen in GitHub Actions and Caddy serves `./current`.

## Important Implementation Note

Do not bind-mount `./current` directly as `/srv`. Docker can resolve a symlink bind source when the container starts, which can leave Caddy serving the old release after `current` is repointed. Mount the repository root at `/srv:ro` and configure Caddy with `root * /srv/current` instead.

### Task 1: Serve The Current Release Symlink

**Files:**
- Modify: `docker-compose.yml`
- Modify: `Caddyfile`

- [ ] **Step 1: Update the Docker volume**

Replace the Caddy content volume in `docker-compose.yml` with a read-only mount of the repository root.

```yaml
services:
  caddy:
    image: caddy:2.10.0-alpine
    restart: unless-stopped
    cap_add:
      - NET_ADMIN
    ports:
      - "80:80"
      - "443:443"
      - "443:443/udp"
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile
      - ./:/srv:ro
      - ./../../caddy_data:/data
      - ./../../caddy_config:/config
    networks:
      - caddy

networks:
  caddy:
    enable_ipv6: true
```

- [ ] **Step 2: Point Caddy at `/srv/current`**

Update `Caddyfile` so both served domains use `/srv/current` as their document root.

```caddyfile
webcodr.io {
  root * /srv/current
  encode zstd gzip
  header /fonts/* Cache-Control max-age=31536000
  header /js/* Cache-Control max-age=31536000
  header /css/* Cache-Control max-age=31536000
  file_server
}

www.webcodr.io {
  redir https://webcodr.io{uri} permanent
}

webcodr.dev {
  root * /srv/current
  encode zstd gzip
  header /fonts/* Cache-Control max-age=31536000
  header /js/* Cache-Control max-age=31536000
  header /css/* Cache-Control max-age=31536000
  file_server
}

www.webcodr.dev {
  redir https://webcodr.dev{uri} permanent
}
```

- [ ] **Step 3: Validate Docker Compose syntax**

Run:

```bash
docker compose config
```

Expected: exit code `0` and normalized Compose YAML that includes a project path bind mount ending in `:/srv:ro`.

- [ ] **Step 4: Commit the serving stack change**

Run:

```bash
git add docker-compose.yml Caddyfile
git commit -m "feat: serve current release symlink"
```

### Task 2: Build And Deploy From GitHub Actions

**Files:**
- Modify: `.github/workflows/deploy_production.yml`

- [ ] **Step 1: Replace the production workflow**

Replace `.github/workflows/deploy_production.yml` with this content:

```yaml
name: Deploy on Main Branch or Manually

on:
  push:
    branches:
      - main
  workflow_dispatch:

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: production
    env:
      HUGO_VERSION: "0.162.0"
      RELEASE_PATH: releases/${{ github.sha }}
      TEMP_RELEASE_PATH: releases/.${{ github.sha }}.${{ github.run_id }}.tmp

    steps:
      - name: Check out repository
        uses: actions/checkout@v4

      - name: Install Hugo
        uses: peaceiris/actions-hugo@v3
        with:
          hugo-version: ${{ env.HUGO_VERSION }}
          extended: true

      - name: Build site
        run: hugo

      - name: Verify build output
        run: test -f public/index.html

      - name: Install deploy dependencies
        run: sudo apt-get update && sudo apt-get install -y rsync openssh-client

      - name: Configure SSH
        run: |
          mkdir -p ~/.ssh
          printf '%s\n' "${{ secrets.SSH_KEY }}" > ~/.ssh/deploy_key
          chmod 600 ~/.ssh/deploy_key
          ssh-keyscan -H "${{ secrets.SSH_HOST }}" >> ~/.ssh/known_hosts

      - name: Prepare remote release directory
        run: |
          REMOTE="${{ secrets.SSH_USERNAME }}@${{ secrets.SSH_HOST }}"
          ssh -i ~/.ssh/deploy_key "$REMOTE" "cd ~/projects/weblog && mkdir -p releases && rm -rf '$TEMP_RELEASE_PATH' && mkdir -p '$TEMP_RELEASE_PATH'"

      - name: Upload built site
        run: |
          REMOTE="${{ secrets.SSH_USERNAME }}@${{ secrets.SSH_HOST }}"
          rsync -az --delete -e "ssh -i ~/.ssh/deploy_key" public/ "${REMOTE}:~/projects/weblog/${TEMP_RELEASE_PATH}/"

      - name: Activate release
        run: |
          REMOTE="${{ secrets.SSH_USERNAME }}@${{ secrets.SSH_HOST }}"
          ssh -i ~/.ssh/deploy_key "$REMOTE" "
            set -eu
            cd ~/projects/weblog
            test -f '$TEMP_RELEASE_PATH/index.html'
            if [ -e '$RELEASE_PATH' ]; then
              test -f '$RELEASE_PATH/index.html'
              rm -rf '$TEMP_RELEASE_PATH'
            else
              mv '$TEMP_RELEASE_PATH' '$RELEASE_PATH'
            fi
            ln -sfn '$RELEASE_PATH' current-new
            mv -Tf current-new current
            test \"\$(readlink current)\" = '$RELEASE_PATH'
            (ls -1dt releases/* 2>/dev/null | tail -n +6 | xargs -r rm -rf) || true
          "

      - name: Smoke test production
        run: curl -fsS https://webcodr.io/ >/dev/null
```

- [ ] **Step 2: Review the workflow for server-side Hugo removal**

Run:

```bash
grep -n "git pull\|hugo" .github/workflows/deploy_production.yml
```

Expected: output includes the Actions-side Hugo install/build steps and does not include `git pull` or an SSH script that runs `hugo` on the server.

- [ ] **Step 3: Verify the site still builds locally**

Run:

```bash
hugo
```

Expected: exit code `0`, `Pages` count is reported, and `public/index.html` exists.

- [ ] **Step 4: Commit the workflow change**

Run:

```bash
git add .github/workflows/deploy_production.yml
git commit -m "ci: deploy prebuilt Hugo releases"
```

### Task 3: Update Repository Instructions

**Files:**
- Modify: `AGENTS.md`

- [ ] **Step 1: Replace outdated build and deploy guidance**

Replace `AGENTS.md` with this content:

```markdown
# Repository Instructions

## Project Shape
- This is a Hugo static site with no `package.json` or package-manager workflow; production builds run in GitHub Actions via `.github/workflows/deploy_production.yml`.
- The active theme is the local `themes/webcodr` theme from `config.yaml`; layouts live under `themes/webcodr/layouts/`, while fingerprinted CSS/JS sources live in root `assets/css/webcodr.css` and `assets/js/webcodr.js`.
- `public/` is generated build output and is gitignored; do not edit or commit it.

## Commands
- Requires the Hugo CLI on `PATH` for local verification; CI pins Hugo Extended `0.162.0` for production builds.
- Build/verify the site locally with `hugo`.
- For local preview, use Hugo's dev server from the repo root: `hugo server`.
- There is no configured test, lint, typecheck, formatter, or asset-bundler command in this repo.
- `k6/load-test.js` is a standalone production URL load check, not part of CI or the Hugo build.

## Content
- Blog posts live in `content/post/`; `create_post.fish` and `create_post.ps1` create files named `content/post/YYYY-MM-DD_slug.md` with `title` and UTC `date` front matter.
- The about page is `content/about/index.md`.
- `static/admin/config.yml` is the CMS config: it writes posts to `content/post`, media to `static/images`, and targets the `main` branch.

## Deployment
- Pushes to `main` or manual `workflow_dispatch` runs trigger GitHub Actions to build with Hugo, upload `public/` to `~/projects/weblog/releases/<sha>/`, and atomically repoint `~/projects/weblog/current`.
- The production server should not need Hugo installed for deploys; it only needs SSH, the repo checkout, the prepared `releases/` directory, the `current` symlink, Docker, and Caddy.
- `docker-compose.yml` mounts the repo at `/srv` read-only and Caddy serves `/srv/current`; Caddy config is in `Caddyfile` for `webcodr.io`, `www.webcodr.io`, `webcodr.dev`, and `www.webcodr.dev`.
```

- [ ] **Step 2: Commit the instruction update**

Run:

```bash
git add AGENTS.md
git commit -m "docs: update deployment instructions"
```

### Task 4: Final Verification

**Files:**
- Verify: `.github/workflows/deploy_production.yml`
- Verify: `docker-compose.yml`
- Verify: `Caddyfile`
- Verify: `AGENTS.md`

- [ ] **Step 1: Run the Hugo build**

Run:

```bash
hugo
```

Expected: exit code `0`, no Hugo errors, and a generated `public/index.html`.

- [ ] **Step 2: Validate Compose syntax**

Run:

```bash
docker compose config
```

Expected: exit code `0`. If Docker is not available in the local environment, record that this verification must run on a machine with Docker before deployment.

- [ ] **Step 3: Confirm the workflow no longer builds on the server**

Run:

```bash
grep -n "git pull\|cd ~/projects/weblog.*hugo\|hugo$" .github/workflows/deploy_production.yml
```

Expected: no `git pull`; no SSH command that runs `hugo` on the server; the only Hugo usage is the Actions-side `Build site` step.

- [ ] **Step 4: Review the final diff**

Run:

```bash
git diff HEAD~3..HEAD -- .github/workflows/deploy_production.yml docker-compose.yml Caddyfile AGENTS.md
```

Expected: diff shows only the serving stack change, deployment workflow rewrite, and instruction update.

- [ ] **Step 5: Check working tree status**

Run:

```bash
git status --short
```

Expected: no uncommitted changes except generated `public/` output, which is ignored.

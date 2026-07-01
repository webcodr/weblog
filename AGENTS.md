# Repository Instructions

## Project Shape
- This is a Hugo static site with no `package.json` or package-manager workflow; production builds run in GitHub Actions via `.github/workflows/deploy_production.yml`.
- The active theme is the local `themes/webcodr` theme from `config.yaml`; layouts live under `themes/webcodr/layouts/`, while fingerprinted CSS/JS sources live in root `assets/css/webcodr.css` and `assets/js/webcodr.js`.
- `public/` is generated build output and is gitignored; do not edit or commit it.

## Commands
- Requires the Hugo CLI on `PATH` for local verification; CI pins Hugo Extended `0.163.3` for production builds.
- Build/verify the site locally with `hugo`.
- For local preview, use Hugo's dev server from the repo root: `hugo server`.
- There is no configured test, lint, typecheck, formatter, or asset-bundler command in this repo.
- `k6/load-test.js` is a standalone production URL load check, not part of CI or the Hugo build.

## Content
- Blog posts live in `content/post/`; `create_post.fish` and `create_post.ps1` create files named `content/post/YYYY-MM-DD_slug.md` with `title` and UTC `date` front matter.
- The about page is `content/about/index.md`.

## Deployment
- Pushes to `main` or manual `workflow_dispatch` runs trigger GitHub Actions to build with Hugo, upload `public/` to `~/projects/weblog/site/releases/<timestamp>-<sha>/`, and atomically repoint `~/projects/weblog/site/current`.
- The production server should not need Hugo installed for deploys; it only needs SSH, the repo checkout, the prepared `site/releases/` directory, the `site/current` symlink, Docker, and Caddy.
- The production account's login shell may be fish; remote SSH scripts in GitHub Actions should explicitly invoke `bash -s` before using POSIX shell syntax.
- `docker-compose.yml` mounts only `./site` at `/srv` read-only (the git checkout is not exposed to the container) and Caddy serves `/srv/current`; Caddy config is in `Caddyfile` for `webcodr.io`, `www.webcodr.io`, `webcodr.dev`, and `www.webcodr.dev`.
- During the one-time migration from root-level `current`/`releases` to `site/current`/`site/releases`, the first post-change CI smoke test can still verify the old running container; only treat the cutover as complete after recreating Caddy and getting a 200 from production.

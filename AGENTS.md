# Repository Instructions

## Project Shape
- This is a Hugo static site with no `package.json` or package-manager workflow; the production build is the plain `hugo` command used by `.github/workflows/deploy_production.yml`.
- The active theme is the local `themes/webcodr` theme from `config.yaml`; layouts live under `themes/webcodr/layouts/`, while fingerprinted CSS/JS sources live in root `assets/css/webcodr.css` and `assets/js/webcodr.js`.
- `public/` is generated build output and is gitignored; do not edit or commit it.

## Commands
- Requires the Hugo CLI on `PATH`; this repo does not include a wrapper, containerized build command, or package-manager install step.
- Build/verify the site exactly as deployment does: `hugo`.
- For local preview, use Hugo's dev server from the repo root: `hugo server`.
- There is no configured test, lint, typecheck, formatter, or asset-bundler command in this repo.

## Content
- Blog posts live in `content/post/`; the helper scripts create files named `content/post/YYYY-MM-DD_slug.md` with `title` and UTC `date` front matter.
- The about page is `content/about/index.md`.
- `static/admin/config.yml` is the CMS config: it writes posts to `content/post`, media to `static/images`, and targets the `main` branch.

## Deployment
- Pushes to `main` trigger the GitHub Action, which SSHes to the production host, runs `git pull`, then `hugo` in `~/projects/weblog`.
- `docker-compose.yml` serves `./public` through Caddy; Caddy config is in `Caddyfile` for `webcodr.io`, `www.webcodr.io`, `webcodr.dev`, and `www.webcodr.dev`.

# Repository Review — 2026-07-17

Full-site review of config/content, theme, front-end assets, and CI/CD. All findings
verified against source files and built output (Hugo Extended 0.164.0, the CI-pinned
version; build passes with zero warnings).

## High — user-visible bugs

### 1. RSS/JSON Feed summaries double-escape HTML entities

- `themes/webcodr/layouts/_default/rss.xml:23` — `.Summary | plainify | html`
- `themes/webcodr/layouts/_default/list.jsonfeed.json:18` — same pattern

`plainify` strips tags but keeps entity text (`&rsquo;`), which then gets re-escaped,
so feed readers display the literal string `&rsquo;`. Verified in built output:
37× `&amp;rsquo;` plus `&amp;hellip;`, `&amp;ldquo;` etc. in `index.xml`;
195 occurrences of `rsquo` in `feed.json` summaries.
Fix direction: use `.Plain`, or pipe through `htmlUnescape` before re-escaping.

### 2. About page leaks into the home post listing

- `themes/webcodr/layouts/index.html:9` paginates unfiltered `.Site.RegularPages`

Verified: the About page renders as a blog post entry on `/page/7/`.
`themes/webcodr/layouts/archive/list.html:10` correctly filters
`where .Site.RegularPages "Type" "post"` — make index consistent. Feeds are only
spared because About is dated 2017 and falls outside the 20-item RSS limit.

## Medium

### 3. Production sitemap has relative URLs

- `config.yaml:1` — `baseurl: "/"` → `sitemap.xml` contains `<loc>/topics/...</loc>`,
  violating the sitemap protocol (absolute URLs required). `robots.txt`
  (`enableRobotsTXT: true`, `config.yaml:16`) has no `Sitemap:` line. The theme
  compensates everywhere else by hardcoding `https://webcodr.io`, but the internal
  sitemap/robots templates don't.

### 4. Light-theme WCAG contrast failures (dark theme passes everywhere, 6.8–10.6:1)

- Syntax comments `#a1a6c5` on `#e1e2e7` = **1.85:1** (`assets/css/webcodr.css:356,384`)
- Content links `#2e7de9` on `#e1e2e7` = **3.11:1** (css:374, 862; AA needs 4.5:1)
- Inline code `#b15c00` on `#d0d5e3` = **3.25:1** (css:380, 979–980)
- Meta text `#6172b0` on `#e1e2e7` = **3.57:1** (css:371/373)

### 5. No rollback on smoke-test failure

- `.github/workflows/deploy_production.yml:113-116` — if the post-deploy curl smoke
  test fails, the workflow fails but the new (possibly broken) release stays live.
  Rollback is manual-only via SSH (5 releases retained).

### 6. Immutable caching on unversioned assets

- `Caddyfile:17,20` — `/fonts/*` and `/icons/*` get `max-age=31536000, immutable`,
  but those are static unfingerprinted files (`themes/webcodr/static/fonts/*.woff2`,
  `static/icons/*.svg`). An in-place update would be invisible to returning clients
  for up to a year. `/css/*` and `/js/*` are fine (Hugo-fingerprinted).

### 7. Orphaned temp release dirs never pruned

- `deploy_production.yml:27,110` — uploads go to hidden `releases/.<ts>...tmp` dirs,
  but pruning globs `releases/*`, which skips dotfiles → failed uploads accumulate.

### 8. Keyboard users cannot scroll code blocks

- Hugo emits `<pre tabindex="0" class="chroma">`, but the CSS makes the inner
  `<code>` the scroll container (`assets/css/webcodr.css:962`). Focus lands on the
  non-scrollable `<pre>`; the `code:focus-visible` scrollbar reveal (css:967) can
  never trigger. Also: copy button uses `:focus` with no outline (css:1053–1058).

## Low

### Templates / config

- **Empty `_default/list.html`** (0 bytes) — latent trap; with
  `content/post/_index.md` (`build: render: never`) in place, deleting is safe.
- **Duplicate `<title>` on all paginated pages** — `head.html:8`; `/page/2/`…`/page/11/`
  all titled "webcodr" (canonicals do differ).
- **Dead config reference** — `seo.html:3` falls back to `site.Params.ogImage`,
  which doesn't exist in `config.yaml`.
- **Fragile image URL prefixing** — `seo.html:17,31` blindly prefix the domain; a post
  setting `image:` to an absolute URL would produce `https://webcodr.iohttps://...`
  (no post does today — latent).
- **RSS cosmetics** — no XML prolog; dates render as `&#43;0000` (rss.xml:15,21).
- **Inconsistent series-name handling** — `head.html:53` applies `humanize | title`
  to term feed titles, mangling series names.
- **Redundant config keys** — `canonifyURLs: true` (config.yaml:15, no-op with
  `baseurl: "/"`) and `staticDir: ["static"]` (config.yaml:17, restates the default).
- **Theme archetype out of sync** — `themes/webcodr/archetypes/default.md` lacks
  `topics`/`description` and sets `draft: false`, unlike the create-post scripts and
  `tests/post-generators.sh`.
- **Stale `theme.toml`** — `min_version = 0.14` (actual requirement is far newer),
  placeholder homepage, empty `description`, `features = ["", ""]`.
- **No `baseof.html`** — full page shell duplicated across 7 templates; search form
  duplicated between `404.html:17-22` and `search/list.html:10-15`; post-meta line
  duplicated between `post.html:13-15` and `post-meta.html:1-3`; `<html lang="en">`
  hardcoded.
- **Pagination a11y nit** — `pagination.html:2` is a plain `<div>`; a
  `<nav aria-label="Pagination">` would match `post-navigation.html`.

### Front-end assets

- **`??=` misuse** — `assets/js/webcodr.js:110` mutates the language-alias map on
  every lookup; should be `??`.
- **Dead modulepreload polyfill** — `webcodr.js:1-33`; no modulepreload links exist
  in any built page.
- **Resize handler skips missing-`pre` guard** — `webcodr.js:240-245` could throw if
  a `code[data-lang]` lacked a `pre` ancestor (theoretical with current Hugo output);
  also not debounced.
- **`.woff` font fallbacks 404** — `@font-face` blocks reference `/fonts/*.woff`
  (css:449–510), only `.woff2` exist. Harmless in modern browsers (woff2 first).
- **Dead CSS** — `.post-link--meta` (css:776–778); effectively dead Chroma `.bg`
  rules (css:1419–1422, 1820–1823); redundant margin reset (css:1089–1092).
- **Inconsistent gutters** — hardcoded `10px` in header/footer/pagination/search vs
  `--mobile-gutter: 20px` for content.
- **Deprecated API** — `document.execCommand("copy")` fallback (webcodr.js:128).
- **Unused file** — `static/images/okti_boese.webp`.

### Content

- **Draft post with empty body** — `content/post/2026-07-12_alternatives-for-tmux.md`
  (correctly excluded from builds; don't publish as-is).
- **Cosmetic filename/front-matter date mismatches** in ~7 migrated posts (harmless —
  URLs derive from front matter; slugs verified clean in build output).

### CI/CD / infra

- **Unpinned npm supply chain at deploy** — `deploy_production.yml:44` runs
  `npx -y pagefind@1.5.2` with version pin but no integrity verification (no lockfile).
- **SSH key created with default umask** — `deploy_production.yml:60-61` writes the
  key before `chmod 600`; `umask 077` first would close the window.
- **No Cache-Control for HTML** — `Caddyfile`; browsers apply heuristic caching and
  may serve stale pages after a deploy.
- **`.gitignore` gaps** — missing `.hugo_build.lock` (untracked at repo root) and OS
  files; stale `current`/`releases/` entries from the pre-migration layout.
- **Redundant apt install** — `deploy_production.yml:52`; `rsync`/`openssh-client`
  are preinstalled on `ubuntu-24.04` runners (~20-30s per deploy).

## Verified good

- Atomic symlink-swap deploy (`ln -sfn` + `mv -Tf`) with `index.html` pre-validation;
  failure before rename leaves the old release live; live release can't be pruned.
- All GitHub Actions pinned to full commit SHAs; Hugo Extended 0.164.0 pinned
  consistently across workflows; Caddy image pinned by digest.
- Deploy concurrency `cancel-in-progress: false`; `permissions: {}` safe (public repo);
  secrets only via `env:` blocks; pinned `SSH_KNOWN_HOSTS`; quoted SSH heredocs.
- Caddyfile: www→apex 301s on both TLDs, automatic TLS, `encode zstd gzip`, tight CSP
  accommodating Pagefind WASM, custom 404 preserving status, hardened compose file
  (`cap_drop`, `no-new-privileges`, read-only mounts, no obsolete `version` key).
- Asset pipeline correct: `resources.Get` + sha512 fingerprint for CSS/JS; font
  preloads match files; OG-image resources exist; no stale asset references.
- Security: no `target="_blank"` gaps, no `http://` links (only XML namespaces),
  valid JSON-LD with contextual escaping, safe render hooks (alt/lazy/async on images).
- SEO: correct canonicals, RSS + JSON Feed autodiscovery everywhere, per-term RSS
  autodiscovery, generated 1200×630 OG images per post.
- All 15 partials referenced; no dead templates except empty `_default/list.html`.
- Theme/FOUC handling solid (synchronous `theme-init.js`, cross-tab sync,
  `color-scheme` per theme); German posts render `lang="de"` correctly.
- JS: all hooks verified against templates, null-guarded querySelectors, Pagefind
  failure path, no `console.*`/secrets/`!important`/TODOs.
- `enableGitInfo` + CI `fetch-depth: 0` keep git-based `lastmod` coherent.
- k6 load test sane (thresholds, 200-check, prod target).

## Suggested priority

1. Feed double-escaping (High #1) and About-page leak (High #2) — one-line template
   changes, only user-visible bugs.
2. Light-theme contrast (Medium #4) — palette tweak in the CSS light block.
3. Deploy hardening (Medium #5, #7) — rollback step + dotfile-aware pruning.
4. Cleanup pass on the Low items.

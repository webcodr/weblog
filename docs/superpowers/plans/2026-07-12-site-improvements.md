# Site Improvements Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship five independent improvements: per-page SEO/social metadata, a full-content RSS feed, an image render hook, heading anchor links, and Pagefind-based client-side search, plus git-derived sitemap freshness.

**Architecture:** All metadata is rendered at build time from front matter that already exists (`description`, `topics`, optional `lastmod`). Markdown render hooks own image and heading output. Search uses Pagefind's JS API with a hand-rolled UI (no PagefindUI bundle) so styling and CSP stay under our control; the index is generated in CI as a post-build step over `public/`, keeping the repo free of a package-manager workflow. Each task carries its own shell smoke test in `tests/` following the `blog-discovery.sh` pattern (build into a temp dir, assert generated HTML).

**Tech Stack:** Hugo Extended 0.163.x, Go templates, YAML, CSS (Tokyo Night custom properties in `assets/css/webcodr.css:323`), vanilla JS, Pagefind 1.3.x (CI-only via `npx`), Bash, Caddy, GitHub Actions

**Constraints discovered during design:**

- The Caddy CSP (`Caddyfile`) is `script-src 'self'` with no `unsafe-inline`: no inline event handlers, no inline executable scripts. JSON-LD is safe (non-executable data block). Pagefind's WebAssembly needs `'wasm-unsafe-eval'` added to `script-src`.
- `baseurl` is `/` (the site serves both webcodr.io and webcodr.dev); absolute URLs are hardcoded to `https://webcodr.io` following the existing canonical-link precedent in `head.html:79`.
- The 2026-07-12 metadata backfill touched every post, so git-derived lastmod is "today" for all posts. Therefore the visible "Updated" line in `post-meta.html` stays gated on explicit front matter `lastmod`; git info only feeds the sitemap and `article:modified_time`.
- Post images live in `static/images/` (not page bundles), so the image render hook reads dimensions with `imageConfig`/`fileExists` instead of Hugo's asset pipeline. No `srcset` — out of scope.
- Deploys only rsync `public/`; the `Caddyfile` change in Task 5 needs a one-time manual pull + Caddy reload on the production server.

---

## File Map

- Create `tests/seo-metadata.sh`: Assert titles, descriptions, OG/Twitter tags, JSON-LD, `lang` attributes, full-content RSS, and sitemap lastmod.
- Create `tests/content-rendering.sh`: Assert image attributes and heading anchors in generated post HTML.
- Create `tests/search.sh`: Assert search page markup, index scoping attributes, workflow step, and CSP.
- Modify `config.yaml`: Add `params.description`, `enableGitInfo`, and front matter lastmod priority.
- Modify `themes/webcodr/layouts/partials/head.html`: Per-page title/description, canonical refactor, SEO partial include, keywords removal.
- Create `themes/webcodr/layouts/partials/seo.html`: OG, Twitter, and JSON-LD output.
- Modify `themes/webcodr/layouts/_default/single.html`: Add `lang="en"`.
- Create `themes/webcodr/layouts/_default/rss.xml`: Full-content feed with absolute item URLs.
- Create `themes/webcodr/layouts/_default/_markup/render-image.html`: Lazy loading, async decoding, intrinsic dimensions.
- Create `themes/webcodr/layouts/_default/_markup/render-heading.html`: Anchor links on content headings.
- Create `content/search/_index.md` and `themes/webcodr/layouts/search/list.html`: The `/search/` page.
- Modify `themes/webcodr/layouts/partials/post.html`, `post-meta.html`, `table-of-contents.html`, `related-posts.html`, `post-navigation.html`: Pagefind body/ignore scoping.
- Modify `themes/webcodr/layouts/partials/header.html`: Search navigation link.
- Modify `assets/js/webcodr.js`: Search behavior via Pagefind JS API.
- Modify `assets/css/webcodr.css`: Heading anchor, search form/result, and image styles.
- Modify `.github/workflows/deploy_production.yml`: Full-history checkout, Pagefind index step, extended build verification.
- Modify `Caddyfile`: Add `'wasm-unsafe-eval'` to `script-src`.

---

### Task 1: Per-Page SEO And Social Metadata

**Files:**
- Create: `tests/seo-metadata.sh`
- Modify: `themes/webcodr/layouts/partials/head.html`
- Create: `themes/webcodr/layouts/partials/seo.html`
- Modify: `themes/webcodr/layouts/_default/single.html:2`
- Modify: `config.yaml`

- [x] **Step 1: Write the failing SEO smoke test**

Create `tests/seo-metadata.sh` reusing the helper functions from `tests/blog-discovery.sh:1-40` (`fail`, `assert_file`, `assert_contains`, `assert_not_contains`, plus the `hugo --source "$root" --destination "$output" --quiet` build):

```bash
srchr="$output/2026/07/find-things-even-faster-with-srchr/index.html"

assert_contains "$output/index.html" '<title>webcodr</title>'
assert_contains "$output/index.html" '<meta property="og:type" content="website" />'
assert_contains "$srchr" '<html lang="en">'
assert_contains "$srchr" '<title>Find things even faster with srchr · webcodr</title>'
assert_contains "$srchr" 'content="A cross-platform Rust TUI for finding files and searching their contents."'
assert_not_contains "$srchr" 'covers a wide range of programming topics'
assert_contains "$srchr" '<meta property="og:title" content="Find things even faster with srchr" />'
assert_contains "$srchr" '<meta property="og:type" content="article" />'
assert_contains "$srchr" '<meta property="og:url" content="https://webcodr.io/2026/07/find-things-even-faster-with-srchr/" />'
assert_contains "$srchr" '<meta property="article:published_time" content="2026-07-05T20:28:50Z" />'
assert_contains "$srchr" '<meta name="twitter:card" content="summary" />'
assert_contains "$srchr" 'application/ld+json'
assert_contains "$srchr" '"@type": "BlogPosting"'
assert_not_contains "$output/index.html" 'name="keywords"'

printf 'SEO metadata checks passed.\n'
```

- [x] **Step 2: Run the test and verify RED**

Run: `bash tests/seo-metadata.sh`

Expected: FAIL on the home page title (currently just the raw `.Title` without site-title logic and with the old keywords meta present).

- [x] **Step 3: Move the site description into config**

Add to `config.yaml`:

```yaml
params:
  description: >-
    WebCodr is a blog that covers a wide range of programming topics,
    including the Kotlin and Rust programming languages and ways to improve
    developer productivity.
```

- [x] **Step 4: Rework `head.html`**

Restructure `themes/webcodr/layouts/partials/head.html`: hoist the existing pagination-aware permalink logic (currently lines 70-79) above `<head>`, derive title/description, delegate social tags to a new partial, and drop the keywords meta:

```html
{{ $css := resources.Get "css/webcodr.css" | resources.Fingerprint "sha512"}}
{{ $js := resources.Get "js/webcodr.js" | resources.Fingerprint "sha512"}}

{{ $permalink := .Permalink }}
{{ if .IsHome }}
  {{ $paginator := .Paginate .Site.RegularPages }}
  {{ if ne $paginator.PageNumber 1 }}
    {{ $permalink = print $permalink "page/" $paginator.PageNumber "/" }}
  {{ end }}
{{ end }}
{{ $canonical := print "https://webcodr.io" $permalink }}
{{ $title := site.Title }}
{{ if not .IsHome }}{{ $title = print .Title " · " site.Title }}{{ end }}
{{ $description := .Description | default site.Params.description }}

<head>
  <title>{{ $title }}</title>
  ...
  <meta name="description" content="{{ $description }}" />
  {{ partial "seo.html" (dict "page" . "canonical" $canonical "title" $title "description" $description) }}
  ...
  <link rel="canonical" href="{{ $canonical }}">
</head>
```

Keep the stylesheet, viewport, charset, RSS alternate, font preloads, and script tags exactly as they are (elided as `...` above). Remove the `name="keywords"` meta entirely.

- [x] **Step 5: Create the SEO partial**

Create `themes/webcodr/layouts/partials/seo.html`:

```html
{{ $page := .page }}
{{ $isPost := and $page.IsPage (eq $page.Type "post") }}
{{ $image := $page.Params.image | default site.Params.ogImage }}
<meta property="og:site_name" content="{{ site.Title }}" />
<meta property="og:title" content="{{ $page.Title | default site.Title }}" />
<meta property="og:description" content="{{ .description }}" />
<meta property="og:url" content="{{ .canonical }}" />
<meta property="og:type" content="{{ if $isPost }}article{{ else }}website{{ end }}" />
{{ with $image }}
  <meta property="og:image" content="https://webcodr.io{{ . }}" />
{{ end }}
{{ if $isPost }}
  <meta property="article:published_time" content="{{ $page.Date.Format "2006-01-02T15:04:05Z07:00" }}" />
  {{ if ne ($page.Date.Format "2006-01-02") ($page.Lastmod.Format "2006-01-02") }}
    <meta property="article:modified_time" content="{{ $page.Lastmod.Format "2006-01-02T15:04:05Z07:00" }}" />
  {{ end }}
{{ end }}
<meta name="twitter:card" content="{{ if $image }}summary_large_image{{ else }}summary{{ end }}" />
<meta name="twitter:title" content="{{ $page.Title | default site.Title }}" />
<meta name="twitter:description" content="{{ .description }}" />
{{ if $isPost }}
  <script type="application/ld+json">
  {
    "@context": "https://schema.org",
    "@type": "BlogPosting",
    "headline": {{ $page.Title | jsonify }},
    "description": {{ .description | jsonify }},
    "url": {{ .canonical | jsonify }},
    "datePublished": {{ $page.Date.Format "2006-01-02T15:04:05Z07:00" | jsonify }},
    "dateModified": {{ $page.Lastmod.Format "2006-01-02T15:04:05Z07:00" | jsonify }},
    "author": { "@type": "Person", "name": "David Henning" }
  }
  </script>
{{ end }}
```

Notes: `og:image` is emitted only when a per-post `image` front matter param or a site-wide `params.ogImage` exists — neither is set today, so no tags render until an image is chosen (deliberate; picking/creating a default OG image is a content decision, not part of this plan). The JSON-LD block is a non-executable data script and passes the CSP.

- [x] **Step 6: Fix the missing lang attribute**

In `themes/webcodr/layouts/_default/single.html:2` change `<html>` to `<html lang="en">`.

- [x] **Step 7: Run the test and verify GREEN**

Run: `bash tests/seo-metadata.sh`

Expected: `SEO metadata checks passed.`

- [x] **Step 8: Run the full site verification**

Run: `bash tests/blog-discovery.sh && bash tests/post-generators.sh && hugo && git diff --check`

Expected: all checks pass, successful build, no whitespace errors.

- [x] **Step 9: Commit**

```bash
git add tests/seo-metadata.sh themes/webcodr/layouts/partials/head.html themes/webcodr/layouts/partials/seo.html themes/webcodr/layouts/_default/single.html config.yaml
git commit -m "feat: add per-page seo and social metadata"
```

### Task 2: Full-Content RSS Feed

**Files:**
- Modify: `tests/seo-metadata.sh`
- Create: `themes/webcodr/layouts/_default/rss.xml`

- [x] **Step 1: Extend the smoke test with feed assertions**

Append to `tests/seo-metadata.sh` (before the final `printf`):

```bash
feed="$output/index.xml"
assert_file "$feed"
assert_contains "$feed" '<content:encoded>'
assert_contains "$feed" '<link>https://webcodr.io/2026/07/find-things-even-faster-with-srchr/</link>'
assert_contains "$feed" 'xmlns:content="http://purl.org/rss/1.0/modules/content/"'
item_count=$(grep -Fc '<item>' "$feed")
[[ "$item_count" -le 20 && "$item_count" -ge 1 ]] || fail "expected 1-20 feed items, found $item_count"
```

- [x] **Step 2: Run the test and verify RED**

Run: `bash tests/seo-metadata.sh`

Expected: FAIL on `<content:encoded>` (the built-in template is summary-only).

- [x] **Step 3: Create the custom RSS template**

Create `themes/webcodr/layouts/_default/rss.xml`, modeled on Hugo's embedded template but with absolute item URLs (matching the hardcoded canonical-host precedent) and full content:

```xml
{{- $pctx := . -}}
{{- if .IsHome -}}{{ $pctx = .Site }}{{- end -}}
{{- $pages := $pctx.RegularPages -}}
{{- $limit := .Site.Config.Services.RSS.Limit -}}
{{- if ge $limit 1 -}}
{{- $pages = $pages | first $limit -}}
{{- end -}}
<rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom" xmlns:content="http://purl.org/rss/1.0/modules/content/">
  <channel>
    <title>{{ .Site.Title }}</title>
    <link>https://webcodr.io{{ .RelPermalink }}</link>
    <description>Recent content on {{ .Site.Title }}</description>
    <generator>Hugo</generator>
    <language>en-us</language>
    {{ with index $pages 0 }}<lastBuildDate>{{ .Date.Format "Mon, 02 Jan 2006 15:04:05 -0700" }}</lastBuildDate>{{ end }}
    {{ with .OutputFormats.Get "RSS" }}<atom:link href="https://webcodr.io{{ .RelPermalink }}" rel="self" type="application/rss+xml" />{{ end }}
    {{ range $pages }}
    <item>
      <title>{{ .Title }}</title>
      <link>https://webcodr.io{{ .RelPermalink }}</link>
      <pubDate>{{ .Date.Format "Mon, 02 Jan 2006 15:04:05 -0700" }}</pubDate>
      <guid>https://webcodr.io{{ .RelPermalink }}</guid>
      <description>{{ .Summary | plainify | html }}</description>
      <content:encoded>{{ printf "<![CDATA[%s]]>" .Content | safeHTML }}</content:encoded>
    </item>
    {{ end }}
  </channel>
</rss>
```

The existing feed-discovery link in `head.html` and the footer RSS link resolve through `.OutputFormats.Get "RSS"` and need no changes. `services.rss.limit: 20` in `config.yaml` keeps applying through `$limit`.

- [x] **Step 4: Run the test and verify GREEN**

Run: `bash tests/seo-metadata.sh`

Expected: `SEO metadata checks passed.`

- [x] **Step 5: Validate the feed shape**

Run: `hugo --destination /tmp/rss-check --quiet && head -30 /tmp/rss-check/index.xml && rm -rf /tmp/rss-check`

Expected: well-formed XML, absolute `https://webcodr.io/...` links, CDATA-wrapped HTML content.

- [x] **Step 6: Run the full site verification and commit**

Run: `bash tests/blog-discovery.sh && hugo && git diff --check`

```bash
git add tests/seo-metadata.sh themes/webcodr/layouts/_default/rss.xml
git commit -m "feat: publish full-content rss feed"
```

### Task 3: Image Render Hook

**Files:**
- Create: `tests/content-rendering.sh`
- Create: `themes/webcodr/layouts/_default/_markup/render-image.html`
- Modify: `assets/css/webcodr.css`

- [x] **Step 1: Write the failing rendering smoke test**

Create `tests/content-rendering.sh` with the same helper/build scaffold as the other tests:

```bash
router_post="$output/2017/01/edgerouter-x-vs-mikrotik-hex/index.html"

assert_file "$router_post"
assert_contains "$router_post" 'src="/images/router-benchmark/erx.jpg"'
assert_contains "$router_post" 'loading="lazy"'
assert_contains "$router_post" 'decoding="async"'
grep -Eq 'width="[0-9]+" height="[0-9]+"' "$router_post" || fail "expected intrinsic image dimensions in $router_post"
assert_contains "$router_post" 'alt="Ubiquiti EdgeRouter X"'

printf 'Content rendering checks passed.\n'
```

- [x] **Step 2: Run the test and verify RED**

Run: `bash tests/content-rendering.sh`

Expected: FAIL on `loading="lazy"`.

- [x] **Step 3: Create the image render hook**

Create `themes/webcodr/layouts/_default/_markup/render-image.html`. Post images are static files referenced as `/images/...`, so dimensions come from `imageConfig` guarded by `fileExists`; external or missing images fall back to a plain lazy image:

```html
{{- $src := .Destination -}}
{{- $localPath := print "static" $src -}}
{{- if and (strings.HasPrefix $src "/") (fileExists $localPath) -}}
{{- $dims := imageConfig $localPath -}}
<img src="{{ $src | safeURL }}" alt="{{ .Text }}"{{ with .Title }} title="{{ . }}"{{ end }} width="{{ $dims.Width }}" height="{{ $dims.Height }}" loading="lazy" decoding="async" />
{{- else -}}
<img src="{{ $src | safeURL }}" alt="{{ .Text }}"{{ with .Title }} title="{{ . }}"{{ end }} loading="lazy" decoding="async" />
{{- end -}}
```

- [x] **Step 4: Keep explicit dimensions responsive**

In `assets/css/webcodr.css`, verify the `.post-content` image rules include both `max-width: 100%` and `height: auto`; add whichever is missing so the new `width`/`height` attributes reserve layout space without breaking scaling on narrow viewports.

- [x] **Step 5: Run the test and verify GREEN**

Run: `bash tests/content-rendering.sh`

Expected: `Content rendering checks passed.`

- [x] **Step 6: Visually verify one image-heavy post**

Run: `hugo server`

Open `http://localhost:1313/2018/02/edgerouter-vlan-isolation/` and confirm images render at correct proportions on desktop and narrow widths.

- [x] **Step 7: Run the full site verification and commit**

Run: `bash tests/seo-metadata.sh && bash tests/blog-discovery.sh && hugo && git diff --check`

```bash
git add tests/content-rendering.sh themes/webcodr/layouts/_default/_markup/render-image.html assets/css/webcodr.css
git commit -m "feat: lazy-load post images with intrinsic dimensions"
```

### Task 4: Heading Anchor Links

**Files:**
- Modify: `tests/content-rendering.sh`
- Create: `themes/webcodr/layouts/_default/_markup/render-heading.html`
- Modify: `assets/css/webcodr.css`

- [x] **Step 1: Extend the rendering test**

Append to `tests/content-rendering.sh` (before the final `printf`):

```bash
search_post="$output/2026/07/using-fd-rg-fzf-and-bat-to-find-things-fast/index.html"

assert_contains "$search_post" 'id="usage"'
assert_contains "$search_post" 'href="#usage" class="heading-anchor"'
assert_contains "$search_post" 'class="table-of-contents"'
```

The last assertion guards the existing TOC contract: the render hook must keep emitting the same `id` values `.TableOfContents` links to.

- [x] **Step 2: Run the test and verify RED**

Run: `bash tests/content-rendering.sh`

Expected: FAIL on `class="heading-anchor"`.

- [x] **Step 3: Create the heading render hook**

Create `themes/webcodr/layouts/_default/_markup/render-heading.html`:

```html
<h{{ .Level }} id="{{ .Anchor | safeURL }}">{{ .Text | safeHTML }}<a href="#{{ .Anchor | safeURL }}" class="heading-anchor" aria-label="Link to this section">#</a></h{{ .Level }}>
```

- [x] **Step 4: Style the anchors**

Add to `assets/css/webcodr.css` near the other post-content styles, reusing the Tokyo Night custom properties from `:root` (`assets/css/webcodr.css:323`):

```css
.heading-anchor {
	margin-left: 0.5rem;
	color: var(--headline-secondary-color);
	text-decoration: none;
	opacity: 0;
	transition: opacity 0.15s ease-in-out;
}

:is(h2, h3, h4, h5, h6):hover > .heading-anchor,
.heading-anchor:focus-visible {
	opacity: 1;
}

@media (hover: none) {
	.heading-anchor {
		opacity: 1;
	}
}
```

Align the hover/focus treatment with the unified site link styles (see commit `56ad125`).

- [x] **Step 5: Run the test and verify GREEN**

Run: `bash tests/content-rendering.sh`

Expected: `Content rendering checks passed.`

- [x] **Step 6: Run the full site verification and commit**

Run: `bash tests/seo-metadata.sh && bash tests/blog-discovery.sh && hugo && git diff --check`

```bash
git add tests/content-rendering.sh themes/webcodr/layouts/_default/_markup/render-heading.html assets/css/webcodr.css
git commit -m "feat: add heading anchor links"
```

### Task 5: Client-Side Search With Pagefind

**Files:**
- Create: `tests/search.sh`
- Create: `content/search/_index.md`
- Create: `themes/webcodr/layouts/search/list.html`
- Modify: `themes/webcodr/layouts/partials/post.html`
- Modify: `themes/webcodr/layouts/partials/post-meta.html`, `table-of-contents.html`, `related-posts.html`, `post-navigation.html`
- Modify: `themes/webcodr/layouts/partials/header.html`
- Modify: `assets/js/webcodr.js`
- Modify: `assets/css/webcodr.css`
- Modify: `.github/workflows/deploy_production.yml`
- Modify: `Caddyfile`

- [x] **Step 1: Write the failing search smoke test**

Create `tests/search.sh` with the shared scaffold. Pagefind itself runs only in CI, so the test asserts the static contract:

```bash
search_page="$output/search/index.html"
post_page="$output/2026/07/find-things-even-faster-with-srchr/index.html"

assert_file "$search_page"
assert_contains "$search_page" 'id="search-input"'
assert_contains "$search_page" 'id="search-results"'
assert_contains "$search_page" 'id="search-status"'
assert_contains "$output/index.html" 'href="/search/"'
assert_contains "$post_page" 'data-pagefind-body'
assert_not_contains "$output/index.html" 'data-pagefind-body'
assert_contains "$post_page" 'data-pagefind-ignore'
assert_contains "$root/.github/workflows/deploy_production.yml" 'pagefind'
assert_contains "$root/Caddyfile" "'wasm-unsafe-eval'"

printf 'Search checks passed.\n'
```

- [x] **Step 2: Run the test and verify RED**

Run: `bash tests/search.sh`

Expected: FAIL because `/search/` does not exist.

- [x] **Step 3: Create the search page**

Create `content/search/_index.md`:

```markdown
---
title: Search
description: Search all posts on webcodr by keyword.
---
```

Create `themes/webcodr/layouts/search/list.html`, modeled on `themes/webcodr/layouts/archive/list.html`. No `<form>` with inline handlers (the CSP forbids inline JS); behavior attaches in `webcodr.js`:

```html
<!DOCTYPE html>
<html lang="en">
{{ partial "head.html" . }}
<body>
  {{ partial "header.html" . }}
  <div class="container container--main">
    <main class="content">
      <article class="post">
        <h1 class="post-headline">{{ .Title }}</h1>
        <div class="search-form">
          <label class="search-label" for="search-input">Search posts</label>
          <input type="search" id="search-input" class="search-input" placeholder="Type to search…" autocomplete="off" />
        </div>
        <p id="search-status" class="search-status" role="status"></p>
        <ol id="search-results" class="search-results"></ol>
      </article>
    </main>
  </div>
  {{ partial "footer.html" . }}
</body>
</html>
```

- [x] **Step 4: Scope the Pagefind index to single post bodies**

In `themes/webcodr/layouts/partials/post.html:1`, tag the article root only in the single-post location so Pagefind indexes exactly one page per post (once any `data-pagefind-body` exists, untagged pages are excluded automatically):

```html
<article class="post"{{ if and (eq .context.Type "post") (eq .location "single") }} data-pagefind-body{{ end }}>
```

Add `data-pagefind-ignore` to the root element of `post-meta.html`, `table-of-contents.html`, `related-posts.html`, and `post-navigation.html` so navigation chrome inside the article never pollutes excerpts.

- [x] **Step 5: Add the header navigation link**

In `themes/webcodr/layouts/partials/header.html`, add after the Archive link:

```html
<a href="/search/" class="header-navigation-link">Search</a>
```

- [x] **Step 6: Implement search behavior in `webcodr.js`**

Add to `assets/js/webcodr.js`, following the file's existing const-arrow style, and call `setupSearch()` inside the existing `DOMContentLoaded` listener:

```js
const setupSearch = () => {
	const input = document.querySelector("#search-input");
	const resultsList = document.querySelector("#search-results");
	const status = document.querySelector("#search-status");

	if (!input || !resultsList || !status) {
		return;
	}

	let pagefindPromise = null;
	const loadPagefind = () => {
		pagefindPromise ??= import("/pagefind/pagefind.js").then(
			async (pagefind) => {
				await pagefind.init();
				return pagefind;
			},
		);
		return pagefindPromise;
	};

	const renderResults = (results, total) => {
		resultsList.replaceChildren();
		status.textContent =
			total === 0 ? "No results found." : `${total} result${total === 1 ? "" : "s"}`;

		for (const result of results) {
			const item = document.createElement("li");
			item.classList.add("search-result");

			const link = document.createElement("a");
			link.href = result.url;
			link.textContent = result.meta.title;
			link.classList.add("search-result--title");

			const excerpt = document.createElement("p");
			excerpt.classList.add("search-result--excerpt");
			excerpt.innerHTML = result.excerpt;

			item.append(link, excerpt);
			resultsList.append(item);
		}
	};

	let debounceTimer = null;
	input.addEventListener("input", () => {
		clearTimeout(debounceTimer);
		debounceTimer = setTimeout(async () => {
			const query = input.value.trim();

			if (query.length < 2) {
				resultsList.replaceChildren();
				status.textContent = "";
				return;
			}

			let pagefind;

			try {
				pagefind = await loadPagefind();
			} catch (_) {
				status.textContent = "Search is unavailable.";
				return;
			}

			const search = await pagefind.search(query);
			const results = await Promise.all(
				search.results.slice(0, 10).map((result) => result.data()),
			);

			if (input.value.trim() !== query) {
				return;
			}

			renderResults(results, search.results.length);
		}, 150);
	});
};
```

Notes: the dynamic `import("/pagefind/pagefind.js")` is same-origin (CSP-clean) and fails gracefully under `hugo server`, where no index exists. `result.excerpt` HTML comes from our own build-time index, so `innerHTML` is safe here.

- [x] **Step 7: Style the search page**

Add `.search-form`, `.search-label`, `.search-input` (including focus state), `.search-status`, `.search-results`, `.search-result`, `.search-result--title`, `.search-result--excerpt`, and `.search-result--excerpt mark` rules to `assets/css/webcodr.css` using the existing `:root` custom properties (e.g. `--code-background-color` for the input surface, `--headline-tertiary-color` for `mark` highlights) so the page matches the Tokyo Night look.

- [x] **Step 8: Generate the index in CI**

In `.github/workflows/deploy_production.yml`, add after the `Build site` step and extend `Verify build output`:

```yaml
      - name: Build search index
        run: npx -y pagefind@1.3.0 --site public

      - name: Verify build output
        run: |
          test -f public/index.html
          test -f public/pagefind/pagefind.js
```

- [x] **Step 9: Allow Pagefind's WebAssembly in the CSP**

In `Caddyfile`, change the CSP directive `script-src 'self'` to `script-src 'self' 'wasm-unsafe-eval'` (Pagefind compiles a WASM module at runtime; nothing else changes).

- [x] **Step 10: Run the test and verify GREEN**

Run: `bash tests/search.sh`

Expected: `Search checks passed.`

- [x] **Step 11: Verify search end-to-end locally**

```bash
hugo --destination /tmp/search-check --quiet
npx -y pagefind@1.3.0 --site /tmp/search-check
python3 -m http.server 8080 -d /tmp/search-check
```

Open `http://localhost:8080/search/`, search for "srchr" and "edgerouter", and confirm ranked results with highlighted excerpts appear and result links resolve. Then stop the server and `rm -rf /tmp/search-check`.

- [x] **Step 12: Run the full site verification and commit**

Run: `bash tests/seo-metadata.sh && bash tests/content-rendering.sh && bash tests/blog-discovery.sh && hugo && git diff --check`

```bash
git add tests/search.sh content/search/_index.md themes/webcodr/layouts/search/list.html themes/webcodr/layouts/partials/post.html themes/webcodr/layouts/partials/post-meta.html themes/webcodr/layouts/partials/table-of-contents.html themes/webcodr/layouts/partials/related-posts.html themes/webcodr/layouts/partials/post-navigation.html themes/webcodr/layouts/partials/header.html assets/js/webcodr.js assets/css/webcodr.css .github/workflows/deploy_production.yml Caddyfile
git commit -m "feat: add client-side search with pagefind"
```

> **Operational follow-up (manual, after merge to main):** the deploy pipeline only uploads `public/`, so the Caddyfile change must be applied on the production server once: pull the repo checkout there and reload Caddy (e.g. `docker compose exec caddy caddy reload --config /etc/caddy/Caddyfile`). Search will be blocked by the old CSP until this happens. Verify afterwards that `https://webcodr.io/search/` returns results and the browser console shows no CSP violations.

### Task 6: Git-Derived Sitemap Freshness

**Files:**
- Modify: `tests/seo-metadata.sh`
- Modify: `config.yaml`
- Modify: `.github/workflows/deploy_production.yml`

- [ ] **Step 1: Extend the smoke test**

Append to `tests/seo-metadata.sh` (before the final `printf`):

```bash
sitemap_lastmod=$(awk '/edgerouter-x-vs-mikrotik-hex/{found=1} found && /<lastmod>/{print; exit}' "$output/sitemap.xml")
[[ -n "$sitemap_lastmod" ]] || fail "expected a lastmod entry for the 2017 router post in sitemap.xml"
[[ "$sitemap_lastmod" != *"<lastmod>2017-"* ]] || fail "expected git-derived lastmod, found publication date: $sitemap_lastmod"
```

- [ ] **Step 2: Run the test and verify RED**

Run: `bash tests/seo-metadata.sh`

Expected: FAIL because without git info `.Lastmod` falls back to the 2017 publication date.

- [ ] **Step 3: Enable git info with explicit front matter priority**

Add to `config.yaml`:

```yaml
enableGitInfo: true
frontmatter:
  lastmod: ["lastmod", ":git", "date", "publishDate"]
```

The explicit order makes front matter `lastmod` win over git (Hugo's default with `enableGitInfo` puts `:git` first). The visible "Updated" line in `post-meta.html:11` stays gated on `.Params.lastmod` and must NOT be changed to `.Lastmod`: the 2026-07-12 metadata backfill touched every post, so git dates would falsely mark all posts as freshly updated. Git info feeds only the sitemap and the `article:modified_time` meta from Task 1.

- [ ] **Step 4: Give CI full git history**

In `.github/workflows/deploy_production.yml`, extend the checkout step (a shallow clone would stamp every page with the latest commit date):

```yaml
      - name: Check out repository
        uses: actions/checkout@34e114876b0b11c390a56381ad16ebd13914f8d5 # v4.3.1
        with:
          fetch-depth: 0
```

- [ ] **Step 5: Run the test and verify GREEN**

Run: `bash tests/seo-metadata.sh`

Expected: `SEO metadata checks passed.`

- [ ] **Step 6: Confirm no visible regression**

Run: `hugo --destination /tmp/lastmod-check --quiet`

Verify `/tmp/lastmod-check/2017/01/edgerouter-x-vs-mikrotik-hex/index.html` still contains no `Updated <time` line, then `rm -rf /tmp/lastmod-check`.

- [ ] **Step 7: Run the full site verification and commit**

Run: `bash tests/content-rendering.sh && bash tests/search.sh && bash tests/blog-discovery.sh && bash tests/post-generators.sh && hugo && git diff --check`

```bash
git add tests/seo-metadata.sh config.yaml .github/workflows/deploy_production.yml
git commit -m "feat: derive sitemap lastmod from git history"
```

---

## Post-Deploy Verification

After the first production deploy with all tasks merged:

1. `curl -fsS https://webcodr.io/search/ | grep search-input` — search page live.
2. `curl -fsS https://webcodr.io/index.xml | grep -c '<content:encoded>'` — full-content feed live.
3. Paste a post URL into https://cards-dev.twitter.com/validator or Bluesky's link preview and confirm title/description render from the post's own metadata.
4. Exercise search in a browser and confirm no CSP violations in the console (requires the manual Caddy reload from Task 5).

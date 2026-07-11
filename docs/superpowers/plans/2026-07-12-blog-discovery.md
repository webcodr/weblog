# Blog Discovery and Reading Flow Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add static topic and archive discovery plus better single-post navigation while preserving the full-article homepage.

**Architecture:** Hugo generates a `topics` taxonomy, compact topic/archive indexes, and all post navigation at build time. Focused partials own metadata, table-of-contents, related-content, and adjacent-post rendering; a shell smoke test builds into a temporary directory and asserts the generated HTML contract.

**Tech Stack:** Hugo Extended 0.163.x, Go templates, YAML front matter, CSS, POSIX shell

---

## File Map

- Create `tests/blog-discovery.sh`: Build the site in isolation and assert routes and generated markup.
- Modify `config.yaml`: Define the topics taxonomy and related-content weights.
- Modify posts dated 2024 onward under `content/post/`: Add controlled topics and selected optional metadata.
- Create `content/archive/_index.md`: Create the `/archive/` route and select its layout.
- Create `themes/webcodr/layouts/partials/post-index-entry.html`: Render one compact topic/archive entry.
- Create `themes/webcodr/layouts/_default/terms.html`: Render `/topics/`.
- Create `themes/webcodr/layouts/_default/taxonomy.html`: Render one topic page.
- Create `themes/webcodr/layouts/archive/list.html`: Render the year-grouped archive.
- Create `themes/webcodr/layouts/partials/post-meta.html`: Render publication, update, reading-time, and topic metadata.
- Create `themes/webcodr/layouts/partials/table-of-contents.html`: Render an opted-in TOC.
- Create `themes/webcodr/layouts/partials/related-posts.html`: Render up to three topic-related posts.
- Create `themes/webcodr/layouts/partials/post-navigation.html`: Render chronological adjacent-post links.
- Modify `themes/webcodr/layouts/partials/post.html`: Compose the single-post partials without changing homepage article bodies.
- Modify `themes/webcodr/layouts/partials/header.html`: Add Topics and Archive navigation.
- Modify `assets/css/webcodr.css`: Style all new elements in the existing Tokyo Night visual language.

### Task 1: Topic Data And Hugo Configuration

**Files:**
- Create: `tests/blog-discovery.sh`
- Modify: `config.yaml:1-21`
- Modify: `content/post/2026-07-05_find-things-even-faster-with-srchr.md:1-4`
- Modify: `content/post/2026-07-05_using-fd-rg-fzf-and-bat-to-find-things-fast.md:1-4`
- Modify: `content/post/2025-10-31_fix-omarchy-gaming--vulkan-.md:1-4`
- Modify: `content/post/2025-10-29_hyprland-trackpad-tips---tricks.md:1-4`
- Modify: `content/post/2025-08-29_more-awesome-cli-tools.md:1-4`
- Modify: `content/post/2025-08-01_i-m-using-arch-btw.md:1-4`
- Modify: `content/post/2025-05-28_java-switch-dont-do-this.md:1-5`
- Modify: `content/post/2024-10-07_pop-os-bluetooth-handsfree-mode.md:1-5`
- Modify: `content/post/2024-03-06_cli-tools.md:1-5`
- Modify: `content/post/2024-01-19_micro-dsl-kotlin.md:1-5`

- [ ] **Step 1: Create the test directory**

Run: `ls -ld . && mkdir tests`

Expected: the repository root is listed and the new `tests/` directory is created.

- [ ] **Step 2: Write the generated-output test harness and first failing taxonomy assertion**

```bash
#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
output=$(mktemp -d)
trap 'rm -rf "$output"' EXIT

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

assert_file() {
  [[ -f "$1" ]] || fail "expected file $1"
}

assert_contains() {
  grep -Fq -- "$2" "$1" || fail "expected $1 to contain: $2"
}

assert_not_contains() {
  if grep -Fq -- "$2" "$1"; then
    fail "expected $1 not to contain: $2"
  fi
}

hugo --source "$root" --destination "$output" --quiet

assert_file "$output/topics/index.html"
assert_file "$output/topics/developer-tools/index.html"

printf 'Blog discovery checks passed.\n'
```

- [ ] **Step 3: Run the test to verify it fails**

Run: `bash tests/blog-discovery.sh`

Expected: FAIL with `expected file .../topics/index.html` because the taxonomy does not exist.

- [ ] **Step 4: Configure the taxonomy and related-content index**

Append to `config.yaml`:

```yaml
taxonomies:
  topic: topics
related:
  includeNewer: true
  threshold: 80
  toLower: true
  indices:
    - name: topics
      weight: 100
    - name: date
      weight: 10
```

- [ ] **Step 5: Backfill the approved initial topic set and optional metadata**

Add these fields inside the existing front matter blocks:

```yaml
# 2026-07-05_find-things-even-faster-with-srchr.md
topics: [developer-tools, rust]
description: A cross-platform Rust TUI for finding files and searching their contents.

# 2026-07-05_using-fd-rg-fzf-and-bat-to-find-things-fast.md
topics: [developer-tools]
description: Build interactive file and content search helpers with fd, rg, fzf, and bat.
toc: true

# 2025-10-31_fix-omarchy-gaming--vulkan-.md
topics: [linux, omarchy]

# 2025-10-29_hyprland-trackpad-tips---tricks.md
topics: [linux, omarchy]

# 2025-08-29_more-awesome-cli-tools.md
topics: [developer-tools]
toc: true

# 2025-08-01_i-m-using-arch-btw.md
topics: [linux, omarchy]
toc: true
lastmod: 2025-08-28T00:00:00+00:00

# 2025-05-28_java-switch-dont-do-this.md
topics: [programming, kotlin]

# 2024-10-07_pop-os-bluetooth-handsfree-mode.md
topics: [linux]

# 2024-03-06_cli-tools.md
topics: [developer-tools, rust]
toc: true

# 2024-01-19_micro-dsl-kotlin.md
topics: [programming, kotlin]
```

Every topic now has at least two posts. Do not alter titles, dates, or article bodies.

- [ ] **Step 6: Run the taxonomy test**

Run: `bash tests/blog-discovery.sh`

Expected: `Blog discovery checks passed.` Hugo creates taxonomy routes even though the current generic list layout renders empty files.

- [ ] **Step 7: Commit the content model**

```bash
git add config.yaml tests/blog-discovery.sh content/post/2026-07-05_find-things-even-faster-with-srchr.md content/post/2026-07-05_using-fd-rg-fzf-and-bat-to-find-things-fast.md content/post/2025-10-31_fix-omarchy-gaming--vulkan-.md content/post/2025-10-29_hyprland-trackpad-tips---tricks.md content/post/2025-08-29_more-awesome-cli-tools.md content/post/2025-08-01_i-m-using-arch-btw.md content/post/2025-05-28_java-switch-dont-do-this.md content/post/2024-10-07_pop-os-bluetooth-handsfree-mode.md content/post/2024-03-06_cli-tools.md content/post/2024-01-19_micro-dsl-kotlin.md
git commit -m "feat: add post topic metadata"
```

### Task 2: Topic And Archive Indexes

**Files:**
- Modify: `tests/blog-discovery.sh`
- Create: `content/archive/_index.md`
- Create: `themes/webcodr/layouts/partials/post-index-entry.html`
- Create: `themes/webcodr/layouts/_default/terms.html`
- Create: `themes/webcodr/layouts/_default/taxonomy.html`
- Create: `themes/webcodr/layouts/archive/list.html`

- [ ] **Step 1: Add failing index assertions after the existing file assertions**

```bash
assert_contains "$output/topics/index.html" '<h1 class="post-headline">Topics</h1>'
assert_contains "$output/topics/index.html" '>Developer Tools<'
assert_contains "$output/topics/developer-tools/index.html" 'Find things even faster with srchr'
assert_contains "$output/topics/developer-tools/index.html" 'A cross-platform Rust TUI'
assert_file "$output/archive/index.html"
assert_contains "$output/archive/index.html" '<h2 class="archive-year">2026</h2>'
assert_contains "$output/archive/index.html" 'Find things even faster with srchr'
assert_contains "$output/archive/index.html" '<h2 class="archive-year">2015</h2>'
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `bash tests/blog-discovery.sh`

Expected: FAIL because the topic files are empty and `/archive/` does not exist.

- [ ] **Step 3: Create the compact entry partial**

Create `themes/webcodr/layouts/partials/post-index-entry.html`:

```html
<li class="post-index-item">
  <time datetime="{{ .Date.Format "2006-01-02T15:04:05Z07:00" }}" class="post-index-date">{{ .Date.Format "Jan 02" }}</time>
  <div class="post-index-content">
    <a href="{{ .RelPermalink }}" class="post-index-link">{{ .Title }}</a>
    <span class="post-index-reading-time">{{ .ReadingTime }} min read</span>
    {{ with .Description }}<p class="post-index-description">{{ . }}</p>{{ end }}
  </div>
</li>
```

- [ ] **Step 4: Create the topic index template**

Create `themes/webcodr/layouts/_default/terms.html`:

```html
<!DOCTYPE html>
<html lang="en">
{{ partial "head.html" . }}
<body>
  {{ partial "header.html" . }}
  <div class="container container--main">
    <main class="content">
      <article class="post">
        <h1 class="post-headline">Topics</h1>
        <ul class="topic-list">
          {{ range .Data.Terms.ByCount }}
            <li class="topic-list-item">
              <a href="{{ .Page.RelPermalink }}" class="topic-list-link">{{ .Page.LinkTitle }}</a>
              <span class="topic-list-count">{{ .Count }}</span>
            </li>
          {{ end }}
        </ul>
      </article>
    </main>
  </div>
  {{ partial "footer.html" . }}
</body>
</html>
```

- [ ] **Step 5: Create the individual topic template**

Create `themes/webcodr/layouts/_default/taxonomy.html`:

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
        <ul class="post-index">
          {{ range .Pages.ByDate.Reverse }}
            {{ partial "post-index-entry.html" . }}
          {{ end }}
        </ul>
      </article>
    </main>
  </div>
  {{ partial "footer.html" . }}
</body>
</html>
```

- [ ] **Step 6: Create the archive content node and layout**

Create `content/archive/_index.md`:

```yaml
---
title: Archive
---
```

Create `themes/webcodr/layouts/archive/list.html`:

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
        {{ range (where .Site.RegularPages "Type" "post").GroupByDate "2006" }}
          <section class="archive-group">
            <h2 class="archive-year">{{ .Key }}</h2>
            <ul class="post-index">
              {{ range .Pages }}
                {{ partial "post-index-entry.html" . }}
              {{ end }}
            </ul>
          </section>
        {{ end }}
      </article>
    </main>
  </div>
  {{ partial "footer.html" . }}
</body>
</html>
```

- [ ] **Step 7: Run the index tests**

Run: `bash tests/blog-discovery.sh`

Expected: `Blog discovery checks passed.`

- [ ] **Step 8: Commit the indexes**

```bash
git add tests/blog-discovery.sh content/archive/_index.md themes/webcodr/layouts/partials/post-index-entry.html themes/webcodr/layouts/_default/terms.html themes/webcodr/layouts/_default/taxonomy.html themes/webcodr/layouts/archive/list.html
git commit -m "feat: add topic and archive indexes"
```

### Task 3: Post Metadata And Optional Table Of Contents

**Files:**
- Modify: `tests/blog-discovery.sh`
- Create: `themes/webcodr/layouts/partials/post-meta.html`
- Create: `themes/webcodr/layouts/partials/table-of-contents.html`
- Modify: `themes/webcodr/layouts/partials/post.html:1-14`

- [ ] **Step 1: Add failing metadata and TOC assertions**

```bash
srchr="$output/2026/07/find-things-even-faster-with-srchr/index.html"
search_post="$output/2026/07/using-fd-rg-fzf-and-bat-to-find-things-fast/index.html"
arch_post="$output/2025/08/i-m-using-arch-btw/index.html"

assert_contains "$srchr" 'Published <time datetime="2026-07-05T20:28:50+00:00"'
assert_contains "$srchr" '>Developer Tools</a>'
assert_not_contains "$srchr" 'Updated <time'
assert_not_contains "$srchr" 'class="table-of-contents"'
assert_contains "$search_post" 'class="table-of-contents"'
assert_contains "$search_post" 'href="#usage"'
assert_contains "$arch_post" 'Updated <time datetime="2025-08-28T00:00:00+00:00"'
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `bash tests/blog-discovery.sh`

Expected: FAIL because single posts still show only reading time and the incorrect last-updated label.

- [ ] **Step 3: Create the single-post metadata partial**

Create `themes/webcodr/layouts/partials/post-meta.html`:

```html
<p class="post-meta">
  Published <time datetime="{{ .Date.Format "2006-01-02T15:04:05Z07:00" }}" class="post-date">{{ .Date.Format "January 2, 2006" }}</time>
  <span aria-hidden="true"> · </span>{{ .ReadingTime }} min read
  {{ with .GetTerms "topics" }}
    <span aria-hidden="true"> · </span>
    <span class="post-topics">
      {{ range $index, $topic := . }}{{ if $index }}, {{ end }}<a href="{{ $topic.RelPermalink }}" class="post-topic-link">{{ $topic.LinkTitle }}</a>{{ end }}
    </span>
  {{ end }}
</p>
{{ with .Params.lastmod }}
  {{ if ne ($.Date.Format "2006-01-02") ($.Lastmod.Format "2006-01-02") }}
    <p class="post-updated">Updated <time datetime="{{ $.Lastmod.Format "2006-01-02T15:04:05Z07:00" }}">{{ $.Lastmod.Format "January 2, 2006" }}</time></p>
  {{ end }}
{{ end }}
```

- [ ] **Step 4: Create the opted-in TOC partial**

Create `themes/webcodr/layouts/partials/table-of-contents.html`:

```html
{{ if .Params.toc }}
  <aside class="table-of-contents" aria-labelledby="table-of-contents-title">
    <h2 id="table-of-contents-title" class="table-of-contents-title">Contents</h2>
    {{ .TableOfContents }}
  </aside>
{{ end }}
```

- [ ] **Step 5: Compose metadata and TOC in the post partial**

Replace `themes/webcodr/layouts/partials/post.html` with:

```html
<article class="post">
  <h1 class="post-headline"><a href="{{ .context.Permalink }}" class="post-link--headline">{{ .context.Title }}</a></h1>
  {{ if and (eq .context.Type "post") (eq .location "single") }}
    {{ partial "post-meta.html" .context }}
    {{ partial "table-of-contents.html" .context }}
  {{ else }}
    <p class="post-meta"><strong>Reading Time:</strong> {{ .context.ReadingTime }} minutes</p>
  {{ end }}
  <div class="post-content">
    {{ .context.Content }}
  </div>
</article>
```

- [ ] **Step 6: Run the metadata and TOC tests**

Run: `bash tests/blog-discovery.sh`

Expected: `Blog discovery checks passed.`

- [ ] **Step 7: Commit post metadata**

```bash
git add tests/blog-discovery.sh themes/webcodr/layouts/partials/post-meta.html themes/webcodr/layouts/partials/table-of-contents.html themes/webcodr/layouts/partials/post.html
git commit -m "feat: add post metadata and contents navigation"
```

### Task 4: Related And Chronological Post Navigation

**Files:**
- Modify: `tests/blog-discovery.sh`
- Create: `themes/webcodr/layouts/partials/related-posts.html`
- Create: `themes/webcodr/layouts/partials/post-navigation.html`
- Modify: `themes/webcodr/layouts/partials/post.html`

- [ ] **Step 1: Add failing navigation assertions**

```bash
legacy_post="$output/2018/04/vue-loader-setup-in-webpack/index.html"

assert_contains "$srchr" 'class="related-posts"'
assert_contains "$srchr" 'Using fd, rg, fzf and bat to find things fast'
assert_contains "$srchr" 'class="post-navigation"'
assert_not_contains "$legacy_post" 'class="related-posts"'
assert_contains "$legacy_post" 'class="post-navigation"'
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `bash tests/blog-discovery.sh`

Expected: FAIL because neither navigation partial exists yet.

- [ ] **Step 3: Create the related-post partial**

Create `themes/webcodr/layouts/partials/related-posts.html`:

```html
{{ with .GetTerms "topics" }}
  {{ $related := $.Site.RegularPages.Related $ | first 3 }}
  {{ with $related }}
    <aside class="related-posts" aria-labelledby="related-posts-title">
      <h2 id="related-posts-title" class="related-posts-title">Continue reading</h2>
      <ul class="related-posts-list">
        {{ range . }}
          <li><a href="{{ .RelPermalink }}">{{ .Title }}</a></li>
        {{ end }}
      </ul>
    </aside>
  {{ end }}
{{ end }}
```

- [ ] **Step 4: Create chronological navigation**

Create `themes/webcodr/layouts/partials/post-navigation.html`:

```html
{{ if or .PrevInSection .NextInSection }}
  <nav class="post-navigation" aria-label="Article navigation">
    <div class="post-navigation-previous">
      {{ with .PrevInSection }}<a href="{{ .RelPermalink }}">&larr; {{ .Title }}</a>{{ end }}
    </div>
    <div class="post-navigation-next">
      {{ with .NextInSection }}<a href="{{ .RelPermalink }}">{{ .Title }} &rarr;</a>{{ end }}
    </div>
  </nav>
{{ end }}
```

- [ ] **Step 5: Add both partials after the article body**

In `themes/webcodr/layouts/partials/post.html`, add before `</article>`:

```html
  {{ if and (eq .context.Type "post") (eq .location "single") }}
    {{ partial "related-posts.html" .context }}
    {{ partial "post-navigation.html" .context }}
  {{ end }}
```

- [ ] **Step 6: Run the navigation tests**

Run: `bash tests/blog-discovery.sh`

Expected: `Blog discovery checks passed.` Also inspect the generated `srchr` page and confirm its own title does not occur inside the `related-posts` element; Hugo's `Related` collection excludes the context page.

- [ ] **Step 7: Commit post navigation**

```bash
git add tests/blog-discovery.sh themes/webcodr/layouts/partials/related-posts.html themes/webcodr/layouts/partials/post-navigation.html themes/webcodr/layouts/partials/post.html
git commit -m "feat: add related and adjacent post links"
```

### Task 5: Global Navigation, Styling, And Final Verification

**Files:**
- Modify: `tests/blog-discovery.sh`
- Modify: `themes/webcodr/layouts/partials/header.html:1-5`
- Modify: `assets/css/webcodr.css:323-799`

- [ ] **Step 1: Add failing global-navigation and regression assertions**

```bash
home="$output/index.html"

assert_contains "$home" 'class="header-navigation"'
assert_contains "$home" 'href="/topics/"'
assert_contains "$home" 'href="/archive/"'
assert_contains "$home" 'Inspired by my last post about'
assert_contains "$home" 'rel="alternate" type="application/rss+xml"'
assert_contains "$output/topics/index.html" 'class="topic-list"'
assert_contains "$output/archive/index.html" 'class="post-index"'
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `bash tests/blog-discovery.sh`

Expected: FAIL because the header has no navigation.

- [ ] **Step 3: Add semantic global navigation**

Replace `themes/webcodr/layouts/partials/header.html` with:

```html
<div class="container">
  <header class="header">
    <p class="header-title"><a href="/" class="header-link"><span class="header-prompt--path" aria-hidden="true">~</span> <span class="header-prompt--chevron" aria-hidden="true">❯</span> webcodr</a></p>
    <nav class="header-navigation" aria-label="Primary navigation">
      <a href="/topics/" class="header-navigation-link">Topics</a>
      <a href="/archive/" class="header-navigation-link">Archive</a>
    </nav>
  </header>
</div>
```

- [ ] **Step 4: Add styles for global navigation and compact indexes**

Insert after the existing header prompt rules in `assets/css/webcodr.css`:

```css
.header {
	display: flex;
	align-items: center;
	justify-content: space-between;
	background: var(--header-title-background-color);
}

.header-navigation {
	display: flex;
	gap: 1rem;
	padding: 0 10px;
	font-family: var(--monospace-font);
}

.header-navigation-link,
.post-topic-link,
.post-index-link,
.topic-list-link,
.related-posts a,
.post-navigation a,
.table-of-contents a {
	color: var(--post-text-color);
}

.header-navigation-link:hover,
.header-navigation-link:focus-visible,
.post-topic-link:hover,
.post-topic-link:focus-visible,
.post-index-link:hover,
.post-index-link:focus-visible,
.topic-list-link:hover,
.topic-list-link:focus-visible,
.related-posts a:hover,
.related-posts a:focus-visible,
.post-navigation a:hover,
.post-navigation a:focus-visible,
.table-of-contents a:hover,
.table-of-contents a:focus-visible {
	color: var(--headline-secondary-color);
}

@media screen and (max-width: 480px) {
	.header {
		align-items: flex-start;
		flex-direction: column;
	}

	.header-navigation {
		padding: 0 10px 10px;
	}
}
```

Insert before the existing `.pagination` rules:

```css
.post-updated {
	margin: -2.5em 0 3em;
	padding: 0 10px;
	color: var(--post-meta-text-color);
}

.topic-list,
.post-index,
.related-posts-list,
.table-of-contents ul {
	list-style: none;
	padding: 0 10px;
}

.topic-list-item,
.post-index-item {
	display: flex;
	gap: 1rem;
	margin-bottom: 1rem;
}

.topic-list-item {
	justify-content: space-between;
}

.topic-list-count,
.post-index-date,
.post-index-reading-time {
	color: var(--post-meta-text-color);
}

.post-index-date {
	flex: 0 0 3.5rem;
}

.post-index-content {
	min-width: 0;
}

.post-index-reading-time {
	display: block;
	font-size: 0.9rem;
}

.post-index-description {
	margin: 0.4rem 0 0;
}

.archive-year,
.table-of-contents-title,
.related-posts-title {
	font-size: 24px;
}

.table-of-contents,
.related-posts,
.post-navigation {
	margin: 2rem 10px;
}

.post-navigation {
	display: grid;
	grid-template-columns: minmax(0, 1fr) minmax(0, 1fr);
	gap: 1rem;
	padding-top: 1rem;
	border-top: 1px solid var(--code-scrollback-background-color);
}

.post-navigation-next {
	text-align: right;
}

@media screen and (min-width: 840px) {
	.post-updated,
	.topic-list,
	.post-index,
	.related-posts-list,
	.table-of-contents ul,
	.table-of-contents,
	.related-posts,
	.post-navigation {
		padding-left: 0;
		padding-right: 0;
		margin-left: 0;
		margin-right: 0;
	}
}
```

- [ ] **Step 5: Run all generated-output tests and a production build**

Run: `bash tests/blog-discovery.sh && hugo`

Expected: `Blog discovery checks passed.`, then a successful Hugo build with no warnings. Confirm the build reports topic, archive, and post pages in the page count.

- [ ] **Step 6: Perform responsive and accessibility review**

Run: `hugo server`

Review `/`, `/topics/`, `/topics/developer-tools/`, `/archive/`, `/2026/07/using-fd-rg-fzf-and-bat-to-find-things-fast/`, and `/2018/04/vue-loader-setup-in-webpack/` at approximately 390 px and 1280 px widths. Confirm:

- The homepage still contains complete article bodies and its pagination works.
- Header links wrap without overlap.
- Topic and archive entries remain readable at narrow widths.
- The opted-in TOC links to headings and is keyboard accessible.
- The legacy post has adjacent navigation but no empty topic or related section.
- Related links exclude the current post.
- Previous and next links are chronologically adjacent and boundary posts show only one link.
- Focus indicators are visible and heading order remains logical.

Stop the server after review.

- [ ] **Step 7: Commit the completed UI**

```bash
git add tests/blog-discovery.sh themes/webcodr/layouts/partials/header.html assets/css/webcodr.css
git commit -m "feat: style blog discovery navigation"
```

- [ ] **Step 8: Verify the final diff**

Run: `git status --short && git log --oneline -6`

Expected: only pre-existing unrelated untracked files remain; the five feature commits appear above the design commit.

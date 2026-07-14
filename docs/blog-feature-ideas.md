# Blog Feature Ideas

The blog already has a strong foundation: Pagefind search, topics, an archive,
series, related posts, tables of contents, RSS and JSON feeds, code-copy buttons,
and generated social images.

## Recommended Next Features

### 1. Content Freshness Indicators

- Mark posts as **Current**, **Needs review**, or **Archived**.
- Show relevant tested versions, such as “Hugo 0.164” or “Kotlin 2.x.”
- Make older technical tutorials easier for readers to evaluate.

### 2. Language Labels and Filtering

- Add language metadata to post front matter.
- Display visible English and German badges.
- Allow readers to filter the archive and search results by language.

### 3. Command Palette

- Open a keyboard-driven command palette with `Ctrl+K`.
- Search posts, topics, and navigation destinations from one overlay.
- Match the blog’s terminal-inspired visual design.

### 4. Sticky, Active Table of Contents

- Keep the table of contents visible while reading long posts.
- Highlight the section currently being viewed.
- Add an optional, subtle reading-progress indicator.

### 5. Theme Selector

- Keep Tokyo Night as the default theme.
- Add light and system theme options.
- Store the reader’s preference locally without cookies.

### 6. Report Outdated Content

- Add a “Report outdated content” link to each post.
- Open a prefilled GitHub issue containing the post title and URL.
- Optionally include an “Edit this page on GitHub” link.

### 7. Curated Learning Paths

Create intentionally ordered collections that go beyond ordinary topic pages,
such as:

- Modern CLI
- Linux Desktop
- Kotlin
- Home Networking

### 8. Runnable Code Links

- Link examples to Kotlin Playground, Rust Playground, or similar services.
- Offer downloadable source files where appropriate.
- Avoid the complexity and performance cost of embedding a complete playground.

### 9. Topic and Series Feeds

- Expose RSS feeds for individual topics and series.
- Let readers subscribe only to subjects they care about.
- Generate the feeds through Hugo without adding a backend.

### 10. Lightweight Discussion

Possible approaches include:

- Webmentions
- GitHub Discussions or Giscus
- Links to related Bluesky conversations

These options provide interaction without requiring a custom comment
database.

## Suggested Priorities

Start with:

1. Content freshness indicators
2. Language labels and filtering
3. Command palette

These features fit the existing content and design while preserving the blog’s
fast, static architecture.

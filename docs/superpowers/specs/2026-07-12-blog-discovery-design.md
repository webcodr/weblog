# Blog Discovery and Reading Flow Design

## Goal

Make older posts easier to discover and improve movement between articles without changing the blog's deliberately lean, full-article homepage. The feature must remain fully static, work without client-side JavaScript, and allow metadata to be added to the archive gradually.

## Scope

The first release adds:

- A controlled post-topic taxonomy.
- A topic index and individual topic pages.
- A chronological archive grouped by year.
- Topic-based related posts on single-post pages.
- Chronological previous and next post links.
- An optional table of contents for long posts.
- Clear publication and modification dates.
- Header links to the topic index and archive.

Client-side search, comments, newsletters, and a summary-based homepage are outside this release. Search can be reconsidered after topic and archive navigation have been used in production.

## User Experience

The homepage continues to render five complete articles per page. Its existing pagination, RSS behavior, and code-block tools remain unchanged. The header adds compact `Topics` and `Archive` links while preserving the terminal-prompt visual language.

The topic index at `/topics/` lists the controlled topics and the number of posts assigned to each. Each topic page displays compact entries containing the publication date, title, reading time, and description when one exists.

The archive at `/archive/` includes every regular post, including posts without topics. Entries are grouped by publication year and ordered newest first within each year. Each entry displays its publication date and title.

A single post displays:

1. Its publication date and reading time near the title.
2. Links for any assigned topics.
3. An optional table of contents before the body when `toc: true` is set.
4. Up to three related posts after the body when topic matches exist.
5. Chronological previous and next post links.

Related and adjacent links must exclude the current page. Optional sections are omitted entirely when they have no content.

## Content Model

Maintained posts may add the following front matter:

```yaml
topics:
  - developer-tools
  - rust
description: A short description used in post indexes.
toc: true
lastmod: 2026-07-12T12:00:00Z
```

`topics` contains one to three values from a small controlled vocabulary. The initial implementation backfills posts published from 2024 onward using established subject clusters such as `developer-tools`, `linux`, `networking`, `javascript`, `kotlin`, and `rust`. A new topic is introduced only when at least two posts can use it.

`description`, `toc`, and `lastmod` are optional. Posts without topics remain valid and appear in the archive and chronological navigation. They do not show an empty topic or related-post section. Posts published before 2024 can therefore be backfilled incrementally after the first release.

`date` is always the publication date. `lastmod` is displayed as an updated date only when explicitly present and different from `date`. The current label that calls `date` "Last updated" is replaced by these distinct semantics.

## Hugo Architecture

`config.yaml` defines the singular `topic` and plural `topics` taxonomy and configures Hugo's related-content index. Shared `topics` values are the primary related-content signal; publication date is a lower-weight secondary signal. This taxonomy naming produces the required `/topics/` routes directly.

Dedicated layouts render the topic term list, individual topic pages, and archive. `content/archive/_index.md` creates the archive route and selects a custom archive layout that groups regular posts by year.

Small partials encapsulate post metadata, the optional table of contents, related posts, and chronological navigation. The existing post partial includes them only for the appropriate list or single-page context. This keeps the homepage's current rendering behavior intact.

All links and indexes are generated at build time. No new JavaScript, remote service, persistent storage, or runtime API is introduced.

## Fallbacks

- Missing topics omit topic links and related posts.
- Missing descriptions omit descriptions rather than deriving unstable text from article bodies.
- Missing or false `toc` values omit the table of contents.
- Missing `lastmod` values show only the publication date.
- A post at either chronological boundary shows only the available adjacent link.
- Empty optional sections produce no heading or wrapper markup.

These cases are normal content states and must not emit Hugo warnings or fail the build.

## Visual Treatment

New navigation uses the existing Tokyo Night palette, typography, spacing, and single-column content width. Topic and archive pages favor compact text lists over cards or grids. Related posts and previous/next links are visually subordinate to the article body and must wrap cleanly on narrow screens.

## Verification

Run `hugo` and confirm a clean build. Inspect generated output for:

- `/topics/`, at least one topic page, and `/archive/`.
- A post with topics and related links that exclude itself.
- A post without topics and with no empty topic or related section.
- A long post with `toc: true` and a short post without a table of contents.
- Correct publication-only and publication-plus-updated date states.
- First, middle, and last posts in chronological navigation.
- Unchanged full-article homepage pagination and RSS output.

Review the homepage, topic index, archive, and a representative single post at desktop and mobile widths. Keyboard focus, heading order, link labels, and wrapping must remain usable.

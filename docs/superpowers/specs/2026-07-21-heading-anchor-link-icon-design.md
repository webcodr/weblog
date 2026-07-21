# Heading-anchor link icon with copy toast

**Date:** 2026-07-21
**Status:** Approved design, ready for implementation plan

## Goal

Replace the `#` hover affordance on article sub headlines with a link-icon
button on desktop, remove it entirely (no replacement) on mobile, and copy the
section URL to the clipboard with a bottom-right toast when the icon is clicked.

## Current behavior

- `themes/webcodr/layouts/_default/_markup/render-heading.html` renders each
  heading as
  `<h{n} id="…"><a href="#…" class="heading-anchor">Text<span class="heading-anchor-hash" aria-hidden="true">#</span></a></h{n}>`.
  The whole heading is a jump-to-section link; the `#` is a child glyph.
- CSS (`assets/css/webcodr.css`):
  - `.heading-anchor-hash` fades in (opacity 0 → 1) on
    `.heading-anchor:hover` / `:focus-visible`.
  - `@media (hover: none)` forces the hash always-visible on touch devices.
  - `@media screen and (min-width: 880px)` makes the headings `position:
    relative` and pins the hash absolutely to the left of the heading
    (`right: 100%`).
- The code copy button (`.post-content--copy`) is a **JS-created** `<button>`
  (see `createCopyButton` / `setupCodeBlocks` in `assets/js/webcodr.js`). It
  renders its icon with `-webkit-mask`/`mask` + `background-color:
  currentColor`, has a hover background, and swaps success/error icons via the
  `--copy-button-icon` custom property.
- `tests/content-rendering.sh:37` asserts
  `href="#usage" class="heading-anchor"` in built output.

## Approved decisions

1. **Icon style:** full button chrome (background box + hover state, like the
   code copy button), positioned to the **left** of the heading on desktop,
   fading in on hover.
2. **Copy trigger:** only the link icon copies + toasts. The heading text stays
   a normal jump-to-section anchor link.

## Design

### 1. Markup / rendering

- Edit `render-heading.html` to **remove** the
  `<span class="heading-anchor-hash" aria-hidden="true">#</span>`. The heading
  becomes `<h{n} id="…"><a href="#…" class="heading-anchor">Text</a></h{n}>`.
  This preserves the jump link and keeps `tests/content-rendering.sh:37`
  passing.
- The copy button is **not** server-rendered. It is created in JS, mirroring the
  code copy button, so there is no dead/no-op button when JS is disabled. A
  `<button>` cannot nest inside the `<a>`, so it is appended as a **sibling** of
  the anchor, inside the heading element.

### 2. New asset

- Add `static/icons/link.svg` — a chain/link glyph, `viewBox="0 0 16 16"`,
  single path, no explicit fill (so `currentColor` / mask tinting works like
  `copy.svg`, `check.svg`, `exclamation.svg`).

### 3. JavaScript (`assets/js/webcodr.js`)

- Add a `setupHeadingAnchors()` step, called from the `DOMContentLoaded`
  handler alongside `setupCodeBlocks()` / `setupSearch()`.
- For each `.post-content .heading-anchor`:
  - Resolve the absolute section URL once:
    `new URL(anchor.getAttribute("href"), window.location.href).href`.
  - Create a `<button type="button" class="heading-anchor-copy">` with an
    accessible label (`aria-label` + `title`, e.g. "Copy link to this section").
    The icon is drawn via CSS (mask), same as the copy button, so the button has
    no text content.
  - Append the button as the last child of the heading element
    (`anchor.parentElement`).
  - On click: `await copyToClipboard(url)`; on success show a success toast, on
    failure show an error toast. (Reuse the existing `copyToClipboard` helper.)
- Toast helper (single reusable element):
  - Lazily create one `<div class="toast" role="status" aria-live="polite"
    aria-atomic="true">` appended to `document.body`; reuse it for every toast.
  - `showToast(message, variant)` sets the text, applies a `toast--visible`
    (and optional `toast--error`) class, and clears/sets a timeout to hide it
    after ~2000ms. Re-triggering resets the timer.
  - Success message: "Link copied". Error message: "Couldn't copy link".

### 4. CSS (`assets/css/webcodr.css`)

- Remove the old hash rules: `.heading-anchor-hash` base rule, the
  `.heading-anchor:hover/.:focus-visible .heading-anchor-hash` reveal, the
  `@media (hover: none) { .heading-anchor-hash { opacity: 1 } }` block, and the
  `.heading-anchor-hash` bits inside `@media (min-width: 880px)`. Keep
  `.post-content .heading-anchor` link styling.
- `.heading-anchor-copy`: reuse the copy-button visual language —
  `display: inline-flex`, centered, small square (~`1.6rem`), `border: none`,
  `border-radius: 4px`, `background-color: var(--code-background-color)`,
  `color: var(--post-meta-text-color)`, `cursor: pointer`, `opacity: 0`,
  `transition: opacity 0.15s ease-in-out`, and a `--heading-anchor-icon:
  url("/icons/link.svg")` custom property. Its `::before` paints the icon via
  `-webkit-mask`/`mask: var(--heading-anchor-icon) center / contain no-repeat`
  with `background-color: currentColor`, matching `.post-content--copy::before`.
  Default the button `margin-left` so it reads as attached to the heading on
  narrow (hover-capable) layouts.
- Hover/focus state: `background-color:
  var(--copy-button-hover-background-color)`, `color:
  var(--code-text-color)`.
- Reveal: `:is(h2,h3,h4,h5,h6):hover .heading-anchor-copy` and
  `.heading-anchor-copy:focus-visible` → `opacity: 1` (keyboard reachable).
- Positioning: on `@media screen and (min-width: 880px)` keep headings
  `position: relative` and pin `.heading-anchor-copy` absolutely to the left of
  the heading (`right: 100%; margin: 0 0.5rem 0 0`), matching where the `#` sat.
- Gate the button behind `@media (hover: hover)`. Under `@media (hover: none)`
  the button is `display: none` (mobile: no hash, no replacement).
- `.toast`: `position: fixed`, pinned to the bottom-right using
  `var(--mobile-gutter)` for inset, `z-index` above content, `padding`,
  `border-radius: 5px`, `background-color: var(--code-background-color)`, a
  subtle border (`var(--code-scrollback-background-color)`) and/or box-shadow,
  `color: var(--post-text-color)`. Hidden by default (`opacity: 0`,
  `translateY`, `pointer-events: none`); `.toast--visible` fades/slides it in.
  `.toast--error` tints text/border with `var(--syntax-error-color)`.
  Transitions wrapped so a `prefers-reduced-motion: reduce` query disables the
  movement (opacity-only or instant).

### Out of scope

- The code copy button (`.post-content--copy`) and its behavior are unchanged.
- No change to heading levels, IDs, or the jump-link semantics of heading text.

## Verification

- `hugo` builds cleanly.
- `for t in tests/*.sh; do bash "$t"; done` passes (notably
  `tests/content-rendering.sh`, which still finds
  `href="#usage" class="heading-anchor"`).
- Manual/`hugo server` check: on a hover-capable viewport the link button fades
  in to the left of a sub headline on hover, clicking it copies the absolute
  section URL and shows a bottom-right toast; on a touch/`hover: none` viewport
  no icon appears.
- Optional: add a smoke assertion for `static/icons/link.svg` existence and/or
  that `webcodr.js` wires up heading anchors, consistent with existing test
  style.

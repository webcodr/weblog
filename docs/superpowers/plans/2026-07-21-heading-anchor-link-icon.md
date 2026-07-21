# Heading-anchor Link Icon Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the `#` hover glyph on article sub headlines with a link-icon button (desktop only) that copies the section URL and shows a bottom-right toast; remove the glyph entirely on touch devices.

**Architecture:** The Hugo render-heading hook keeps emitting the heading anchor link but drops the `#` span. A JS step (mirroring the existing code-copy-button pattern) creates a per-heading copy button and a single reusable toast element. CSS reuses the copy button's icon-via-`mask` technique and reveals the button on hover with `@media (hover: hover)`, hiding it under `@media (hover: none)`.

**Tech Stack:** Hugo (Extended) static site, vanilla ES modules in `assets/js/webcodr.js`, hand-written CSS in `assets/css/webcodr.css`, Bash smoke tests under `tests/`.

## Global Constraints

- No package manager / npm workflow; there is no JS or CSS unit-test runner. Verify with `hugo` builds and the Bash smoke suite. (Interactive JS behavior is verified manually.)
- Hugo Extended `0.164.0` is the CI pin; any recent Hugo Extended works locally.
- Fingerprinted asset sources live in root `assets/css/webcodr.css` and `assets/js/webcodr.js`. The theme is `themes/webcodr`.
- Never edit or commit `public/` (generated, gitignored).
- Run the full test suite with: `for t in tests/*.sh; do bash "$t"; done`.
- String-level changes to CSS/templates can require test updates; keep `tests/content-rendering.sh` green.
- Success toast copy is exactly `Link copied`; error toast copy is exactly `Couldn't copy link`.

---

### Task 1: Template drops the hash + link icon asset

**Files:**
- Create: `static/icons/link.svg`
- Modify: `themes/webcodr/layouts/_default/_markup/render-heading.html:1`
- Test: `tests/content-rendering.sh`

**Interfaces:**
- Consumes: nothing.
- Produces: `/icons/link.svg` served at the site root (used by CSS in Task 2 via `url("/icons/link.svg")`); heading markup `<h{n} id="…"><a href="#…" class="heading-anchor">Text</a></h{n}>` with no `heading-anchor-hash` span.

- [ ] **Step 1: Add the failing test assertions**

In `tests/content-rendering.sh`, add an `assert_not_contains` helper after the existing `assert_contains` function (after line 19):

```bash
assert_not_contains() {
	grep -Fq -- "$2" "$1" && fail "expected $1 to NOT contain: $2" || true
}
```

Then, immediately after the existing line `assert_contains "$search_post" 'href="#usage" class="heading-anchor"'` (line 37), add:

```bash
assert_not_contains "$search_post" 'heading-anchor-hash'
assert_file "$output/icons/link.svg"
```

- [ ] **Step 2: Run the suite to verify it fails**

Run: `bash tests/content-rendering.sh`
Expected: FAIL — the built page still contains `heading-anchor-hash` (the `assert_not_contains` fails), and/or `expected file .../icons/link.svg`.

- [ ] **Step 3: Create the link icon**

Create `static/icons/link.svg` with a chain glyph (no `fill` attribute, so `mask`/`currentColor` tinting works like `copy.svg`):

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16">
  <path d="M6.354 5.5H4a3 3 0 0 0 0 6h3a3 3 0 0 0 2.83-4H9q-.13 0-.25.031A2 2 0 0 1 7 10.5H4a2 2 0 1 1 0-4h1.535c.218-.376.495-.714.82-1z"/>
  <path d="M9 5.5a3 3 0 0 0-2.83 4h1.098A2 2 0 0 1 9 6.5h3a2 2 0 1 1 0 4h-1.535a4 4 0 0 1-.82 1H12a3 3 0 1 0 0-6z"/>
</svg>
```

- [ ] **Step 4: Remove the hash span from the render hook**

Replace the entire contents of `themes/webcodr/layouts/_default/_markup/render-heading.html` with:

```html
<h{{ .Level }} id="{{ .Anchor | safeURL }}"><a href="#{{ .Anchor | safeURL }}" class="heading-anchor">{{ .Text | safeHTML }}</a></h{{ .Level }}>
```

- [ ] **Step 5: Run the suite to verify it passes**

Run: `bash tests/content-rendering.sh`
Expected: PASS — `Content rendering checks passed.`

- [ ] **Step 6: Commit**

```bash
git add static/icons/link.svg themes/webcodr/layouts/_default/_markup/render-heading.html tests/content-rendering.sh
git commit -m "feat: drop heading hash glyph and add link icon asset

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 2: CSS — copy-link button + toast styles

**Files:**
- Modify: `assets/css/webcodr.css:846-872` (remove old hash rules), insert new rules in their place.

**Interfaces:**
- Consumes: `/icons/link.svg` (Task 1); CSS custom properties already defined in `:root` (`--code-background-color`, `--copy-button-hover-background-color`, `--code-text-color`, `--post-meta-text-color`, `--post-text-color`, `--code-scrollback-background-color`, `--headline-base-color`, `--syntax-error-color`, `--mobile-gutter`).
- Produces: `.heading-anchor-copy` (styled + revealed on hover, hidden on touch) and `.toast` / `.toast--visible` / `.toast--error` classes consumed by the JS in Task 3.

- [ ] **Step 1: Remove the old hash rules**

In `assets/css/webcodr.css`, delete this exact block (currently lines 846–872):

```css
.heading-anchor-hash {
	display: inline-block;
	margin-left: 0.5rem;
	color: var(--headline-secondary-color);
	opacity: 0;
	transition: opacity 0.15s ease-in-out;
}
.heading-anchor:hover .heading-anchor-hash,
.heading-anchor:focus-visible .heading-anchor-hash {
	opacity: 1;
}
@media (hover: none) {
	.heading-anchor-hash {
		opacity: 1;
	}
}
@media screen and (min-width: 880px) {
	:is(h2, h3, h4, h5, h6) {
		position: relative;
	}
	.heading-anchor-hash {
		position: absolute;
		right: 100%;
		margin-left: 0;
		margin-right: 0.5rem;
	}
}
```

- [ ] **Step 2: Insert the new button + toast rules**

In the same location (between the `.heading-anchor:hover … { text-decoration: underline; }` rule and `.post-content .highlight { … }`), insert:

```css
/* Copy-link button revealed beside sub headlines on hover-capable devices. */
@media (hover: hover) {
	:is(h2, h3, h4, h5, h6) {
		position: relative;
	}

	.heading-anchor-copy {
		display: inline-flex;
		align-items: center;
		justify-content: center;
		width: 1.6rem;
		height: 1.6rem;
		margin-left: 0.5rem;
		border: none;
		border-radius: 4px;
		padding: 0;
		--heading-anchor-icon: url("/icons/link.svg");
		background-color: var(--code-background-color);
		color: var(--post-meta-text-color);
		cursor: pointer;
		vertical-align: middle;
		opacity: 0;
		transition: opacity 0.15s ease-in-out;
	}

	.heading-anchor-copy::before {
		content: "";
		display: block;
		width: 1rem;
		height: 1rem;
		background-color: currentColor;
		-webkit-mask: var(--heading-anchor-icon) center / contain no-repeat;
		mask: var(--heading-anchor-icon) center / contain no-repeat;
	}

	.heading-anchor-copy:hover,
	.heading-anchor-copy:focus-visible {
		background-color: var(--copy-button-hover-background-color);
		color: var(--code-text-color);
	}

	:is(h2, h3, h4, h5, h6):hover .heading-anchor-copy,
	.heading-anchor-copy:focus-visible {
		opacity: 1;
	}
}

/* On wide viewports pin the button to the left of the heading (where # sat). */
@media (hover: hover) and (min-width: 880px) {
	.heading-anchor-copy {
		position: absolute;
		right: 100%;
		margin: 0 0.5rem 0 0;
	}
}

/* Touch devices: no hash, no replacement. */
@media (hover: none) {
	.heading-anchor-copy {
		display: none;
	}
}

.toast {
	position: fixed;
	right: var(--mobile-gutter);
	bottom: var(--mobile-gutter);
	z-index: 20;
	max-width: calc(100vw - 2 * var(--mobile-gutter));
	padding: 0.75rem 1rem;
	border: 1px solid var(--code-scrollback-background-color);
	border-left: 4px solid var(--headline-base-color);
	border-radius: 5px;
	background-color: var(--code-background-color);
	color: var(--post-text-color);
	box-shadow: 0 4px 12px rgba(0, 0, 0, 0.25);
	font-size: 1rem;
	opacity: 0;
	transform: translateY(0.5rem);
	pointer-events: none;
	transition:
		opacity 0.2s ease-in-out,
		transform 0.2s ease-in-out;
}

.toast--visible {
	opacity: 1;
	transform: translateY(0);
}

.toast--error {
	border-left-color: var(--syntax-error-color);
	color: var(--syntax-error-color);
}

@media (prefers-reduced-motion: reduce) {
	.toast {
		transform: none;
		transition: opacity 0.2s ease-in-out;
	}
	.toast--visible {
		transform: none;
	}
}
```

- [ ] **Step 3: Build and run the suite**

Run: `hugo --quiet && for t in tests/*.sh; do bash "$t"; done`
Expected: Hugo builds without errors; every test prints its "checks passed." line and the loop exits 0.

- [ ] **Step 4: Commit**

```bash
git add assets/css/webcodr.css
git commit -m "feat: style heading copy-link button and toast

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 3: JS — create copy button, wire clipboard + toast

**Files:**
- Modify: `assets/js/webcodr.js` (add helpers before the `DOMContentLoaded` handler at line 290; add one call inside it).

**Interfaces:**
- Consumes: existing `copyToClipboard(text)` helper (line 79); `.heading-anchor` anchors and `.heading-anchor-copy` / `.toast*` CSS from Tasks 1–2.
- Produces: runtime behavior only — no exports.

- [ ] **Step 1: Add the toast + heading-anchor helpers**

In `assets/js/webcodr.js`, immediately before the `document.addEventListener("DOMContentLoaded", …)` block (currently line 290), insert:

```javascript
const showToast = (() => {
	let toast = null;
	let hideTimer = null;

	return (message, variant = "success") => {
		if (!toast) {
			toast = document.createElement("div");
			toast.className = "toast";
			toast.setAttribute("role", "status");
			toast.setAttribute("aria-live", "polite");
			toast.setAttribute("aria-atomic", "true");
			document.body.append(toast);
		}

		toast.textContent = message;
		toast.classList.toggle("toast--error", variant === "error");
		// Force reflow so re-triggering restarts the fade-in transition.
		void toast.offsetWidth;
		toast.classList.add("toast--visible");

		clearTimeout(hideTimer);
		hideTimer = setTimeout(() => {
			toast.classList.remove("toast--visible");
		}, 2000);
	};
})();
const createHeadingAnchorButton = (url) => {
	const button = document.createElement("button");
	button.type = "button";
	button.classList.add("heading-anchor-copy");
	button.setAttribute("aria-label", "Copy link to this section");
	button.title = "Copy link to this section";
	button.addEventListener("click", async () => {
		try {
			await copyToClipboard(url);
			showToast("Link copied");
		} catch (_) {
			showToast("Couldn't copy link", "error");
		}
	});

	return button;
};
const setupHeadingAnchors = () => {
	const anchors = document.querySelectorAll(".post-content .heading-anchor");

	for (const anchor of anchors) {
		const url = new URL(anchor.getAttribute("href"), window.location.href)
			.href;
		anchor.parentElement.append(createHeadingAnchorButton(url));
	}
};
```

- [ ] **Step 2: Call the setup on DOMContentLoaded**

Change the existing handler (line 290–294) from:

```javascript
document.addEventListener("DOMContentLoaded", () => {
	setupThemeSelector();
	setupCodeBlocks();
	setupSearch();
});
```

to:

```javascript
document.addEventListener("DOMContentLoaded", () => {
	setupThemeSelector();
	setupCodeBlocks();
	setupHeadingAnchors();
	setupSearch();
});
```

- [ ] **Step 3: Build and run the suite**

Run: `hugo --quiet && for t in tests/*.sh; do bash "$t"; done`
Expected: Hugo builds without errors; all smoke tests pass.

- [ ] **Step 4: Manual verification**

Run: `hugo server` and open a post with sub headings (e.g. `/2026/07/using-fd-rg-fzf-and-bat-to-find-things-fast/`).
Verify, on a hover-capable (desktop) viewport:
- Hovering an `h2`/`h3` reveals the link-icon button to the left of the heading; it shows a hover background.
- Tabbing to the button (keyboard) reveals it via `:focus-visible`.
- Clicking it copies the absolute section URL (paste to confirm it is `http://localhost:1313/…/#anchor`) and a toast reads "Link copied" in the bottom-right, fading out after ~2s.

Then, using browser devtools device emulation (or a `(hover: none)` emulation), confirm no icon appears next to headings.

- [ ] **Step 5: Commit**

```bash
git add assets/js/webcodr.js
git commit -m "feat: copy section link from heading icon with toast

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Notes

- The button is JS-created (not server-rendered) so there is no dead button when JS is disabled — matching the existing code copy button architecture. Without JS, headings remain plain jump-links.
- A `<button>` cannot nest inside the `<a>`, so it is appended as a sibling inside the heading element (`anchor.parentElement`).
- The absolute-position rule at ≥880px pins the button left of the heading regardless of DOM order, so its being the heading's last child is fine.

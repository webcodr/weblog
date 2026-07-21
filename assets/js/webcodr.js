const themeStorageKey = "webcodr-theme";
const explicitThemes = new Set(["light", "dark"]);
const getThemePreference = () => {
	try {
		const theme = localStorage.getItem(themeStorageKey);
		return explicitThemes.has(theme) ? theme : "system";
	} catch (_) {
		return "system";
	}
};
const persistThemePreference = (theme) => {
	try {
		if (theme === "system") {
			localStorage.removeItem(themeStorageKey);
		} else {
			localStorage.setItem(themeStorageKey, theme);
		}
	} catch (_) {
		// Theme switching still works for the current page if storage is blocked.
	}
};
const applyThemePreference = (theme, persist = true) => {
	if (explicitThemes.has(theme)) {
		document.documentElement.dataset.theme = theme;
	} else {
		delete document.documentElement.dataset.theme;
	}

	if (persist) {
		persistThemePreference(theme);
	}
};
const updateThemeButtons = (buttons, theme) => {
	for (const button of buttons) {
		button.setAttribute(
			"aria-pressed",
			String(button.dataset.themeValue === theme),
		);
	}
};
const setupThemeSelector = () => {
	const selector = document.querySelector("#theme-selector");

	if (!selector) {
		return;
	}

	const buttons = selector.querySelectorAll("[data-theme-value]");
	const selectTheme = (theme, persist = true) => {
		applyThemePreference(theme, persist);
		updateThemeButtons(buttons, theme);
	};
	selectTheme(getThemePreference(), false);
	selector.hidden = false;

	for (const button of buttons) {
		button.addEventListener("click", () => {
			selectTheme(button.dataset.themeValue);
		});
	}

	window.addEventListener("storage", (event) => {
		if (event.key !== themeStorageKey) {
			return;
		}

		const updatedTheme = explicitThemes.has(event.newValue)
			? event.newValue
			: "system";
		selectTheme(updatedTheme, false);
	});
};
const languageAliases = {
	golang: "go",
	sh: "bash",
};
const sanitizeLanguageName = (language) =>
	languageAliases[language.toLowerCase()] ?? language;
const copyToClipboard = async (text) => {
	if (!navigator.clipboard) {
		throw new Error("Clipboard API unavailable");
	}

	await navigator.clipboard.writeText(text);
};
const copyButtonStates = {
	ready: {
		label: "Copy code to clipboard",
		className: null,
	},
	success: {
		label: "Copied code to clipboard",
		className: "post-content--copy-success",
	},
	error: {
		label: "Could not copy code",
		className: "post-content--copy-error",
	},
};
const setCopyButtonState = (copyButton, state) => {
	const buttonState = copyButtonStates[state];

	copyButton.setAttribute("aria-label", buttonState.label);
	copyButton.title = buttonState.label;
	copyButton.classList.remove(
		"post-content--copy-success",
		"post-content--copy-error",
	);

	if (buttonState.className) {
		copyButton.classList.add(buttonState.className);
	}
};
const createCopyButton = (codeBlock) => {
	const copyButton = document.createElement("button");
	copyButton.type = "button";
	copyButton.classList.add("post-content--copy");
	setCopyButtonState(copyButton, "ready");
	copyButton.addEventListener("click", async () => {
		copyButton.disabled = true;

		try {
			await copyToClipboard(codeBlock.textContent);
			setCopyButtonState(copyButton, "success");
		} catch (_) {
			setCopyButtonState(copyButton, "error");
		}

		setTimeout(() => {
			copyButton.disabled = false;
			setCopyButtonState(copyButton, "ready");
		}, 2000);
	});

	return copyButton;
};
const updateOverflowFade = (codeBlock) => {
	const pre = codeBlock.closest("pre");
	const hasClippedContent =
		codeBlock.scrollLeft + codeBlock.clientWidth < codeBlock.scrollWidth - 1;

	pre.classList.toggle("post-content--overflow-right", hasClippedContent);
};
const overlayScrollbar = (codeBlock) => {
	codeBlock.style.marginBottom = "";
	const scrollbarHeight = codeBlock.offsetHeight - codeBlock.clientHeight;

	if (scrollbarHeight > 0) {
		codeBlock.style.marginBottom = `-${scrollbarHeight}px`;
	}
};
const refreshCodeBlock = (codeBlock) => {
	overlayScrollbar(codeBlock);
	updateOverflowFade(codeBlock);
};
const setupCodeBlocks = () => {
	const codeBlocks = [
		...document.querySelectorAll(".post-content .chroma code[data-lang]"),
	].filter((codeBlock) => codeBlock.closest("pre"));
	if (codeBlocks.length === 0) {
		return;
	}
	for (const codeBlock of codeBlocks) {
		const pre = codeBlock.closest("pre");
		const parent = pre.parentElement;

		if (!pre.querySelector(".post-content--language")) {
			const nameElement = document.createElement("span");
			nameElement.textContent = sanitizeLanguageName(codeBlock.dataset.lang);
			nameElement.classList.add("post-content--language");
			parent.before(nameElement);
		}

		if (!pre.querySelector(".post-content--copy")) {
			pre.append(createCopyButton(codeBlock));
		}

		codeBlock.addEventListener(
			"scroll",
			() => updateOverflowFade(codeBlock),
			{ passive: true },
		);

		refreshCodeBlock(codeBlock);
	}

	let resizeTimer;
	window.addEventListener("resize", () => {
		clearTimeout(resizeTimer);
		resizeTimer = setTimeout(() => {
			codeBlocks.forEach(refreshCodeBlock);
		}, 150);
	});
};
const createSearchExcerpt = (html) => {
	const parsed = new DOMParser().parseFromString(html, "text/html");
	const fragment = document.createDocumentFragment();

	for (const node of parsed.body.childNodes) {
		if (node.nodeType === Node.ELEMENT_NODE && node.tagName === "MARK") {
			const mark = document.createElement("mark");
			mark.textContent = node.textContent;
			fragment.append(mark);
		} else {
			fragment.append(document.createTextNode(node.textContent ?? ""));
		}
	}

	return fragment;
};
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
			total === 0
				? "No results found."
				: `${total} result${total === 1 ? "" : "s"}`;

		for (const result of results) {
			const item = document.createElement("li");
			item.classList.add("search-result");

			const link = document.createElement("a");
			link.href = result.url;
			link.textContent = result.meta.title;
			link.classList.add("search-result--title");

			const excerpt = document.createElement("p");
			excerpt.classList.add("search-result--excerpt");
			excerpt.append(createSearchExcerpt(result.excerpt));

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
document.addEventListener("DOMContentLoaded", () => {
	setupThemeSelector();
	setupCodeBlocks();
	setupHeadingAnchors();
	setupSearch();
});

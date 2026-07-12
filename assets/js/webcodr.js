(function polyfill() {
	const relList = document.createElement("link").relList;
	if (relList && relList.supports && relList.supports("modulepreload")) return;
	for (const link of document.querySelectorAll('link[rel="modulepreload"]'))
		processPreload(link);
	new MutationObserver((mutations) => {
		for (const mutation of mutations) {
			if (mutation.type !== "childList") continue;
			for (const node of mutation.addedNodes)
				if (node.tagName === "LINK" && node.rel === "modulepreload")
					processPreload(node);
		}
	}).observe(document, {
		childList: true,
		subtree: true,
	});
	function getFetchOpts(link) {
		const fetchOpts = {};
		if (link.integrity) fetchOpts.integrity = link.integrity;
		if (link.referrerPolicy) fetchOpts.referrerPolicy = link.referrerPolicy;
		if (link.crossOrigin === "use-credentials")
			fetchOpts.credentials = "include";
		else if (link.crossOrigin === "anonymous") fetchOpts.credentials = "omit";
		else fetchOpts.credentials = "same-origin";
		return fetchOpts;
	}
	function processPreload(link) {
		if (link.ep) return;
		link.ep = true;
		const fetchOpts = getFetchOpts(link);
		fetch(link.href, fetchOpts);
	}
})();
const languageAliases = {
	golang: "go",
	sh: "bash",
};
const sanitizeLanguageName = (language) =>
	(languageAliases[language.toLowerCase()] ??= language);
const copyToClipboard = async (text) => {
	if (navigator.clipboard && window.isSecureContext) {
		await navigator.clipboard.writeText(text);
		return;
	}

	const textArea = document.createElement("textarea");
	textArea.value = text;
	textArea.style.position = "fixed";
	textArea.style.top = "0";
	textArea.style.left = "0";
	textArea.style.opacity = "0";
	document.body.append(textArea);
	textArea.focus();
	textArea.select();

	const success = document.execCommand("copy");
	textArea.remove();

	if (!success) {
		throw new Error("Copy command failed");
	}
};
const setCopyButtonState = (copyButton, state) => {
	const states = {
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
	const buttonState = states[state];

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
const overlayScrollbar = (codeBlock) => {
	codeBlock.style.marginBottom = "";
	const scrollbarHeight = codeBlock.offsetHeight - codeBlock.clientHeight;

	if (scrollbarHeight > 0) {
		codeBlock.style.marginBottom = `-${scrollbarHeight}px`;
	}
};
const setupCodeBlocks = () => {
	const codeBlocks = document.querySelectorAll(
		".post-content .chroma code[data-lang]",
	);
	if (codeBlocks.length === 0) {
		return;
	}
	for (const codeBlock of codeBlocks) {
		const pre = codeBlock.closest("pre");

		if (!pre) {
			continue;
		}

		const parent = pre.parentElement;

		if (!pre.querySelector(".post-content--language")) {
			const nameElement = document.createElement("span");
			const language = codeBlock.getAttribute("data-lang");
			const textNode = document.createTextNode(sanitizeLanguageName(language));
			nameElement.append(textNode);
			nameElement.classList.add("post-content--language");
			parent.before(nameElement);
		}

		if (!pre.querySelector(".post-content--copy")) {
			pre.append(createCopyButton(codeBlock));
		}

		overlayScrollbar(codeBlock);
	}

	window.addEventListener("resize", () => {
		for (const codeBlock of codeBlocks) {
			overlayScrollbar(codeBlock);
		}
	});
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
document.addEventListener("DOMContentLoaded", () => {
	setupCodeBlocks();
	setupSearch();
});

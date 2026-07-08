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

		if (!pre.querySelector(".post-content--language")) {
			const nameElement = document.createElement("span");
			const language = codeBlock.getAttribute("data-lang");
			const textNode = document.createTextNode(sanitizeLanguageName(language));
			nameElement.append(textNode);
			nameElement.classList.add("post-content--language");
			pre.prepend(nameElement);
		}

		if (!pre.querySelector(".post-content--copy")) {
			pre.append(createCopyButton(codeBlock));
		}
	}
};
document.addEventListener("DOMContentLoaded", () => {
	setupCodeBlocks();
});

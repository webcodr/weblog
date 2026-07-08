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
const createSvgIcon = (paths) => {
	const svgNamespace = "http://www.w3.org/2000/svg";
	const icon = document.createElementNS(svgNamespace, "svg");
	icon.setAttribute("aria-hidden", "true");
	icon.setAttribute("viewBox", "0 0 16 16");

	for (const pathDefinition of paths) {
		const path = document.createElementNS(svgNamespace, "path");
		path.setAttribute("d", pathDefinition.d);

		if (pathDefinition.fillRule) {
			path.setAttribute("fill-rule", pathDefinition.fillRule);
		}

		icon.append(path);
	}

	return icon;
};
const setCopyButtonState = (copyButton, state) => {
	const states = {
		ready: {
			label: "Copy code to clipboard",
			paths: [
				{
					d: "M4 2a2 2 0 0 1 2-2h8a2 2 0 0 1 2 2v8a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2zm2-1a1 1 0 0 0-1 1v8a1 1 0 0 0 1 1h8a1 1 0 0 0 1-1V2a1 1 0 0 0-1-1zM2 5a1 1 0 0 0-1 1v8a1 1 0 0 0 1 1h8a1 1 0 0 0 1-1v-1h1v1a2 2 0 0 1-2 2H2a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2h1v1z",
					fillRule: "evenodd",
				},
			],
			className: null,
		},
		success: {
			label: "Copied code to clipboard",
			paths: [
				{
					d: "M12.736 3.97a.733.733 0 0 1 1.047 0c.286.289.29.756.01 1.05L7.88 12.01a.733.733 0 0 1-1.065.02L3.217 8.384a.757.757 0 0 1 0-1.06.733.733 0 0 1 1.047 0l3.052 3.093 5.4-6.425z",
				},
			],
			className: "post-content--copy-success",
		},
		error: {
			label: "Could not copy code",
			paths: [
				{
					d: "M7.005 3.1a1 1 0 1 1 1.99 0l-.388 6.35a.61.61 0 0 1-1.214 0zM7 12a1 1 0 1 1 2 0 1 1 0 0 1-2 0",
				},
			],
			className: "post-content--copy-error",
		},
	};
	const buttonState = states[state];

	copyButton.replaceChildren(createSvgIcon(buttonState.paths));
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

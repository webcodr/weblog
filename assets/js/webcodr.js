(function polyfill() {
  const relList = document.createElement("link").relList;
  if (relList && relList.supports && relList.supports("modulepreload")) return;
  for (const link of document.querySelectorAll('link[rel="modulepreload"]')) processPreload(link);
  new MutationObserver((mutations) => {
    for (const mutation of mutations) {
      if (mutation.type !== "childList") continue;
      for (const node of mutation.addedNodes) if (node.tagName === "LINK" && node.rel === "modulepreload") processPreload(node);
    }
  }).observe(document, {
    childList: true,
    subtree: true
  });
  function getFetchOpts(link) {
    const fetchOpts = {};
    if (link.integrity) fetchOpts.integrity = link.integrity;
    if (link.referrerPolicy) fetchOpts.referrerPolicy = link.referrerPolicy;
    if (link.crossOrigin === "use-credentials") fetchOpts.credentials = "include";
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
  sh: "bash"
};
const sanitizeLanguageName = (language) => languageAliases[language.toLowerCase()] ??= language;
const setLanguage = () => {
  const codeBlocks = document.querySelectorAll("[data-lang]");
  if (codeBlocks.length === 0) {
    return;
  }
  for (const codeBlock of codeBlocks) {
    const nameElement = document.createElement("span");
    const language = codeBlock.getAttribute("data-lang");
    const textNode = document.createTextNode(sanitizeLanguageName(language));
    nameElement.appendChild(textNode);
    nameElement.classList.add("post-content--language");
    codeBlock.parentNode.prepend(nameElement);
  }
};
document.addEventListener("DOMContentLoaded", () => {
  setLanguage();
});

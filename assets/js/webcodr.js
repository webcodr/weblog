(function(){const o=document.createElement("link").relList;if(o&&o.supports&&o.supports("modulepreload"))return;for(const e of document.querySelectorAll('link[rel="modulepreload"]'))s(e);new MutationObserver(e=>{for(const t of e)if(t.type==="childList")for(const c of t.addedNodes)c.tagName==="LINK"&&c.rel==="modulepreload"&&s(c)}).observe(document,{childList:!0,subtree:!0});function n(e){const t={};return e.integrity&&(t.integrity=e.integrity),e.referrerPolicy&&(t.referrerPolicy=e.referrerPolicy),e.crossOrigin==="use-credentials"?t.credentials="include":e.crossOrigin==="anonymous"?t.credentials="omit":t.credentials="same-origin",t}function s(e){if(e.ep)return;e.ep=!0;const t=n(e);fetch(e.href,t)}})();const i={golang:"go",sh:"bash"},d=r=>{var o;return i[o=r.toLowerCase()]??(i[o]=r)},a=()=>{const r=document.querySelectorAll("[data-lang]");if(r.length!==0)for(const o of r){const n=document.createElement("span"),s=o.getAttribute("data-lang"),e=document.createTextNode(d(s));n.appendChild(e),n.classList.add("post-content--language"),o.parentNode.prepend(n)}};document.addEventListener("DOMContentLoaded",()=>{a()});

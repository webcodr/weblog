#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
output=$(mktemp -d)
trap 'rm -rf "$output"' EXIT

fail() {
	printf 'FAIL: %s\n' "$1" >&2
	exit 1
}

assert_contains() {
	grep -Fq -- "$2" "$1" || fail "expected $1 to contain: $2"
}

hugo --source "$root" --destination "$output" --quiet

home="$output/index.html"
css="$root/assets/css/webcodr.css"
js="$root/assets/js/webcodr.js"
theme_init="$root/assets/js/theme-init.js"

assert_contains "$home" 'id="theme-selector"'
assert_contains "$home" 'role="group"'
assert_contains "$home" 'aria-label="Theme"'
assert_contains "$home" 'data-theme-value="system"'
assert_contains "$home" 'data-theme-value="light"'
assert_contains "$home" 'data-theme-value="dark"'
assert_contains "$home" 'aria-label="Use light theme"'
assert_contains "$home" 'aria-label="Use dark theme"'
assert_contains "$home" 'class="theme-selector-icon"'
assert_contains "$home" 'src="/js/theme-init.'
assert_contains "$home" 'integrity="sha512-'

theme_script_line=$(grep -nF 'src="/js/theme-init.' "$home" | cut -d: -f1)
stylesheet_line=$(grep -nF 'rel="stylesheet"' "$home" | cut -d: -f1)
[[ "$theme_script_line" -lt "$stylesheet_line" ]] || fail "expected theme initialization before the stylesheet"

assert_contains "$css" '.theme-selector[hidden] {'
assert_contains "$css" ':root[data-theme="light"] {'
assert_contains "$css" '@media (prefers-color-scheme: light) {'
assert_contains "$css" ':root:not([data-theme]) {'
assert_contains "$css" '--container-background-color: #e1e2e7;'
assert_contains "$css" '--post-text-color: #3760bf;'
assert_contains "$css" '--syntax-keyword-color: #9854f1;'
assert_contains "$css" 'color-scheme: light;'
assert_contains "$css" 'color-scheme: dark;'

assert_contains "$theme_init" 'localStorage.getItem("webcodr-theme")'
assert_contains "$theme_init" 'document.documentElement.dataset.theme = theme'
assert_contains "$js" 'localStorage.removeItem(themeStorageKey)'
assert_contains "$js" 'delete document.documentElement.dataset.theme'
assert_contains "$js" 'button.dataset.themeValue === theme'
assert_contains "$js" 'button.setAttribute('
assert_contains "$js" 'setupThemeSelector();'

printf 'Theme checks passed.\n'

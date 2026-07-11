#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
output=$(mktemp -d)
trap 'rm -rf "$output"' EXIT

fail() {
	printf 'FAIL: %s\n' "$1" >&2
	exit 1
}

assert_file() {
	[[ -f "$1" ]] || fail "expected file $1"
}

assert_contains() {
	grep -Fq -- "$2" "$1" || fail "expected $1 to contain: $2"
}

assert_not_contains() {
	if grep -Fq -- "$2" "$1"; then
		fail "expected $1 not to contain: $2"
	fi
}

hugo --source "$root" --destination "$output" --quiet

assert_file "$output/topics/index.xml"
assert_file "$output/topics/developer-tools/index.xml"
assert_contains "$output/topics/index.html" '<h1 class="post-headline">Topics</h1>'
assert_contains "$output/topics/index.html" '>Developer Tools<'
assert_contains "$output/topics/developer-tools/index.html" 'Find things even faster with srchr'
assert_contains "$output/topics/developer-tools/index.html" 'A cross-platform Rust TUI'
assert_file "$output/archive/index.html"
assert_contains "$output/archive/index.html" '<h2 class="archive-year">2026</h2>'
assert_contains "$output/archive/index.html" 'Find things even faster with srchr'
assert_contains "$output/archive/index.html" '<h2 class="archive-year">2012</h2>'

srchr="$output/2026/07/find-things-even-faster-with-srchr/index.html"
search_post="$output/2026/07/using-fd-rg-fzf-and-bat-to-find-things-fast/index.html"
arch_post="$output/2025/08/im-using-arch-btw/index.html"

assert_contains "$srchr" 'Published <time datetime="2026-07-05T20:28:50Z"'
assert_contains "$srchr" '>Developer Tools</a>'
assert_not_contains "$srchr" 'Updated <time'
assert_not_contains "$srchr" 'class="table-of-contents"'
assert_contains "$search_post" 'class="table-of-contents"'
assert_contains "$search_post" 'href="#usage"'
assert_contains "$arch_post" 'Updated <time datetime="2025-08-28T00:00:00Z"'

legacy_post="$output/2018/04/vue-loader-setup-in-webpack/index.html"

assert_contains "$srchr" 'class="related-posts"'
assert_contains "$srchr" 'Using fd, rg, fzf and bat to find things fast'
assert_contains "$srchr" 'class="post-navigation"'
assert_contains "$srchr" 'class="post-navigation-previous"'
assert_not_contains "$srchr" 'class="post-navigation-next"'
assert_not_contains "$legacy_post" 'class="related-posts"'
assert_contains "$legacy_post" 'class="post-navigation"'

printf 'Blog discovery checks passed.\n'

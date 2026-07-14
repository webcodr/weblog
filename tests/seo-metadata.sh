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

srchr="$output/2026/07/find-things-even-faster-with-srchr/index.html"

assert_file "$srchr"
assert_contains "$output/index.html" '<title>webcodr</title>'
assert_contains "$output/index.html" '<meta property="og:type" content="website" />'
assert_contains "$srchr" '<html lang="en">'
assert_contains "$srchr" '<title>Find things even faster with srchr · webcodr</title>'
assert_contains "$srchr" 'content="A cross-platform Rust TUI for finding files and searching their contents."'
assert_not_contains "$srchr" 'covers a wide range of programming topics'
assert_contains "$srchr" '<meta property="og:title" content="Find things even faster with srchr" />'
assert_contains "$srchr" '<meta property="og:type" content="article" />'
assert_contains "$srchr" '<meta property="og:url" content="https://webcodr.io/2026/07/find-things-even-faster-with-srchr/" />'
assert_contains "$srchr" '<meta property="article:published_time" content="2026-07-05T20:28:50Z" />'
assert_contains "$srchr" '<meta name="twitter:card" content="summary_large_image" />'
assert_contains "$srchr" 'application/ld+json'
assert_contains "$srchr" '"@type": "BlogPosting"'
assert_not_contains "$output/index.html" 'name="keywords"'

feed="$output/index.xml"
assert_file "$feed"
assert_contains "$feed" '<content:encoded>'
assert_contains "$feed" '<link>https://webcodr.io/2026/07/find-things-even-faster-with-srchr/</link>'
assert_contains "$feed" 'xmlns:content="http://purl.org/rss/1.0/modules/content/"'
item_count=$(grep -Fc '<item>' "$feed")
[[ "$item_count" -le 20 && "$item_count" -ge 1 ]] || fail "expected 1-20 feed items, found $item_count"

sitemap_lastmod=$(awk '/mikrotik-hex/{found=1} found && /<lastmod>/{print; exit}' "$output/sitemap.xml")
[[ -n "$sitemap_lastmod" ]] || fail "expected a lastmod entry for the 2017 router post in sitemap.xml"
[[ "$sitemap_lastmod" != *"<lastmod>2017-"* ]] || fail "expected git-derived lastmod, found publication date: $sitemap_lastmod"

printf 'SEO metadata checks passed.\n'

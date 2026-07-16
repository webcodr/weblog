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

assert_not_file() {
	[[ ! -e "$1" ]] || fail "expected no file at $1"
}

assert_contains() {
	grep -Fq -- "$2" "$1" || fail "expected $1 to contain: $2"
}

assert_tree_contains() {
	grep -RFq -- "$2" "$1" || fail "expected $1 to contain: $2"
}

assert_not_contains() {
	if grep -Fq -- "$2" "$1"; then
		fail "expected $1 not to contain: $2"
	fi
}

assert_count() {
	local actual
	actual=$(grep -Fc -- "$3" "$1")
	[[ "$actual" -eq "$2" ]] || fail "expected $1 to contain $2 occurrences of: $3 (found $actual)"
}

assert_post_metadata() {
	local post="$root/content/post/$1"
	grep -Eq '^topics: \[[a-z0-9-]+(, [a-z0-9-]+){0,2}\]$' "$post" || fail "expected 1-3 normalized topics in $post"
	grep -Eq '^description: .+[.!?]$' "$post" || fail "expected a punctuated description in $post"
}

hugo --source "$root" --destination "$output" --quiet

assert_file "$output/topics/index.xml"
assert_file "$output/topics/developer-tools/index.xml"
assert_contains "$output/topics/index.html" '<h1 class="post-headline">Topics</h1>'
assert_contains "$output/topics/index.html" '>Developer Tools<'
assert_contains "$output/topics/developer-tools/index.html" 'Find things even faster with srchr'
assert_contains "$output/topics/developer-tools/index.html" 'A cross-platform Rust TUI'
assert_tree_contains "$output/topics/networking" 'VDSL via Vigor 130 und EdgeRouter X'
assert_tree_contains "$output/topics/javascript" 'Snapshot Tests With Jest'
assert_contains "$output/topics/javascript/index.html" '>Sep 25, 2019</time>'
assert_tree_contains "$output/topics/hardware" 'Tastaturen'
assert_tree_contains "$output/topics/php" 'Array almighty'
assert_file "$output/archive/index.html"
assert_contains "$output/archive/index.html" '<h2 class="archive-year">2026</h2>'
assert_contains "$output/archive/index.html" 'Find things even faster with srchr'
assert_contains "$output/archive/index.html" '<h2 class="archive-year">2012</h2>'

srchr="$output/2026/07/find-things-even-faster-with-srchr/index.html"
search_post="$output/2026/07/using-fd-rg-fzf-and-bat-to-find-things-fast/index.html"
arch_post="$output/2025/08/im-using-arch-btw/index.html"

assert_contains "$srchr" 'Published <time datetime="2026-07-05T20:28:50Z"'
assert_contains "$srchr" '<article class="post" lang="en" data-pagefind-body>'
assert_not_contains "$srchr" 'class="post-language"'
assert_contains "$srchr" '>Developer Tools</a>'
assert_not_contains "$srchr" 'Updated <time'
assert_not_contains "$srchr" 'class="table-of-contents"'
assert_contains "$search_post" 'class="table-of-contents"'
assert_contains "$search_post" 'href="#usage"'
assert_contains "$arch_post" 'Updated <time datetime="2025-08-28T00:00:00Z"'

legacy_post="$output/2018/04/vue-loader-setup-in-webpack/index.html"
german_post="$output/2017/01/ubiquiti-edgerouter-x-vs.-mikrotik-hex/index.html"

assert_contains "$german_post" '<article class="post" lang="de" data-pagefind-body>'
assert_contains "$german_post" '<span class="post-language" lang="de">Deutsch</span>'
assert_contains "$output/archive/index.html" 'class="post-language" lang="de">Deutsch</span>'
assert_not_contains "$output/archive/index.html" 'class="post-language" lang="en">English</span>'
assert_contains "$srchr" 'class="related-posts"'
assert_contains "$srchr" 'Using fd, rg, fzf and bat to find things fast'
assert_contains "$srchr" 'class="post-navigation"'
assert_contains "$srchr" 'class="post-navigation-previous"'
assert_not_contains "$srchr" 'class="post-navigation-next"'
assert_contains "$legacy_post" 'class="related-posts"'
assert_contains "$legacy_post" 'class="post-navigation"'
assert_not_contains "$root/themes/webcodr/layouts/partials/post-navigation.html" '&larr;'
assert_not_contains "$root/themes/webcodr/layouts/partials/post-navigation.html" '&rarr;'

home="$output/index.html"

assert_contains "$home" 'class="header-navigation"'
assert_contains "$home" 'href="/topics/"'
assert_contains "$home" 'href="/archive/"'
assert_contains "$home" 'Inspired by my last post about'
assert_contains "$home" 'type="application/rss&#43;xml"'
assert_count "$home" 5 '<article class="post" lang="'
assert_contains "$output/topics/index.html" 'class="topic-list"'
assert_contains "$output/archive/index.html" 'class="post-index"'
assert_not_file "$output/archive/page/2/index.html"
assert_not_file "$output/topics/page/2/index.html"
assert_not_file "$output/topics/developer-tools/page/2/index.html"
assert_not_file "$output/404/page/2/index.html"
assert_count "$root/assets/css/webcodr.css" 3 'font-family: Roboto, Helvetica, Arial, sans-serif;'
assert_contains "$root/assets/css/webcodr.css" 'a[href]:hover,'
assert_contains "$root/assets/css/webcodr.css" 'a[href]:focus-visible {'
assert_count "$root/assets/css/webcodr.css" 7 'text-decoration: underline;'
assert_not_contains "$root/assets/css/webcodr.css" 'border-bottom: 2px solid var(--post-text-color);'
assert_not_contains "$root/assets/css/webcodr.css" '.related-posts-list'
assert_contains "$root/themes/webcodr/layouts/partials/related-posts.html" 'class="post-index post-index--full-date"'
assert_contains "$root/assets/css/webcodr.css" 'border-left: 4px solid var(--headline-tertiary-color);'
assert_contains "$root/assets/css/webcodr.css" 'border-left: 4px solid var(--headline-base-color);'
for post in "$root"/content/post/*.md; do
	[[ "$(basename "$post")" == "_index.md" ]] && continue
	assert_post_metadata "$(basename "$post")"
done

printf 'Blog discovery checks passed.\n'

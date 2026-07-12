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

search_page="$output/search/index.html"
post_page="$output/2026/07/find-things-even-faster-with-srchr/index.html"

assert_file "$search_page"
assert_contains "$search_page" 'id="search-input"'
assert_contains "$search_page" 'id="search-results"'
assert_contains "$search_page" 'id="search-status"'
assert_contains "$output/index.html" 'href="/search/"'
assert_contains "$post_page" 'data-pagefind-body'
assert_not_contains "$output/index.html" 'data-pagefind-body'
assert_contains "$post_page" 'data-pagefind-ignore'
assert_contains "$root/.github/workflows/deploy_production.yml" 'pagefind'
assert_contains "$root/Caddyfile" "'wasm-unsafe-eval'"

printf 'Search checks passed.\n'

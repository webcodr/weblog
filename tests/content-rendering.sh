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

hugo --source "$root" --destination "$output" --quiet

router_post="$output/2017/01/ubiquiti-edgerouter-x-vs.-mikrotik-hex/index.html"

assert_file "$router_post"
assert_contains "$router_post" 'src="/images/router-benchmark/erx.jpg"'
assert_contains "$router_post" 'loading="lazy"'
assert_contains "$router_post" 'decoding="async"'
grep -Eq 'width="[0-9]+" height="[0-9]+"' "$router_post" || fail "expected intrinsic image dimensions in $router_post"
assert_contains "$router_post" 'alt="Ubiquiti EdgeRouter X"'

search_post="$output/2026/07/using-fd-rg-fzf-and-bat-to-find-things-fast/index.html"

assert_file "$search_post"
assert_contains "$search_post" 'id="usage"'
assert_contains "$search_post" 'href="#usage" class="heading-anchor"'
assert_contains "$search_post" 'class="table-of-contents"'

printf 'Content rendering checks passed.\n'

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

printf 'Blog discovery checks passed.\n'

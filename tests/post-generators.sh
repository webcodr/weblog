#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
workspace=$(mktemp -d)
trap 'rm -rf "$workspace"' EXIT

fail() {
	printf 'FAIL: %s\n' "$1" >&2
	exit 1
}

assert_contains() {
	grep -Fq -- "$2" "$1" || fail "expected $1 to contain: $2"
}

mkdir -p "$workspace/content/post"
(
	cd "$workspace"
	fish "$root/create_post.fish" "Generator metadata test"
)

generated=$(printf '%s\n' "$workspace"/content/post/*_generator-metadata-test.md)
[[ -f "$generated" ]] || fail "expected Fish generator output at $generated"
assert_contains "$generated" 'topics: []'
assert_contains "$generated" 'description: ""'
generated_lines=()
while IFS= read -r line || [[ -n "$line" ]]; do
	generated_lines+=("$line")
done < "$generated"
[[ "${generated_lines[3]}" == 'topics: []' ]] || fail "expected topics after date in Fish output"
[[ "${generated_lines[4]}" == 'description: ""' ]] || fail "expected description after topics in Fish output"
[[ "${generated_lines[5]}" == '---' ]] || fail "expected closing delimiter after description in Fish output"

assert_contains "$root/create_post.ps1" 'topics: []'
assert_contains "$root/create_post.ps1" 'description: ""'
date_line=$(grep -nF 'date: $date' "$root/create_post.ps1" | cut -d: -f1)
topics_line=$(grep -nF 'topics: []' "$root/create_post.ps1" | cut -d: -f1)
description_line=$(grep -nF 'description: ""' "$root/create_post.ps1" | cut -d: -f1)
[[ "$topics_line" -eq $((date_line + 1)) ]] || fail "expected topics after date in PowerShell template"
[[ "$description_line" -eq $((topics_line + 1)) ]] || fail "expected description after topics in PowerShell template"

printf 'Post generator checks passed.\n'

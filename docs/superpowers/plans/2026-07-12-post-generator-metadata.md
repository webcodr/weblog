# Post Generator Metadata Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make both post creation scripts generate explicit empty `topics` and `description` front matter fields.

**Architecture:** Add a standalone shell regression check that runs the Fish generator in a temporary workspace and statically inspects the PowerShell template because no PowerShell runtime is installed. Update only the two output templates; retain their arguments, slug logic, timestamps, and destination behavior.

**Tech Stack:** Fish, PowerShell, Bash, Hugo, YAML front matter

---

### Task 1: Add Metadata Placeholders to Both Generators

**Files:**
- Create: `tests/post-generators.sh`
- Modify: `create_post.fish:10-13`
- Modify: `create_post.ps1:12-17`

- [ ] **Step 1: Write the failing generator regression check**

Create `tests/post-generators.sh`:

```bash
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
mapfile -t generated_lines < "$generated"
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
```

- [ ] **Step 2: Run the check and verify RED**

Run: `bash tests/post-generators.sh`

Expected: FAIL because the generated Fish post does not contain `topics: []`.

- [ ] **Step 3: Update the Fish output template**

Change the output block in `create_post.fish` to:

```fish
    echo "---" > $filename
    echo "title: "$title"" >> $filename
    echo "date: $date" >> $filename
    echo "topics: []" >> $filename
    echo 'description: ""' >> $filename
    echo "---" >> $filename
```

- [ ] **Step 4: Update the PowerShell output template**

Change the here-string in `create_post.ps1` to:

```powershell
    $content = @"
---
title: $Title
date: $date
topics: []
description: ""
---
"@
```

- [ ] **Step 5: Run generator checks and verify GREEN**

Run: `bash tests/post-generators.sh`

Expected: `Post generator checks passed.`

- [ ] **Step 6: Run the complete site verification**

Run: `bash tests/blog-discovery.sh && hugo`

Expected: `Blog discovery checks passed.` followed by a successful Hugo build.

- [ ] **Step 7: Check patch hygiene**

Run: `git diff --check`

Expected: no output and exit status 0.

- [ ] **Step 8: Commit the generator update**

```bash
git add create_post.fish create_post.ps1 tests/post-generators.sh
git commit -m "feat: add metadata to post generators"
```

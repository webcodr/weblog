# Post Generator Metadata Design

## Goal

Ensure posts created by either repository script include the topic and description fields required by the blog's metadata conventions.

## Scope

Update `create_post.fish` and `create_post.ps1`. Preserve their existing title arguments, filename and slug generation, UTC timestamp generation, and output location.

Each generated file will use this front matter shape:

```yaml
---
title: Example title
date: 2026-07-12T12:00:00+00:00
topics: []
description: ""
---
```

`topics` and `description` are explicit YAML placeholders for the author to complete before publishing. The scripts will not add prompts or additional command-line arguments.

## Verification

Automated checks will run the Fish script in an isolated temporary directory and inspect the generated Markdown file. Because this repository and development environment do not provide a PowerShell runtime, the PowerShell template will be checked statically for the same ordered front matter lines. Both scripts must place `topics: []` and `description: ""` between the date and closing delimiter.

The checks must not create or modify files under the repository's real `content/post/` directory. The normal blog regression suite and Hugo build must continue to pass.

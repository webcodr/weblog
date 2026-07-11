# Post Metadata Backfill Design

## Goal

Complete the blog's topic and description metadata so every post participates consistently in topic discovery, related-post selection, and descriptive post indexes.

## Scope

- Add `topics` to the 44 posts that currently have no topic metadata.
- Add `description` to the 52 posts that currently have no description.
- Preserve every existing topic and description value unchanged.
- Do not revise article bodies, titles, dates, or other front matter.

The scope is based on the current 54-post collection. Two posts already have descriptions, and ten already have topics.

## Editorial Process

Each article will be read before its metadata is written. Classification will use the article's primary subjects rather than relying only on its filename, title, or publication date.

Descriptions will:

- Consist of one concise sentence, generally 60 to 160 characters.
- Match the language of the article: German for German posts and English for English posts.
- Summarize the article's subject or practical outcome without promotional filler.
- Name specific technologies or products when they help distinguish the article.
- Use sentence case and terminal punctuation.

## Topic Vocabulary

Each post will receive one to three lowercase topic slugs. Existing topics will be reused whenever accurate. Focused topics such as `networking`, `web-development`, `hardware`, or `apple` may be added where the existing vocabulary does not represent the article.

The final vocabulary will be controlled across the full collection:

- Prefer durable subject areas over narrow phrases copied from titles.
- Use one spelling for each concept and avoid near-duplicates.
- Avoid introducing a topic for a single article when a broader accurate topic exists.
- Retain existing topic values even if a newly introduced term might also fit.

## Content Format

Metadata will follow the YAML front matter style already used by newer posts:

```yaml
topics:
  - networking
  - linux
description: A concise sentence describing the article.
```

Fields will be placed consistently with the newer posts without reformatting unrelated front matter.

## Verification

Automated checks will verify that:

- Every regular post has a non-empty `description`.
- Every regular post has between one and three `topics` values.
- Topic values are lowercase slugs from the resulting controlled vocabulary.
- Existing topic and description values remain unchanged.
- Representative topic pages include newly classified older posts.
- The Hugo site builds successfully.

The generated topic index will also be reviewed for accidental duplicate concepts, overly narrow categories, and obviously incorrect classifications.

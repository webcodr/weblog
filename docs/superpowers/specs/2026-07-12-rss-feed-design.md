# RSS Feed Design

## Goal

Make the blog's existing Hugo RSS feed discoverable while limiting it to the 20 most recent posts.

## Design

- Keep Hugo's built-in summary feed at `/index.xml`.
- Set `services.rss.limit` to `20` in `config.yaml`.
- Add RSS autodiscovery metadata to the shared HTML head using Hugo's home-page RSS output URL.
- Add an `RSS` link to the footer beside the existing Bluesky and About links.
- Do not add or override an RSS template.

## Verification

- Build the site with `hugo`.
- Parse `public/index.xml` as XML.
- Confirm the feed contains no more than 20 items.
- Confirm generated HTML contains RSS autodiscovery metadata and the footer link.

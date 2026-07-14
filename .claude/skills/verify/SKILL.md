# Verify

How to verify changes to this Hugo site end-to-end, including Caddy behavior.

## Build

```bash
hugo --quiet --destination "$SCRATCH/public"   # local hugo must match CI pin in .github/workflows
```

Pagefind assets are only built in CI (`npx pagefind --site public`); client-side
search won't work in a local build unless you run that too.

## Serve through the real Caddyfile

The production Caddyfile only has TLS domain blocks, so append a plain-HTTP
block that reuses the `(site)` snippet:

```bash
cat Caddyfile > "$SCRATCH/Caddyfile.test"
printf '\nhttp://:8080 {\n\timport site\n}\n' >> "$SCRATCH/Caddyfile.test"
docker run --rm -d --name weblog-verify -p 127.0.0.1:8080:8080 \
  -v "$SCRATCH/Caddyfile.test":/etc/caddy/Caddyfile:ro \
  -v "$SCRATCH/public":/srv/current:ro \
  caddy:<same pinned image as docker-compose.yml>
```

Then curl pages/headers. `caddy validate --config ... --adapter caddyfile` in the
same image checks syntax only, not behavior.

## Gotchas

- Directives from the main route (e.g. the `header` security snippet) do NOT
  apply inside `handle_errors` — error responses need their own `import`.
  Always check headers on an error response, not just 200s.
- Screenshots: `chromium --headless --disable-gpu --window-size=1280,720
  --screenshot=out.png <url>` works. To show `:focus` styling, copy a built
  page into the served dir with `autofocus` sed-ed onto the element and
  screenshot that harness page (file:// harnesses can't load the site CSS).
- Test suite: `for t in tests/*.sh; do bash "$t"; done` — needs `hugo` and
  `fish` on PATH. CI runs this in `.github/workflows/ci.yml`.

# Serverless Hugo Deploy Design

## Goal

Remove Hugo from the production server by moving the site build into GitHub Actions while keeping the existing Caddy/Docker serving stack.

## Current State

- The production workflow SSHes into the server, runs `git pull`, then runs `hugo` in `~/projects/weblog`.
- `docker-compose.yml` serves `./public` through Caddy at `/srv`.
- `public/` is generated build output and is not committed.

## Chosen Approach

GitHub Actions will build the site and publish immutable release directories to the server. The server will serve a stable `current` symlink that points at the active release.

Server layout:

```text
~/projects/weblog/
  docker-compose.yml
  Caddyfile
  releases/
    <sha-1>/
    <sha-2>/
  current -> releases/<active-sha>
```

`docker-compose.yml` will change the Caddy content volume from `./public` to `./current`:

```yaml
- ./current:/srv:ro
```

## Deployment Flow

On pushes to `main` and manual `workflow_dispatch` runs, the workflow will:

1. Check out the repository.
2. Install Hugo Extended `0.162.0`.
3. Run `hugo` on the GitHub Actions runner.
4. Verify that `public/index.html` exists.
5. Upload `public/` contents to `~/projects/weblog/releases/${GITHUB_SHA}/` on the server.
6. SSH to the server and atomically update `current` to point at `releases/${GITHUB_SHA}`.
7. Prune older release directories after a successful switch, keeping a small rollback window such as the last 5 releases.

The workflow will continue using the existing SSH secrets:

- `SSH_HOST`
- `SSH_USERNAME`
- `SSH_KEY`

The implementation should prefer `rsync` over SSH for upload because it is straightforward for directory publishing and preserves static file layout cleanly.

The remote symlink switch should use a temporary symlink and atomic rename on Ubuntu:

```sh
ln -sfn "releases/${GITHUB_SHA}" current-new
mv -Tf current-new current
```

Remote SSH scripts should explicitly invoke `bash -s` before using POSIX shell syntax because the production account's login shell may be fish.

## Error Handling

- If checkout, Hugo install, build, or verification fails, the server is not touched.
- If upload fails, `current` is not changed and production keeps serving the previous release.
- If the symlink switch fails, production keeps serving the previous release.
- If cleanup fails after the symlink switch, the deploy can still be treated as successful because the active release was updated.

## Rollback

Rollback is a manual symlink switch on the server:

```sh
cd ~/projects/weblog
ln -sfn releases/<previous-sha> current-new
mv -Tf current-new current
```

Caddy should serve the new symlink target immediately. If Docker does not pick up the updated symlink on the server, the fallback is:

```sh
docker compose restart caddy
```

## One-Time Server Setup

Before the updated Compose configuration is started, the server needs:

1. A `releases/` directory.
2. An initial release directory containing the built site.
3. A `current` symlink pointing at that release.
4. Docker Compose restarted once after the volume changes from `./public` to `./current`.

Future deploys should not require `git pull` or `hugo` on the server.

## Verification

The workflow should verify:

- `hugo` exits successfully.
- `public/index.html` exists before upload.
- The remote `current` symlink resolves to the uploaded release after deployment.

An optional post-deploy smoke check can run `curl -fsS https://webcodr.io/` from the GitHub Actions runner. The existing `k6/load-test.js` remains a standalone production load check and is not part of the deploy workflow.

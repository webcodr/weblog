# Server Rebuild and Container Hardening Plan

> **For agentic workers:** Implement and verify this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. Prepare Tasks 1 to 3 and Task 4's provisioning files before the outage. The operator performs the rebuild and server operations; an agent must not execute destructive remote steps without approval. The previous implementation was reverted; unchecked steps describe future work, not installed files.

**Shell convention:** All workstation commands run in **fish**, including local Git and validation commands. Fences marked `bash` are server-side script contents or commands run in a Bash session on the Debian host, never pasted into the workstation shell. GitHub Actions `run:` blocks use the runner's Bash shell. Replace `HOST` and `OLD_USER` before running commands; do not paste angle-bracket placeholders as shell arguments.

**Goal:** Rebuild the production host from scratch on Debian 13 (Trixie) with a least-privilege layout: a rootful Docker daemon with remapped container identities, a Caddy container that is non-root, read-only and resource-limited, a restricted deploy identity, and automatic security updates.

**Architecture:** The existing Hetzner VM (2 vCPU, 2 GB RAM), reinstalled in place via the Hetzner "Rebuild" action so it keeps its IPv4 and IPv6 addresses and its cloud firewall attachment. Three Unix identities: `root` (console only), `ops` (admin, sudo, owns the compose stack at `/opt/weblog`), and `deploy` (no shell access beyond a forced command, owns `/srv/weblog/site`). Docker CE runs with user-namespace remapping so container root is an unprivileged host uid. Caddy runs as uid 1000 inside the container, on a read-only root filesystem, with named volumes for certificates. GitHub Actions rsyncs a release into `/srv/weblog/site/releases/` through `rrsync` and calls a whitelisted `weblog-release` command to activate or roll back.

**Tech Stack:** Debian 13 Trixie, Docker CE (docker.com apt repo, since Debian's own `docker.io` package lags), Docker Compose v2 plugin, Caddy 2.11 (alpine image, digest pinned), OpenSSH with forced commands, `rrsync`, nftables, `unattended-upgrades`, Hetzner Cloud Firewall.

---

## Decisions

- **Debian 13 over Ubuntu 24.04.** Agreed. Debian's security team ships fixes for all of `main` with public advisories; Ubuntu's coverage for `universe` requires Pro. For a host that only runs SSH, Docker and Caddy, Debian is the smaller and better-maintained surface. Hetzner offers a Debian 13 image directly.
- **Rootful Docker with `userns-remap` over rootless Docker.** Rootless Docker adds slirp4netns/pasta networking, complicates IPv6 and UDP (HTTP/3) port publishing, and gains little here because a single trusted image is run. User-namespace remapping delivers the core property (container root is not host root) with mature networking. Revisit rootless only if more services are added.
- **Named volumes for `/data` and `/config`.** They hold the ACME account key and TLS private keys. The current `./../../caddy_data` relative path depends on the working-directory layout and silently creates an empty directory if it drifts, which triggers Let's Encrypt re-issuance and rate limits.
- **Compose stack and site data live outside `$HOME`.** `/opt/weblog` for the git checkout (compose, Caddyfile), `/srv/weblog/site` for releases. Neither depends on which user runs `docker compose`.
- **Forced SSH command for deploys.** A leaked `SSH_KEY` secret today means a full shell on the host. After this plan it means the ability to upload files into `releases/` and flip a symlink between validated release names, nothing else.
- **Safe uploaded links.** Force `rrsync -wo -munge` on the server, reject symlinks when activating or restoring releases, and keep `/rsyncd-munged` absent inside the Caddy container. Caddy's document root is not a filesystem sandbox: an ordinary uploaded link to `/data` could otherwise expose TLS keys. A stolen deploy key can still replace/delete public content or fill its writable storage; it is not limited to new staging directories.
- **Explicit admin authentication.** `ops` is key-only over SSH with a validated `NOPASSWD` sudo rule. This is intentional full administrator access (membership in `docker` is already root-equivalent). Keep root key login until a second `ops` session passes `sudo -n`; only then disable root SSH.
- **In-place rebuild instead of a parallel VM.** New instances of this class are currently unavailable or markedly more expensive, so the existing server is reinstalled. This costs a planned outage (target under 30 minutes) but avoids any DNS change: the IP addresses stay, and the restored Caddy storage means no new certificate issuance at cutover. A snapshot taken right before the rebuild is the rollback path.
- **Firewall in two layers.** Hetzner Cloud Firewall in front of the VM (allows 22, 80, 443 TCP and 443 UDP, ICMP) and host nftables. Docker's published ports bypass host filtering via the `DOCKER-USER` chain semantics, which is acceptable because only 80/443 are published, but the cloud firewall is the authoritative layer.

## File Structure

- Modify `docker-compose.yml`: non-root user, read-only rootfs, tmpfs, limits, log rotation, named volumes, env-driven site path.
- Modify `Caddyfile`: add a container-loopback-only HTTP health endpoint that serves the current release's index without a redirect.
- Create `.env.example`: documents `WEBLOG_SITE_DIR`.
- Create `server/weblog-release`: server-side release activation and rollback script (installed to `/usr/local/bin/`).
- Create `server/weblog-deploy-shell`: SSH forced-command dispatcher for the `deploy` user.
- Create `server/daemon.json`: Docker daemon configuration.
- Create `server/nftables.conf`: host firewall.
- Create `server/bootstrap.sh`: idempotent host provisioning script (users, packages, Docker, firewall, sshd).
- Modify `.github/workflows/deploy_production.yml`: use the restricted deploy protocol.
- Modify `AGENTS.md`: update the Deployment section for the new paths and identities.
- Modify `.gitignore`: add `.env`.

## Cutover Strategy

The server is rebuilt in place, so everything that can be prepared in advance must be, and the outage is bounded by: snapshot, rebuild (about 2 minutes), bootstrap (about 5 minutes), restore of certificates and the last release, `docker compose up`. Realistic total: 15 to 30 minutes.

Before the outage window, Task 0 copies off Caddy's ACME storage and the currently served release. Prepare and commit Tasks 1 to 2 and Task 4's provisioning files on an infrastructure branch; keep Task 3's workflow change on a separate branch until Task 8. Record the tested infrastructure commit for Task 5. Rehearse bootstrap, deploy confinement, failure recovery, and reboot on a disposable Debian 13 host before rebuilding production. Do not count writing or debugging scripts as part of the outage window.

During the window: snapshot, rebuild with the Debian 13 image, run bootstrap, verify admin access, restore, start Caddy, verify externally over IPv4 and IPv6, reboot, and repeat the checks. Because the IP does not change, DNS needs no change. Do not declare the outage over based on a loopback-only check.

After the window: rotate the GitHub `production` secrets to the new deploy identity, merge the workflow branch, run a deploy, decommission the snapshot after a few days.

---

### Task 0: Back up state from the current server (before the outage)

Run from your workstation in fish against the current host. Nothing here changes the running server. Keep backup storage private; if remote sudo requires a password, arrange and verify a narrowly scoped temporary backup method before starting rather than expecting rsync to supply a TTY.

- [ ] **Step 1: Copy Caddy's ACME storage**

The compose file mounts `~/caddy_data` at `/data`. It holds the ACME account key and the four certificates. Restoring it means zero certificate issuance at cutover and no Let's Encrypt rate-limit exposure.

```fish
mkdir -p -m 700 ~/weblog-migration
chmod 700 ~/weblog-migration
rsync -az --rsync-path="sudo rsync" OLD_USER@HOST:~/caddy_data/ ~/weblog-migration/caddy_data/
chmod -R go-rwx ~/weblog-migration/caddy_data
```

Use `sudo rsync` on the remote side if the files are owned by root (Caddy runs as root in the old setup). Treat this directory like a private key: delete it after the migration.

- [ ] **Step 2: Copy the currently served release**

```fish
set -l rel (ssh OLD_USER@HOST 'readlink ~/projects/weblog/site/current')
if string match -rq '^releases/[0-9]{14}-[0-9a-f]{40}$' -- "$rel"
    rsync -az "OLD_USER@HOST:~/projects/weblog/site/$rel/" ~/weblog-migration/release/
    and string replace 'releases/' '' -- "$rel" > ~/weblog-migration/release-name
else
    printf 'Unexpected current target: %s\n' "$rel" >&2
end
```

Restoring this instead of a placeholder means the real site is back the moment Caddy starts, and CI does not have to run before the outage ends.

- [ ] **Step 3: Note what else lives on the server**

```fish
ssh OLD_USER@HOST 'ls ~ /opt /srv /etc/cron.d 2>/dev/null; crontab -l 2>/dev/null; docker ps -a'
```

Anything beyond the weblog stack must be either backed up now or consciously abandoned. The rebuild wipes the disk.

- [ ] **Step 4: Record the current SSH host key fingerprint**

```fish
ssh-keyscan -t ed25519 HOST > ~/weblog-migration/old_known_hosts
```

The rebuild generates new host keys. Your own `~/.ssh/known_hosts` entry and the `SSH_KNOWN_HOSTS` GitHub secret both need replacing afterwards (Task 7).

---

### Task 1: Harden `docker-compose.yml`

**Files:**
- Modify: `docker-compose.yml`
- Modify: `Caddyfile`
- Create: `.env.example`
- Modify: `.gitignore`

- [ ] **Step 1: Replace the compose file**

```yaml
services:
  caddy:
    image: caddy:2.11.4-alpine@sha256:5f5c8640aae01df9654968d946d8f1a56c497f1dd5c5cda4cf95ab7c14d58648
    restart: unless-stopped
    user: "1000:1000"
    read_only: true
    tmpfs:
      - /tmp:size=64m,mode=1777
    cap_drop:
      - ALL
    security_opt:
      - no-new-privileges:true
    pids_limit: 256
    mem_limit: 384m
    memswap_limit: 384m
    cpus: 1.5
    logging:
      driver: json-file
      options:
        max-size: "20m"
        max-file: "5"
    ports:
      - "80:80"
      - "443:443"
      - "443:443/udp"
    environment:
      XDG_DATA_HOME: /data
      XDG_CONFIG_HOME: /config
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile:ro
      - ${WEBLOG_SITE_DIR:-./site}:/srv:ro
      - caddy_data:/data
      - caddy_config:/config
    networks:
      - caddy
    healthcheck:
      test: ["CMD", "wget", "-q", "--spider", "http://127.0.0.1:8080/"]
      interval: 30s
      timeout: 5s
      retries: 3

volumes:
  caddy_data:
  caddy_config:

networks:
  caddy:
    enable_ipv6: true
```

Notes:
- `user: 1000:1000` works without `NET_BIND_SERVICE` because Docker sets `net.ipv4.ip_unprivileged_port_start=0` inside containers. Keep a fallback in mind: if Caddy logs `permission denied` on `:80`, add `sysctls: ["net.ipv4.ip_unprivileged_port_start=0"]`.
- The healthcheck reads the current release over a dedicated HTTP listener. `wget --spider` follows redirects, so probing the automatic redirect on port 80 would incorrectly reach HTTPS for `127.0.0.1`, for which Caddy has no certificate.
- `mem_limit: 384m` leaves headroom on a 2 GB host for the kernel, sshd, dockerd and page cache. Caddy for a static site idles at ~30 MB.
- Named volumes are created owned by root. Task 6 fixes ownership before the first start, after `docker compose create`.

Append this block to `Caddyfile`, preserving the existing public sites and headers:

```caddyfile
http://127.0.0.1:8080 {
    bind 127.0.0.1
    root * /srv/current
    file_server
}
```

Port 8080 must not be published by Compose or opened in either firewall. The loopback probe establishes local HTTP and index readability; external TLS and protocol checks remain separate gates in Task 6.

- [ ] **Step 2: Add `.env.example`**

```
# Absolute path of the directory containing releases/ and the current symlink.
WEBLOG_SITE_DIR=/srv/weblog/site
```

- [ ] **Step 3: Add `.env` to `.gitignore`**

- [ ] **Step 4: Validate**

```fish
docker compose config
```

Expected: exit code 0, volume source resolves to `./site` locally and to `/srv/weblog/site` when `.env` is present.

- [ ] **Step 5: Commit**

```fish
git add docker-compose.yml Caddyfile .env.example .gitignore
git commit -m "build: run caddy non-root, read-only and resource-limited"
```

### Task 2: Server-side deploy scripts

**Files:**
- Create: `server/weblog-release`
- Create: `server/weblog-deploy-shell`

- [ ] **Step 1: Write `server/weblog-release`**

This script is the only thing the deploy key can execute besides rsync. It validates names and argument counts. Release operations share a lock; CI's existing concurrency group serializes the complete upload/activate/smoke/prune transaction. Do not run manual deployments concurrently with CI.

```bash
#!/usr/bin/env bash
# weblog-release: manage releases in /srv/weblog/site
# Usage:
#   weblog-release prepare  <tmp-name>
#   weblog-release activate <tmp-name> <release-name>
#   weblog-release rollback <release-name>
#   weblog-release rollback-if-current <expected-name> <previous-name>
#   weblog-release prune <expected-current-name> <previous-name>
#   weblog-release current
set -euo pipefail

SITE_DIR=/srv/weblog/site
KEEP=5
RELEASE_RE='^[0-9]{14}-[0-9a-f]{40}$'
TMP_RE='^\.[0-9]{14}-[0-9a-f]{40}\.[0-9]+\.tmp$'

die() { echo "weblog-release: $*" >&2; exit 1; }
check() { [[ "$2" =~ $1 ]] || die "invalid name: $2"; }

cd "$SITE_DIR"
exec 9>.release.lock
flock -x 9
mkdir -p releases

validate_release() {
  local target=$1 links
  test -d "releases/$target" && test ! -L "releases/$target" || die "not a release directory"
  links=$(find "releases/$target" -type l -print -quit) || die "cannot inspect release"
  [ -z "$links" ] || die "release contains symlinks"
  test -f "releases/$target/index.html" || die "releases/$target has no index.html"
}

flip() {
  local target=$1
  validate_release "$target"
  ln -sfn "releases/$target" current-new
  mv -Tf current-new current
  [ "$(readlink current)" = "releases/$target" ] || die "symlink flip failed"
}

case "${1:-}" in
  prepare)
    [ "$#" -eq 2 ] || die "usage: prepare <tmp-name>"
    check "$TMP_RE" "${2:-}"
    find releases -mindepth 1 -maxdepth 1 -name '.*.tmp' -exec rm -rf {} +
    mkdir -p "releases/$2"
    ;;
  activate)
    [ "$#" -eq 3 ] || die "usage: activate <tmp-name> <release-name>"
    check "$TMP_RE" "${2:-}"
    check "$RELEASE_RE" "${3:-}"
    validate_release "$2"
    if [ -e "releases/$3" ]; then
      validate_release "$3"
      rm -rf "releases/$2"
    else
      mv "releases/$2" "releases/$3"
    fi
    touch "releases/$3"
    flip "$3"
    echo "activated $3"
    ;;
  rollback)
    [ "$#" -eq 2 ] || die "usage: rollback <release-name>"
    check "$RELEASE_RE" "${2:-}"
    flip "$2"
    echo "rolled back to $2"
    ;;
  rollback-if-current)
    [ "$#" -eq 3 ] || die "usage: rollback-if-current <expected-name> <previous-name>"
    check "$RELEASE_RE" "$2"
    check "$RELEASE_RE" "$3"
    if [ "$(readlink current)" = "releases/$2" ]; then
      flip "$3"
      echo "rolled back to $3"
    else
      echo "current changed or activation did not happen; not rolling back"
    fi
    ;;
  prune)
    [ "$#" -eq 3 ] || die "usage: prune <expected-current-name> <previous-name>"
    check "$RELEASE_RE" "$2"
    check "$RELEASE_RE" "$3"
    [ "$(readlink current)" = "releases/$2" ] || die "current changed; not pruning"
    validate_release "$2"
    validate_release "$3"
    # Keep the five newest releases plus current/previous if either is older.
    candidates=$(find releases -mindepth 1 -maxdepth 1 -type d -printf '%T@ %f\n' | sort -rn)
    count=0
    while read -r _ name; do
      [[ "$name" =~ $RELEASE_RE ]] || continue
      count=$((count + 1))
      if [ "$count" -le "$KEEP" ] || [ "$name" = "$2" ] || [ "$name" = "$3" ]; then
        continue
      fi
      rm -rf -- "releases/$name"
    done <<< "$candidates"
    ;;
  current)
    [ "$#" -eq 1 ] || die "usage: current"
    if [ -L current ]; then
      readlink current
    elif [ -e current ]; then
      die "current is not a symlink"
    fi
    ;;
  *)
    die "unknown command: ${1:-}"
    ;;
esac
```

- [ ] **Step 2: Write `server/weblog-deploy-shell`**

Installed as the forced command for the deploy key. It allows exactly two things: an rsync server confined to `releases/`, and `weblog-release` subcommands.

```bash
#!/usr/bin/env bash
set -euo pipefail
set -f
cmd="${SSH_ORIGINAL_COMMAND:-}"
case "$cmd" in
  "rsync --server "*)
    exec /usr/bin/rrsync -wo -munge /srv/weblog/site/releases
    ;;
  "weblog-release "*)
    # shellcheck disable=SC2086
    exec /usr/local/bin/weblog-release ${cmd#weblog-release }
    ;;
  *)
    echo "command not permitted" >&2
    exit 126
    ;;
esac
```

Notes:
- `rrsync -wo` disallows rsync downloads; the public site is still readable over HTTP. `-munge` forces uploaded links to point below `/rsyncd-munged/`, which must not exist inside the container. This also protects against links uploaded into an already-active release, after activation validation. Trixie's rsync supports both options; verify them during rehearsal.
- `set -f` disables glob expansion before splitting the subcommand. `weblog-release` then validates argument counts and names; nothing uses `eval`.
- The account's login shell must be `/bin/dash`, not `nologin` (which prevents `ForceCommand` from running) or Bash (which can read SSH startup files before the dispatcher).

- [ ] **Step 3: Lint**

Run on the workstation with ShellCheck installed and selected in the local tool environment:

```fish
shellcheck server/weblog-release server/weblog-deploy-shell
```

- [ ] **Step 4: Commit**

```fish
git add server/
git commit -m "ops: add restricted release and deploy-shell scripts"
```

### Task 3: Update the GitHub Actions workflow

**Files:**
- Modify: `.github/workflows/deploy_production.yml`

- [ ] **Step 1: Change release path variables to bare names**

The server script expects names, not `releases/`-prefixed paths.

```yaml
      - name: Compute release names
        run: |
          TIMESTAMP=$(date -u +%Y%m%d%H%M%S)
          echo "RELEASE=${TIMESTAMP}-${{ github.sha }}" >> "$GITHUB_ENV"
          echo "TEMP_RELEASE=.${TIMESTAMP}-${{ github.sha }}.${{ github.run_id }}.tmp" >> "$GITHUB_ENV"
```

- [ ] **Step 2: Replace the three remote steps and the rollback**

```yaml
      - name: Prepare remote release directory
        env:
          SSH_HOST: ${{ secrets.SSH_HOST }}
          SSH_USERNAME: ${{ secrets.SSH_USERNAME }}
        run: |
          ssh -i ~/.ssh/deploy_key "${SSH_USERNAME}@${SSH_HOST}" "weblog-release prepare $TEMP_RELEASE"

      - name: Upload built site
        env:
          SSH_HOST: ${{ secrets.SSH_HOST }}
          SSH_USERNAME: ${{ secrets.SSH_USERNAME }}
        run: |
          rsync -az --delete -e "ssh -i ~/.ssh/deploy_key" public/ "${SSH_USERNAME}@${SSH_HOST}:${TEMP_RELEASE}/"

      - name: Activate release
        id: activate
        env:
          SSH_HOST: ${{ secrets.SSH_HOST }}
          SSH_USERNAME: ${{ secrets.SSH_USERNAME }}
        run: |
          REMOTE="${SSH_USERNAME}@${SSH_HOST}"
          PREVIOUS=$(ssh -i ~/.ssh/deploy_key "$REMOTE" "weblog-release current")
          if [[ "$PREVIOUS" =~ ^releases/[0-9]{14}-[0-9a-f]{40}$ ]]; then
            echo "PREVIOUS_RELEASE=${PREVIOUS#releases/}" >> "$GITHUB_ENV"
          else
            echo "missing or invalid previous release; restore a baseline before deploying" >&2
            exit 1
          fi
          ssh -i ~/.ssh/deploy_key "$REMOTE" "weblog-release activate $TEMP_RELEASE $RELEASE"

      - name: Smoke test production
        id: smoke
        run: |
          curl -fsS --connect-timeout 10 --max-time 30 https://webcodr.io/ >/dev/null
          curl -fsS --connect-timeout 10 --max-time 30 https://webcodr.dev/ >/dev/null

      - name: Prune releases after successful smoke test
        env:
          SSH_HOST: ${{ secrets.SSH_HOST }}
          SSH_USERNAME: ${{ secrets.SSH_USERNAME }}
        run: |
          ssh -i ~/.ssh/deploy_key "${SSH_USERNAME}@${SSH_HOST}" "weblog-release prune $RELEASE $PREVIOUS_RELEASE"

      - name: Roll back to previous release
        if: ${{ failure() && (steps.activate.outcome == 'failure' || steps.smoke.outcome == 'failure') && env.PREVIOUS_RELEASE != '' }}
        env:
          SSH_HOST: ${{ secrets.SSH_HOST }}
          SSH_USERNAME: ${{ secrets.SSH_USERNAME }}
        run: |
          ssh -i ~/.ssh/deploy_key "${SSH_USERNAME}@${SSH_HOST}" "weblog-release rollback-if-current $RELEASE $PREVIOUS_RELEASE"
          curl -fsS --connect-timeout 10 --max-time 30 https://webcodr.io/ >/dev/null
          curl -fsS --connect-timeout 10 --max-time 30 https://webcodr.dev/ >/dev/null
```

Note the rsync destination is relative (`${TEMP_RELEASE}/`), which `rrsync` resolves inside `/srv/weblog/site/releases`.

Activation does no pruning and touches the directory before flipping `current`. Its only post-flip operations are verification/reporting; an SSH failure can still occur after the flip, so recovery handles both activation and smoke failures. `rollback-if-current` compares and flips under the release lock, leaving an unrelated current release alone. Pruning happens only after smoke success and protects the saved previous target even after a manual rollback to an old release. A pruning failure fails the job but does not revert healthy content. Network outages or cancelled jobs still require operator reconciliation of `current`; do not claim rollback succeeded unless the recovery command and checks succeeded.

The restored baseline is required before the first CI deploy. Keep runner smoke checks portable; the workstation's explicit IPv4/IPv6/HTTP/3 cutover checks in Task 6 are mandatory and must not be replaced by a runner that lacks IPv6 connectivity.

- [ ] **Step 3: Keep everything else**

`permissions: {}`, pinned actions, `concurrency`, the SSH key setup with `umask 077`, `known_hosts` from a secret, and the key cleanup step stay as they are.

- [ ] **Step 4: Commit on a branch, do not merge yet**

The workflow only works against the new server. Merge it in Task 8 as part of the cutover.

- [ ] **Step 5: Rehearse security and failure recovery before the outage**

Use a disposable Debian 13 host running the prepared infrastructure commit and the same pinned Caddy image. Exercise a copy of this workflow against a separate `rehearsal` GitHub environment and dedicated SSH secrets. In that test-only copy, replace every public Caddy hostname and every smoke/recovery/redirect/protocol-check URL with rehearsal-only hostnames whose A/AAAA records point to the disposable host. Obtain valid certificates for those test names so TLS validation stays enabled; never request production-domain certificates on the rehearsal host. Changing only SSH secrets is insufficient because the production workflow hardcodes its HTTPS URLs. Keep these substitutions and failure injection out of the production changes, and never overwrite the production secrets.

| Case | Required result |
| --- | --- |
| Deploy-key authentication | `id` fails through the dispatcher; `weblog-release current`, prepare, upload and activate succeed. |
| Malicious staging link | Upload a valid index and a link to `/etc/alpine-release` using rsync's `-a`. Inspect the receiver: the link is prefixed with `/rsyncd-munged/`. Activation refuses the release and leaves `current` unchanged. |
| Link injected after activation | Activate a link-free test release, then upload that same harmless probe link into the active release. Request `/probe` through Caddy: expect 404, never the container file's contents. Verify `/rsyncd-munged` is absent inside the container. Remove the probe through rsync before further tests. |
| Unsafe backup | Restoring a release containing a symlink fails validation before setting `current`. |
| Retention after manual rollback | Create A-E in increasing mtime order, roll back to A, activate F, and verify A survives. After successful smoke and `prune F A`, A still exists; `rollback-if-current F A` succeeds. |
| Activation failure before flip | Fail a rehearsal runner activation step before the remote activation command. Recovery leaves the baseline alone; no release is pruned. |
| Activation failure after flip | In the rehearsal workflow only, append `exit 1` immediately after a successful remote activation. The activation step fails, smoke is skipped, recovery runs and restores the saved baseline. This exercises the same recovery branch as a lost SSH response after a flip. |
| Smoke failure | Force only the rehearsal smoke step to fail. Recovery restores the baseline and verifies it over HTTPS; pruning is skipped. |
| Current changed before recovery | Set current to a third valid release, then call `rollback-if-current F A`. The third release stays current. |
| Cleanup failure | Make the rehearsal pruning step fail after a passing smoke test. The job fails visibly but the newly verified release stays active. |
| Host recovery | Reboot and verify fresh `ops` sudo, root SSH refusal, container health, firewall rules and external IPv4/IPv6/HTTP/3. |

Record the successful rehearsal commit and run URL before proceeding to the destructive rebuild. Add automated release-script regression coverage for argument rejection, symlink rejection, retention and conditional rollback when implementing Task 2; lint alone does not verify these behaviors.

### Task 4: Provision the Debian 13 host

**Files:**
- Create: `server/bootstrap.sh`
- Create: `server/daemon.json`
- Create: `server/nftables.conf`

- [ ] **Step 1: Snapshot and rebuild the existing VM (start of outage)**

In the Hetzner console for the existing server:

1. Create (or verify) a Cloud Firewall with inbound rules TCP 22, TCP 80, TCP 443, UDP 443, ICMP for both IPv4 and IPv6; outbound unrestricted. Restrict SSH sources only if both the operator and CI runners have permitted addresses; allowing only your workstation IP breaks GitHub-hosted deployments. Attach it before the outage and verify existing access.
2. Before the outage, identify the SSH key selected when this server was originally created and verify that you still have its private half. Hetzner rebuilds reinject that original provisioning key; registering a new project key does not select it for this server's rebuild. Configure the workstation's SSH identity accordingly. If the original key is unavailable, prepare and rehearse a Hetzner rescue/key-installation procedure first; do not begin the rebuild assuming the current host's manually added keys will survive.
3. Take a snapshot of the server. This is the rollback path; keep it until Task 8 is finished.
4. Server → Rebuild → Debian 13. The server keeps its IPv4, IPv6 and firewall. Wait for the console to report it as running (about 2 minutes).
5. Remove the stale host key locally: `ssh-keygen -R HOST` (and the IP if you connect by IP), then `ssh root@HOST` and accept the new fingerprint after comparing it with the one shown in the Hetzner console.

- [ ] **Step 2: Write `server/daemon.json`**

```json
{
  "userns-remap": "default",
  "features": { "containerd-snapshotter": false },
  "live-restore": true,
  "no-new-privileges": true,
  "icc": false,
  "userland-proxy": false,
  "ipv6": true,
  "fixed-cidr-v6": "fd00:d0c:1::/64",
  "log-driver": "json-file",
  "log-opts": { "max-size": "20m", "max-file": "5" }
}
```

Notes:
- `userns-remap: default` creates a `dockremap` user with a subuid range (usually starting at 100000). Container uid 1000 becomes host uid 101000.
- Docker 29 fresh installs default to the containerd image store, which Docker documents as incompatible with `userns-remap`. Explicitly select the legacy image store before creating workloads rather than relying on an automatic fallback. Verify the selected backend during rehearsal.
- `userland-proxy: false` publishes ports with iptables rules only, avoiding the `docker-proxy` process per port.
- `icc: false` is harmless with one container and good hygiene for later.
- `fixed-cidr-v6` gives the default bridge a ULA range so `enable_ipv6` networks work; published IPv6 ports are NATed from the host's public address.

- [ ] **Step 3: Write `server/nftables.conf`**

```
#!/usr/sbin/nft -f
flush ruleset

table inet filter {
  chain input {
    type filter hook input priority 0; policy drop;
    ct state established,related accept
    ct state invalid drop
    iif lo accept
    ip protocol icmp accept
    ip6 nexthdr icmpv6 accept
    tcp dport 22 ct state new accept
    tcp dport { 80, 443 } accept
    udp dport 443 accept
  }
  chain forward {
    type filter hook forward priority 0; policy accept;
  }
  chain output {
    type filter hook output priority 0; policy accept;
  }
}
```

`flush ruleset` clears Docker's iptables-nft tables too. At boot nftables must load before Docker; bootstrap explicitly restarts Docker after applying the firewall. Do not reload this file while Docker is running without immediately restarting Docker and rechecking public connectivity. Avoid a global SSH connection-rate bucket: unauthenticated Internet traffic could consume it and deny operator/CI access. SSH remains key-only with `MaxAuthTries` and cloud source restrictions where feasible.

- [ ] **Step 4: Write `server/bootstrap.sh`**

Prepare this file before the outage, then run it as root on the fresh VM. It can be rerun to apply the same configuration; the separately installed root-login disable file must be preserved on reruns.

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
ssh-keygen -l -f "${1:?usage: bootstrap.sh <ops-public-key-file>}" >/dev/null
OPS_KEY=$(cat "$1")

apt-get update
apt-get -y full-upgrade
apt-get -y install ca-certificates curl gnupg git rsync nftables unattended-upgrades apt-listchanges sudo util-linux

# --- Docker CE ---
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc
# shellcheck disable=SC1091
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian $(. /etc/os-release && echo "$VERSION_CODENAME") stable" > /etc/apt/sources.list.d/docker.list
apt-get update
apt-get -y install docker-ce docker-ce-cli containerd.io docker-compose-plugin
install -m 0644 "$SCRIPT_DIR/daemon.json" /etc/docker/daemon.json
dockerd --validate --config-file=/etc/docker/daemon.json
systemctl enable docker
systemctl restart docker

# --- users ---
id ops >/dev/null 2>&1 || adduser --disabled-password --comment "" ops
usermod -aG sudo,docker ops
printf 'ops ALL=(ALL:ALL) NOPASSWD: ALL\n' > /etc/sudoers.d/90-weblog-ops
chmod 440 /etc/sudoers.d/90-weblog-ops
visudo -cf /etc/sudoers
install -d -m 700 -o ops -g ops /home/ops/.ssh
printf '%s\n' "$OPS_KEY" > /home/ops/.ssh/authorized_keys
chown ops:ops /home/ops/.ssh/authorized_keys; chmod 600 /home/ops/.ssh/authorized_keys

id deploy >/dev/null 2>&1 || adduser --disabled-password --comment "" --shell /bin/dash deploy
usermod --shell /bin/dash deploy
install -d -m 755 -o deploy -g deploy /srv/weblog /srv/weblog/site /srv/weblog/site/releases
install -d -m 700 -o deploy -g deploy /home/deploy/.ssh

# --- release tooling ---
install -m 0755 "$SCRIPT_DIR/weblog-release" /usr/local/bin/weblog-release
install -m 0755 "$SCRIPT_DIR/weblog-deploy-shell" /usr/local/bin/weblog-deploy-shell

# --- sshd ---
cat > /etc/ssh/sshd_config.d/10-hardening.conf <<'EOF'
PermitRootLogin prohibit-password
PasswordAuthentication no
KbdInteractiveAuthentication no
PubkeyAuthentication yes
AllowUsers root ops deploy
X11Forwarding no
AllowAgentForwarding no
MaxAuthTries 3
LoginGraceTime 20
ClientAliveInterval 300
ClientAliveCountMax 2
EOF
cat > /etc/ssh/sshd_config.d/20-deploy.conf <<'EOF'
Match User deploy
    ForceCommand /usr/local/bin/weblog-deploy-shell
    AllowTcpForwarding no
    AllowAgentForwarding no
    X11Forwarding no
    PermitTTY no
EOF
sshd -t
systemctl reload ssh

# --- firewall ---
install -m 0755 "$SCRIPT_DIR/nftables.conf" /etc/nftables.conf
nft -c -f /etc/nftables.conf
systemctl enable nftables
systemctl restart nftables
systemctl restart docker   # re-create Docker's chains after the ruleset load

# --- automatic security updates ---
cat > /etc/apt/apt.conf.d/50unattended-upgrades <<'EOF'
Unattended-Upgrade::Origins-Pattern {
    "origin=Debian,codename=${distro_codename},label=Debian-Security";
    "origin=Debian,codename=${distro_codename}-security,label=Debian-Security";
    "origin=Docker,codename=${distro_codename}";
};
Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "true";
Unattended-Upgrade::Automatic-Reboot-Time "04:30";
EOF
cat > /etc/apt/apt.conf.d/20auto-upgrades <<'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::AutocleanInterval "7";
EOF
systemctl enable --now unattended-upgrades

# --- kernel hardening (light) ---
cat > /etc/sysctl.d/90-hardening.conf <<'EOF'
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.all.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0
net.ipv4.tcp_syncookies = 1
kernel.kptr_restrict = 2
kernel.dmesg_restrict = 1
kernel.unprivileged_bpf_disabled = 1
EOF
sysctl --system

echo "bootstrap complete"
```

Order of operations: upload the prepared `server/` directory to `/root/weblog-bootstrap/server/` before running bootstrap, as below. The script installs files relative to its own location, leaving `/opt/weblog` empty for a clean clone. The `Automatic-Reboot` setting is deliberate: `live-restore` covers compatible dockerd restarts, not host reboots. A kernel reboot at 04:30 causes downtime; the reboot rehearsal and Task 6 gate verify that the stack and firewall recover automatically.

- [ ] **Step 5: Run it**

From the workstation, using the tested infrastructure checkout:

```fish
ssh root@HOST 'mkdir -p /root/weblog-bootstrap/server'
scp -r server/. root@HOST:/root/weblog-bootstrap/server/
scp ~/.ssh/id_ed25519.pub root@HOST:/tmp/weblog-ops.pub
ssh root@HOST 'bash /root/weblog-bootstrap/server/bootstrap.sh /tmp/weblog-ops.pub'
```

Keep an interactive root session open in a separate terminal until verification is complete. From a second workstation terminal, confirm key-only admin access and noninteractive sudo before installing the root-login override:

```fish
ssh -o BatchMode=yes ops@HOST 'sudo -n true'
# Stop here if the preceding command fails. Do not disable root access.
```

Only after that succeeds, run from the workstation:

```fish
printf 'PermitRootLogin no\n' | ssh ops@HOST 'sudo -n tee /etc/ssh/sshd_config.d/00-disable-root-login.conf >/dev/null'
ssh ops@HOST 'sudo -n sshd -t && sudo -n systemctl reload ssh'
ssh ops@HOST 'sudo -n sshd -T -C user=root,host=localhost,addr=127.0.0.1' | string match -r '^permitrootlogin no$'
ssh -o BatchMode=yes -o ControlMaster=no -o ControlPath=none root@HOST true # expect authentication failure
ssh -o BatchMode=yes ops@HOST 'sudo -n true'
```

Do not close the retained root session until both the refusal and the fresh `ops` sudo check behave as expected. Test Hetzner's rescue/console access before the outage; a passwordless root account does not provide a usable console password login by itself. The snapshot is the full rollback path.

- [ ] **Step 6: Commit**

Run on the workstation before the outage, together with the rest of the prepared infrastructure changes:

```fish
shellcheck server/bootstrap.sh server/weblog-release server/weblog-deploy-shell
git add server/
git commit -m "ops: add debian 13 bootstrap, docker daemon config and nftables ruleset"
```

### Task 5: Install the compose stack

- [ ] **Step 1: Clone the repo as `ops`**

On the server in Bash as `ops`. Replace `TESTED_INFRA_COMMIT` with the recorded, pushed infrastructure commit from the rehearsal, not the old `main` or the unmerged workflow branch:

```bash
sudo install -d -o ops -g ops /opt/weblog
git clone https://github.com/webcodr/weblog.git /opt/weblog
cd /opt/weblog
git checkout --detach TESTED_INFRA_COMMIT
printf 'WEBLOG_SITE_DIR=/srv/weblog/site\n' > .env
```

`/opt/weblog` is a plain checkout, read by `ops` only. The container never sees it; it only receives the Caddyfile and the site directory as mounts.

- [ ] **Step 2: Create the deploy key**

On your workstation, generate a key dedicated to CI and never used anywhere else:

```fish
ssh-keygen -t ed25519 -f ~/.ssh/weblog_deploy -C "github-actions weblog deploy" -N ""
```

From the workstation, stream only the public half into the server-side installation command. No private key is copied to the server:

```fish
set -l deploy_public_key (string collect < ~/.ssh/weblog_deploy.pub)
printf 'restrict,command="/usr/local/bin/weblog-deploy-shell" %s\n' "$deploy_public_key" | ssh ops@HOST 'sudo -n install -m 600 -o deploy -g deploy /dev/stdin /home/deploy/.ssh/authorized_keys'
```

- [ ] **Step 3: Verify the restriction**

From the workstation:

```fish
ssh -o BatchMode=yes -o IdentitiesOnly=yes -i ~/.ssh/weblog_deploy deploy@HOST id # expect: "command not permitted", exit 126
ssh -o BatchMode=yes -o IdentitiesOnly=yes -i ~/.ssh/weblog_deploy deploy@HOST weblog-release current # expect: no output, exit 0
```

Both checks are required: an authentication failure or `nologin` rejection is not a passing restriction test. The positive check proves that authentication and the dispatcher actually work.

### Task 6: First start of Caddy

- [ ] **Step 1: Create volumes and fix ownership**

On the server in Bash as `ops`:

```bash
cd /opt/weblog
docker compose create
MAPPED_UID=$(( $(awk -F: '/^dockremap:/{print $2}' /etc/subuid) + 1000 ))
MAPPED_GID=$(( $(awk -F: '/^dockremap:/{print $2}' /etc/subgid) + 1000 ))
for v in weblog_caddy_data weblog_caddy_config; do
  sudo chown "$MAPPED_UID:$MAPPED_GID" "$(docker volume inspect -f '{{.Mountpoint}}' "$v")"
done
```

- [ ] **Step 2: Restore the certificate store and the last release**

From the workstation, upload the Task 0 backups. The deploy shell is restricted, so use `ops`:

```fish
ssh ops@HOST 'mkdir -p -m 700 /home/ops/weblog-restore && chmod 700 /home/ops/weblog-restore'
rsync -az ~/weblog-migration/caddy_data/ ops@HOST:/home/ops/weblog-restore/caddy_data/
rsync -az ~/weblog-migration/release/ ops@HOST:/home/ops/weblog-restore/release/
scp ~/weblog-migration/release-name ops@HOST:/home/ops/weblog-restore/release-name
```

On the server in Bash as `ops`. Stop immediately on any validation or restore failure; do not start Caddy with a partial restore:

```bash
set -euo pipefail
MAPPED_UID=$(( $(awk -F: '/^dockremap:/{print $2}' /etc/subuid) + 1000 ))
MAPPED_GID=$(( $(awk -F: '/^dockremap:/{print $2}' /etc/subgid) + 1000 ))
DATA_MP=$(docker volume inspect -f '{{.Mountpoint}}' weblog_caddy_data)
sudo rsync -a /home/ops/weblog-restore/caddy_data/ "$DATA_MP"/
sudo chown -R "$MAPPED_UID:$MAPPED_GID" "$DATA_MP"

REL=$(cat /home/ops/weblog-restore/release-name)
[[ "$REL" =~ ^[0-9]{14}-[0-9a-f]{40}$ ]]
test -z "$(find /home/ops/weblog-restore/release -type l -print -quit)"
sudo install -d -o deploy -g deploy "/srv/weblog/site/releases/$REL"
sudo rsync -a --chown=deploy:deploy /home/ops/weblog-restore/release/ "/srv/weblog/site/releases/$REL/"
sudo -u deploy weblog-release rollback "$REL"
sudo rm -rf /home/ops/weblog-restore
```

The baseline passes the same name, index and symlink checks as later releases. Do not bypass a rejected symlink by manually setting `current`; rebuild the backup as regular files instead. CI later retains the five newest releases plus the current and saved previous targets if older.

- [ ] **Step 3: Start and check**

On the server in Bash as `ops`:

```bash
docker compose up -d --wait --wait-timeout 120
docker compose logs --tail 100 caddy # expect: no "permission denied", certificates load from restored storage
docker compose exec caddy id      # expect: uid=1000
ps -o user,pid,cmd -C caddy       # expect: host user 101000 (or your mapped uid), not root
docker compose exec caddy test ! -e /rsyncd-munged
curl -fsS --connect-timeout 10 --max-time 30 --resolve webcodr.io:443:127.0.0.1 https://webcodr.io/ -o /dev/null -w '%{http_code}\n'
```

Expect a healthy container and 200 with normal certificate validation. Investigate unexpected issuance by checking the restored path, ownership, certificate expiry and renewal schedule; renewal activity alone does not prove a bad restore. This local check does not end the outage.

- [ ] **Step 4: Verify public TLS, both address families, and HTTP/3**

From the workstation in fish, on a connection with working public IPv4 and IPv6. Confirm `curl --version` lists `HTTP3` before running the HTTP/3 checks; use an HTTP/3-capable curl and another dual-stack connection if necessary, rather than allowing fallback or skipping a family.

```fish
curl --version
for family in -4 -6
    for domain in webcodr.io webcodr.dev
        curl $family -fsS --connect-timeout 10 --max-time 30 "https://$domain/" -o /dev/null -w '%{http_code}\n'
        curl $family --http3-only -fsS --connect-timeout 10 --max-time 30 "https://$domain/" -o /dev/null -w '%{http_version} %{http_code}\n'
    end
    for domain in www.webcodr.io www.webcodr.dev
        curl $family -fsSIL --connect-timeout 10 --max-time 30 "https://$domain/"
    end
end
```

Every command must succeed: apex requests must return 200, HTTP/3 must report version 3 with 200, and `www` must redirect to its matching apex with a final 200. These are manual gates: the loop's final exit status alone does not prove every request passed. Do not use `-k`; an `alt-svc` header is only an advertisement, not proof that UDP/443 works.

- [ ] **Step 5: Reboot and repeat the public checks**

From the workstation:

```fish
ssh ops@HOST 'sudo -n systemctl reboot'
# After the host returns, these must succeed without manually starting Docker or Caddy:
ssh -o ConnectTimeout=10 ops@HOST 'sudo -n true && systemctl is-active docker nftables'
ssh ops@HOST 'cd /opt/weblog && docker compose ps && sudo -n nft list ruleset'
```

Wait for the container healthcheck to report healthy, then rerun **every Step 4 request**. Verify root SSH is still refused, the remapped UID remains correct, and the input-drop firewall and Docker publishing rules survived. Only now is the outage over. If these checks fail, keep the snapshot and backups, repair within the agreed window or rebuild from the snapshot; verify the old site's TLS and host key when rolling back.

### Task 7: Rotate the GitHub deploy secrets

- [ ] **Step 1: Update the `production` environment secrets**

`SSH_USERNAME=deploy`, `SSH_KEY` is the private half of `weblog_deploy` from Task 5, `SSH_KNOWN_HOSTS` is the output of `ssh-keyscan -t ed25519 HOST` from the rebuilt server (compare against the fingerprint you accepted in Task 4). `SSH_HOST` is unchanged.

- [ ] **Step 2: Delete the old deploy key material**

The old private key in the previous `SSH_KEY` secret is now overwritten. The old public key lived only on the wiped disk and in the snapshot. Delete `~/weblog-migration/caddy_data` on your workstation now, and the whole `~/weblog-migration` directory once Task 8 passes.

### Task 8: First deploy through the new path

- [ ] **Step 1: Merge the tested infrastructure and Task 3 workflow branches** into `main`, coordinating the workflow/secrets transition so no old-protocol deployment is mistaken for a successful new deploy. The final push triggers the new workflow. On the server as `ops`, attach the infrastructure checkout to `main` after both merges:

```bash
cd /opt/weblog
git fetch origin
git switch main
git pull --ff-only
docker compose up -d --wait --wait-timeout 120
```

- [ ] **Step 2: Watch the run.** `prepare`, rsync, `activate`, smoke and `prune` must succeed. Confirm from the workstation:

```fish
ssh ops@HOST 'ls -la /srv/weblog/site/releases; readlink /srv/weblog/site/current'
```

- [ ] **Step 3: Confirm production rollback with the deploy key** while CI is idle. Failure-path injection belongs in the mandatory rehearsal, not production. From the workstation, replace the two names below with actual retained release names:

```fish
set -l previous_release PREVIOUS_RELEASE_NAME
set -l newest_release NEWEST_RELEASE_NAME
ssh -i ~/.ssh/weblog_deploy deploy@HOST "weblog-release rollback $previous_release"
curl -fsS --connect-timeout 10 --max-time 30 https://webcodr.io/ -o /dev/null -w '%{http_code}\n'
curl -fsS --connect-timeout 10 --max-time 30 https://webcodr.dev/ -o /dev/null -w '%{http_code}\n'
ssh -i ~/.ssh/weblog_deploy deploy@HOST "weblog-release rollback $newest_release"
curl -fsS --connect-timeout 10 --max-time 30 https://webcodr.io/ -o /dev/null -w '%{http_code}\n'
curl -fsS --connect-timeout 10 --max-time 30 https://webcodr.dev/ -o /dev/null -w '%{http_code}\n'
```

- [ ] **Step 4: Verify headers and HTTP/3**

From the workstation:

```fish
curl -fsSI --connect-timeout 10 --max-time 30 https://webcodr.io/ | string match -ri '^(strict-transport-security|content-security-policy|alt-svc|server):.*'
```

Expect HSTS, CSP, an `alt-svc: h3=` header, and no `server` header. Repeat Task 6 Step 4's `--http3-only` checks to prove protocol connectivity; the header alone is insufficient.

- [ ] **Step 5: Delete the snapshot** after a few days of normal operation, and remove `~/weblog-migration` from your workstation.

### Task 9: Documentation

**Files:**
- Modify: `AGENTS.md`

- [ ] **Step 1: Update the Deployment section**

Replace the references to `~/projects/weblog/site` with `/srv/weblog/site`, document key-only `ops` with explicit passwordless sudo and `deploy` with a dash login shell plus forced commands, and state that uploads use `rrsync -wo -munge`. Document conditional rollback on activation/smoke failures, post-smoke pruning that protects the previous release, the loopback health endpoint, and the tested recovery gates. The compose stack lives at `/opt/weblog` on `main` after Task 8; infra changes are applied with `git pull --ff-only && docker compose up -d --wait` in the server's Bash session as `ops`. Remove the old one-time path-migration paragraph. Keep workstation examples in fish.

- [ ] **Step 2: Commit**

```fish
git add AGENTS.md
git commit -m "docs: describe the rebuilt production host and restricted deploy path"
```

---

## Post-Rebuild Checklist

- `docker compose exec caddy id` shows uid 1000, and the host process runs as the remapped uid.
- `docker compose exec caddy touch /x` fails with a read-only filesystem error.
- `ssh deploy@HOST id` is refused; `ssh deploy@HOST weblog-release current` works.
- `ssh root@HOST` is refused; `ssh ops@HOST` works with key only.
- `ssh ops@HOST 'sudo -n true'` succeeds in a fresh session, including after reboot.
- Container health is healthy via the loopback index endpoint; 8080 is not published.
- Uploaded links are munged, activation/restoration reject links, and `/rsyncd-munged` does not exist inside Caddy.
- Rehearsal proves activation-failure and smoke-failure rollback, protection of an old previous release, and no rollback on pruning failure.
- Public TLS passes over IPv4 and IPv6 and `--http3-only` reports HTTP/3, before and after reboot.
- `nft list ruleset` shows the input policy `drop` with 22, 80, 443 open.
- `systemctl status unattended-upgrades` is active and `/var/log/unattended-upgrades/` fills over the following week.
- Dependabot still opens PRs for the Caddy image digest; merging one and running `git pull --ff-only && docker compose up -d --wait` as `ops` recreates the container.

## Deliberately Not Done

- **Rootless Docker.** See Decisions. User-namespace remapping covers the main risk with less networking friction.
- **fail2ban.** SSH is key-only with `MaxAuthTries 3`. Brute-force noise in the logs is not a risk worth another daemon; a global connection-rate bucket would also let that noise block legitimate admin and CI connections.
- **Caddy access logs.** Not enabled today, not needed for a blog, and enabling them would add a personal-data retention question. Leave off.
- **AppArmor profile for Caddy.** Debian ships AppArmor enabled and Docker applies its default `docker-default` profile automatically. A custom profile adds maintenance for marginal gain on a read-only, non-root, capability-less container.

# Server Rebuild and Container Hardening Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. Tasks 1 to 3 are repo changes and can be done by an agent. Tasks 4 to 8 run on the rebuilt server over SSH and are done by the operator, with an agent preparing the scripts.

**Goal:** Rebuild the production host from scratch on Debian 13 (Trixie) with a least-privilege layout: an unprivileged container runtime, a Caddy container that is non-root, read-only and resource-limited, a deploy identity that can only upload releases and flip a symlink, and automatic security updates.

**Architecture:** The existing Hetzner VM (2 vCPU, 2 GB RAM), reinstalled in place via the Hetzner "Rebuild" action so it keeps its IPv4 and IPv6 addresses and its cloud firewall attachment. Three Unix identities: `root` (console only), `ops` (admin, sudo, owns the compose stack at `/opt/weblog`), and `deploy` (no shell access beyond a forced command, owns `/srv/weblog/site`). Docker CE runs with user-namespace remapping so container root is an unprivileged host uid. Caddy runs as uid 1000 inside the container, on a read-only root filesystem, with named volumes for certificates. GitHub Actions rsyncs a release into `/srv/weblog/site/releases/` through `rrsync` and calls a whitelisted `weblog-release` command to activate or roll back.

**Tech Stack:** Debian 13 Trixie, Docker CE (docker.com apt repo, since Debian's own `docker.io` package lags), Docker Compose v2 plugin, Caddy 2.11 (alpine image, digest pinned), OpenSSH with forced commands, `rrsync`, nftables, `unattended-upgrades`, Hetzner Cloud Firewall.

---

## Decisions

- **Debian 13 over Ubuntu 24.04.** Agreed. Debian's security team ships fixes for all of `main` with public advisories; Ubuntu's coverage for `universe` requires Pro. For a host that only runs SSH, Docker and Caddy, Debian is the smaller and better-maintained surface. Hetzner offers a Debian 13 image directly.
- **Rootful Docker with `userns-remap` over rootless Docker.** Rootless Docker adds slirp4netns/pasta networking, complicates IPv6 and UDP (HTTP/3) port publishing, and gains little here because a single trusted image is run. User-namespace remapping delivers the core property (container root is not host root) with mature networking. Revisit rootless only if more services are added.
- **Named volumes for `/data` and `/config`.** They hold the ACME account key and TLS private keys. The current `./../../caddy_data` relative path depends on the working-directory layout and silently creates an empty directory if it drifts, which triggers Let's Encrypt re-issuance and rate limits.
- **Compose stack and site data live outside `$HOME`.** `/opt/weblog` for the git checkout (compose, Caddyfile), `/srv/weblog/site` for releases. Neither depends on which user runs `docker compose`.
- **Forced SSH command for deploys.** A leaked `SSH_KEY` secret today means a full shell on the host. After this plan it means the ability to upload files into `releases/` and flip a symlink between validated release names, nothing else.
- **In-place rebuild instead of a parallel VM.** New instances of this class are currently unavailable or markedly more expensive, so the existing server is reinstalled. This costs a planned outage (target under 30 minutes) but avoids any DNS change: the IP addresses stay, and the restored Caddy storage means no new certificate issuance at cutover. A snapshot taken right before the rebuild is the rollback path.
- **Firewall in two layers.** Hetzner Cloud Firewall in front of the VM (allows 22, 80, 443 TCP and 443 UDP, ICMP) and host nftables. Docker's published ports bypass host filtering via the `DOCKER-USER` chain semantics, which is acceptable because only 80/443 are published, but the cloud firewall is the authoritative layer.

## File Structure

- Modify `docker-compose.yml`: non-root user, read-only rootfs, tmpfs, limits, log rotation, named volumes, env-driven site path.
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

Before the outage window, Task 0 copies off Caddy's ACME storage and the currently served release, and Tasks 1 to 3 land in the repo on a branch. Optional but recommended: rehearse `bootstrap.sh` for an hour on any small Hetzner type that is available (an ARM CAX11 is fine, the script is architecture-agnostic), then delete it. That turns the real run into a replay.

During the window: snapshot, rebuild with the Debian 13 image, run bootstrap, restore, start Caddy, verify with curl. Because the IP does not change, Caddy serves the restored certificates immediately and DNS needs no attention.

After the window: rotate the GitHub `production` secrets to the new deploy identity, merge the workflow branch, run a deploy, decommission the snapshot after a few days.

---

### Task 0: Back up state from the current server (before the outage)

Run from your workstation against the current host. Nothing here changes the running server.

- [x] **Step 1: Copy Caddy's ACME storage**

The compose file mounts `~/caddy_data` at `/data`. It holds the ACME account key and the four certificates. Restoring it means zero certificate issuance at cutover and no Let's Encrypt rate-limit exposure.

```bash
mkdir -p ~/weblog-migration
rsync -az --rsync-path="sudo rsync" OLD_USER@HOST:~/caddy_data/ ~/weblog-migration/caddy_data/
chmod -R go-rwx ~/weblog-migration/caddy_data
```

Use `sudo rsync` on the remote side if the files are owned by root (Caddy runs as root in the old setup). Treat this directory like a private key: delete it after the migration.

- [x] **Step 2: Copy the currently served release**

```bash
REL=$(ssh OLD_USER@HOST 'readlink ~/projects/weblog/site/current')
echo "$REL"    # expect releases/<timestamp>-<sha>
rsync -az OLD_USER@HOST:~/projects/weblog/site/"$REL"/ ~/weblog-migration/release/
echo "${REL#releases/}" > ~/weblog-migration/release-name
```

Restoring this instead of a placeholder means the real site is back the moment Caddy starts, and CI does not have to run before the outage ends.

- [x] **Step 3: Note what else lives on the server**

```bash
ssh OLD_USER@HOST 'ls ~ /opt /srv /etc/cron.d 2>/dev/null; crontab -l 2>/dev/null; docker ps -a'
```

Anything beyond the weblog stack must be either backed up now or consciously abandoned. The rebuild wipes the disk.

- [x] **Step 4: Record the current SSH host key fingerprint**

```bash
ssh-keyscan -t ed25519 HOST > ~/weblog-migration/old_known_hosts
```

The rebuild generates new host keys. Your own `~/.ssh/known_hosts` entry and the `SSH_KNOWN_HOSTS` GitHub secret both need replacing afterwards (Task 7).

---

### Task 1: Harden `docker-compose.yml`

**Files:**
- Modify: `docker-compose.yml`
- Create: `.env.example`
- Modify: `.gitignore`

- [x] **Step 1: Replace the compose file**

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
      test: ["CMD", "wget", "-q", "--spider", "http://127.0.0.1/"]
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
- The healthcheck hits port 80, which Caddy answers with a redirect to HTTPS (a 308 is a success for `wget --spider`).
- `mem_limit: 384m` leaves headroom on a 2 GB host for the kernel, sshd, dockerd and page cache. Caddy for a static site idles at ~30 MB.
- Named volumes are created owned by root. Task 6 fixes ownership once, after the first `docker compose up`.

- [x] **Step 2: Add `.env.example`**

```
# Absolute path of the directory containing releases/ and the current symlink.
WEBLOG_SITE_DIR=/srv/weblog/site
```

- [x] **Step 3: Add `.env` to `.gitignore`**

- [x] **Step 4: Validate**

```bash
docker compose config
```

Expected: exit code 0, volume source resolves to `./site` locally and to `/srv/weblog/site` when `.env` is present.

- [x] **Step 5: Commit**

```bash
git add docker-compose.yml .env.example .gitignore
git commit -m "build: run caddy non-root, read-only and resource-limited"
```

### Task 2: Server-side deploy scripts

**Files:**
- Create: `server/weblog-release`
- Create: `server/weblog-deploy-shell`

- [x] **Step 1: Write `server/weblog-release`**

This script is the only thing the deploy key can execute besides rsync. It validates every argument against a strict pattern before touching the filesystem.

```bash
#!/usr/bin/env bash
# weblog-release: manage releases in /srv/weblog/site
# Usage:
#   weblog-release prepare  <tmp-name>
#   weblog-release activate <tmp-name> <release-name>
#   weblog-release rollback <release-name>
#   weblog-release current
set -euo pipefail

SITE_DIR=/srv/weblog/site
KEEP=5
RELEASE_RE='^[0-9]{14}-[0-9a-f]{40}$'
TMP_RE='^\.[0-9]{14}-[0-9a-f]{40}\.[0-9]+\.tmp$'

die() { echo "weblog-release: $*" >&2; exit 1; }
check() { [[ "$2" =~ $1 ]] || die "invalid name: $2"; }

cd "$SITE_DIR"
mkdir -p releases

flip() {
  local target=$1
  test -f "releases/$target/index.html" || die "releases/$target has no index.html"
  ln -sfn "releases/$target" current-new
  mv -Tf current-new current
  [ "$(readlink current)" = "releases/$target" ] || die "symlink flip failed"
}

case "${1:-}" in
  prepare)
    check "$TMP_RE" "${2:-}"
    find releases -mindepth 1 -maxdepth 1 -name '.*.tmp' -exec rm -rf {} +
    mkdir -p "releases/$2"
    ;;
  activate)
    check "$TMP_RE" "${2:-}"
    check "$RELEASE_RE" "${3:-}"
    test -f "releases/$2/index.html" || die "upload incomplete"
    if [ -e "releases/$3" ]; then
      rm -rf "releases/$2"
    else
      mv "releases/$2" "releases/$3"
    fi
    flip "$3"
    touch "releases/$3"
    find releases -mindepth 1 -maxdepth 1 -type d -not -name '.*' -printf '%T@ %p\n' | sort -rn | tail -n +"$((KEEP + 1))" | cut -d' ' -f2- | xargs -r rm -rf
    echo "activated $3"
    ;;
  rollback)
    check "$RELEASE_RE" "${2:-}"
    flip "$2"
    echo "rolled back to $2"
    ;;
  current)
    readlink current 2>/dev/null || true
    ;;
  *)
    die "unknown command: ${1:-}"
    ;;
esac
```

- [x] **Step 2: Write `server/weblog-deploy-shell`**

Installed as the forced command for the deploy key. It allows exactly two things: an rsync server confined to `releases/`, and `weblog-release` subcommands.

```bash
#!/usr/bin/env bash
set -euo pipefail
cmd="${SSH_ORIGINAL_COMMAND:-}"
case "$cmd" in
  "rsync --server "*)
    exec /usr/bin/rrsync -wo /srv/weblog/site/releases
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
- `rrsync -wo` means write-only: the key can upload into `releases/` but never read anything back. The `-ro`/`-wo` options exist in rsync 3.2.4 and later; Trixie ships 3.4.x.
- Word-splitting the subcommand is safe because `weblog-release` validates every argument against a fixed regex before use.

- [x] **Step 3: Lint**

```bash
shellcheck server/weblog-release server/weblog-deploy-shell
```

- [x] **Step 4: Commit**

```bash
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
          case "$PREVIOUS" in
            releases/*) echo "PREVIOUS_RELEASE=${PREVIOUS#releases/}" >> "$GITHUB_ENV" ;;
            *) echo "no previous release to roll back to" ;;
          esac
          ssh -i ~/.ssh/deploy_key "$REMOTE" "weblog-release activate $TEMP_RELEASE $RELEASE"

      - name: Smoke test production
        id: smoke
        run: |
          curl -fsS https://webcodr.io/ >/dev/null
          curl -fsS https://webcodr.dev/ >/dev/null

      - name: Roll back to previous release
        if: ${{ failure() && steps.smoke.outcome == 'failure' && env.PREVIOUS_RELEASE != '' }}
        env:
          SSH_HOST: ${{ secrets.SSH_HOST }}
          SSH_USERNAME: ${{ secrets.SSH_USERNAME }}
        run: |
          ssh -i ~/.ssh/deploy_key "${SSH_USERNAME}@${SSH_HOST}" "weblog-release rollback $PREVIOUS_RELEASE"
          curl -fsS https://webcodr.io/ >/dev/null
          curl -fsS https://webcodr.dev/ >/dev/null
```

Note the rsync destination is relative (`${TEMP_RELEASE}/`), which `rrsync` resolves inside `/srv/weblog/site/releases`.

- [ ] **Step 3: Keep everything else**

`permissions: {}`, pinned actions, `concurrency`, the SSH key setup with `umask 077`, `known_hosts` from a secret, and the key cleanup step stay as they are.

- [ ] **Step 4: Commit on a branch, do not merge yet**

The workflow only works against the new server. Merge it in Task 8 as part of the cutover.

### Task 4: Provision the Debian 13 host

**Files:**
- Create: `server/bootstrap.sh`
- Create: `server/daemon.json`
- Create: `server/nftables.conf`

- [ ] **Step 1: Snapshot and rebuild the existing VM (start of outage)**

In the Hetzner console for the existing server:

1. Create (or verify) a Cloud Firewall with inbound rules TCP 22 (restrict to your IP ranges if stable, else any), TCP 80, TCP 443, UDP 443, ICMP; outbound unrestricted. Attach it to the server. This can be done before the outage and does not affect the running site.
2. Make sure your SSH public key is registered in the Hetzner project, so the rebuilt image comes up with it in root's `authorized_keys` and no root password.
3. Take a snapshot of the server. This is the rollback path; keep it until Task 8 is finished.
4. Server → Rebuild → Debian 13. The server keeps its IPv4, IPv6 and firewall. Wait for the console to report it as running (about 2 minutes).
5. Remove the stale host key locally: `ssh-keygen -R HOST` (and the IP if you connect by IP), then `ssh root@HOST` and accept the new fingerprint after comparing it with the one shown in the Hetzner console.

- [ ] **Step 2: Write `server/daemon.json`**

```json
{
  "userns-remap": "default",
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
    tcp dport 22 ct state new limit rate 10/minute accept
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

Docker installs its own iptables-nft rules in separate tables; this file does not flush them because `flush ruleset` runs only at boot before dockerd starts, and dockerd re-creates its chains. Do not run `nft -f` manually while Docker is up without restarting Docker afterwards.

- [ ] **Step 4: Write `server/bootstrap.sh`**

Run once as root on the fresh VM. Idempotent.

```bash
#!/usr/bin/env bash
set -euo pipefail

OPS_KEY="${OPS_KEY:?export OPS_KEY='ssh-ed25519 ... your admin public key'}"

apt-get update
apt-get -y full-upgrade
apt-get -y install ca-certificates curl gnupg git rsync nftables unattended-upgrades apt-listchanges sudo

# --- Docker CE ---
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc
# shellcheck disable=SC1091
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian $(. /etc/os-release && echo "$VERSION_CODENAME") stable" > /etc/apt/sources.list.d/docker.list
apt-get update
apt-get -y install docker-ce docker-ce-cli containerd.io docker-compose-plugin
install -m 0644 /opt/weblog/server/daemon.json /etc/docker/daemon.json
systemctl enable docker
systemctl restart docker

# --- users ---
id ops >/dev/null 2>&1 || adduser --disabled-password --gecos "" ops
usermod -aG sudo,docker ops
install -d -m 700 -o ops -g ops /home/ops/.ssh
printf '%s\n' "$OPS_KEY" > /home/ops/.ssh/authorized_keys
chown ops:ops /home/ops/.ssh/authorized_keys; chmod 600 /home/ops/.ssh/authorized_keys

id deploy >/dev/null 2>&1 || adduser --disabled-password --gecos "" --shell /usr/sbin/nologin deploy
install -d -m 755 -o deploy -g deploy /srv/weblog /srv/weblog/site /srv/weblog/site/releases
install -d -m 700 -o deploy -g deploy /home/deploy/.ssh

# --- release tooling ---
install -m 0755 /opt/weblog/server/weblog-release /usr/local/bin/weblog-release
install -m 0755 /opt/weblog/server/weblog-deploy-shell /usr/local/bin/weblog-deploy-shell

# --- sshd ---
cat > /etc/ssh/sshd_config.d/10-hardening.conf <<'EOF'
PermitRootLogin no
PasswordAuthentication no
KbdInteractiveAuthentication no
PubkeyAuthentication yes
AllowUsers ops deploy
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
sshd -t && systemctl reload ssh

# --- firewall ---
install -m 0755 /opt/weblog/server/nftables.conf /etc/nftables.conf
nft -c -f /etc/nftables.conf   # syntax check before the ruleset goes live
systemctl enable --now nftables
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

Order of operations: the script installs from `/opt/weblog/server/`, so clone the repo first (Task 5, Step 1) or scp the `server/` directory to `/opt/weblog/server/` before running it. The `Automatic-Reboot` setting is deliberate: with `live-restore: true`, Caddy keeps running through a dockerd restart, and a kernel reboot at 04:30 costs about a minute of downtime for a static blog, which is a fair price for not leaving a vulnerable kernel running.

- [ ] **Step 5: Run it**

```bash
# from your workstation
scp -r server root@HOST:/tmp/server
ssh root@HOST 'mkdir -p /opt/weblog && mv /tmp/server /opt/weblog/server'
ssh root@HOST "OPS_KEY='$(cat ~/.ssh/id_ed25519.pub)' bash /opt/weblog/server/bootstrap.sh"
```

Then confirm `ssh ops@HOST sudo -v` works before closing the root session. Root login is disabled afterwards; the Hetzner console remains the break-glass path, and the snapshot from Task 4 is the full rollback.

- [ ] **Step 6: Commit**

```bash
git add server/
git commit -m "ops: add debian 13 bootstrap, docker daemon config and nftables ruleset"
```

### Task 5: Install the compose stack

- [ ] **Step 1: Clone the repo as `ops`**

```bash
sudo chown -R ops:ops /opt/weblog
cd /opt/weblog && git init -q && git remote add origin https://github.com/webcodr/weblog.git
git fetch origin && git checkout -f main
printf 'WEBLOG_SITE_DIR=/srv/weblog/site\n' > .env
```

`/opt/weblog` is a plain checkout, read by `ops` only. The container never sees it; it only receives the Caddyfile and the site directory as mounts.

- [ ] **Step 2: Create the deploy key**

On your workstation, generate a key dedicated to CI and never used anywhere else:

```bash
ssh-keygen -t ed25519 -f ~/.ssh/weblog_deploy -C "github-actions weblog deploy" -N ""
```

On the server, install the public half with the `restrict` option (belt and braces alongside the sshd `Match` block):

```bash
sudo install -m 600 -o deploy -g deploy /dev/stdin /home/deploy/.ssh/authorized_keys <<EOF
restrict,command="/usr/local/bin/weblog-deploy-shell" $(cat ~/.ssh/weblog_deploy.pub)
EOF
```

- [ ] **Step 3: Verify the restriction**

```bash
ssh -i ~/.ssh/weblog_deploy deploy@HOST id            # expect: "command not permitted"
ssh -i ~/.ssh/weblog_deploy deploy@HOST weblog-release current   # expect: empty line, exit 0
```

### Task 6: First start of Caddy

- [ ] **Step 1: Create volumes and fix ownership**

```bash
cd /opt/weblog
docker compose create
MAPPED_UID=$(( $(awk -F: '/^dockremap:/{print $2}' /etc/subuid) + 1000 ))
for v in weblog_caddy_data weblog_caddy_config; do
  sudo chown "$MAPPED_UID:$MAPPED_UID" "$(docker volume inspect -f '{{.Mountpoint}}' $v)"
done
```

- [ ] **Step 2: Restore the certificate store and the last release**

From the workstation, upload the Task 0 backups. The deploy shell is restricted, so use `ops`:

```bash
rsync -az ~/weblog-migration/caddy_data/ ops@HOST:/tmp/caddy_data/
rsync -az ~/weblog-migration/release/ ops@HOST:/tmp/release/
scp ~/weblog-migration/release-name ops@HOST:/tmp/release-name
```

On the server as `ops`:

```bash
MAPPED_UID=$(( $(awk -F: '/^dockremap:/{print $2}' /etc/subuid) + 1000 ))
DATA_MP=$(docker volume inspect -f '{{.Mountpoint}}' weblog_caddy_data)
sudo rsync -a /tmp/caddy_data/ "$DATA_MP"/
sudo chown -R "$MAPPED_UID:$MAPPED_UID" "$DATA_MP"
sudo rm -rf /tmp/caddy_data

REL=$(cat /tmp/release-name)
sudo install -d -o deploy -g deploy "/srv/weblog/site/releases/$REL"
sudo rsync -a --chown=deploy:deploy /tmp/release/ "/srv/weblog/site/releases/$REL/"
sudo -u deploy ln -sfn "releases/$REL" /srv/weblog/site/current
sudo rm -rf /tmp/release /tmp/release-name
```

The `weblog-release` script keeps the five newest releases and treats this restored one like any other.

- [ ] **Step 3: Start and check**

```bash
docker compose up -d
docker compose logs -f caddy      # expect: no "permission denied", certificates load from the restored store, no ACME issuance expected
docker compose exec caddy id      # expect: uid=1000
ps -o user,pid,cmd -C caddy       # expect: host user 101000 (or your mapped uid), not root
curl -sk --resolve webcodr.io:443:127.0.0.1 https://webcodr.io/ -o /dev/null -w '%{http_code}\n'
```

With the restored storage, the last command returns 200 immediately and the Caddy log shows no ACME activity beyond loading the existing certificates. If it does start issuing, the restore landed in the wrong path or with the wrong owner; check `ls -la $DATA_MP/caddy/certificates`. From this point the site is back online and the outage is over. Everything below can happen at leisure.

### Task 7: Rotate the GitHub deploy secrets

- [ ] **Step 1: Update the `production` environment secrets**

`SSH_USERNAME=deploy`, `SSH_KEY` is the private half of `weblog_deploy` from Task 5, `SSH_KNOWN_HOSTS` is the output of `ssh-keyscan -t ed25519 HOST` from the rebuilt server (compare against the fingerprint you accepted in Task 4). `SSH_HOST` is unchanged.

- [ ] **Step 2: Delete the old deploy key material**

The old private key in the previous `SSH_KEY` secret is now overwritten. The old public key lived only on the wiped disk and in the snapshot. Delete `~/weblog-migration/caddy_data` on your workstation now, and the whole `~/weblog-migration` directory once Task 8 passes.

### Task 8: First deploy through the new path

- [ ] **Step 1: Merge the Task 3 branch** into `main`. The push triggers the workflow.
- [ ] **Step 2: Watch the run.** `prepare`, rsync and `activate` must succeed, and the smoke test must pass. Confirm on the server:

```bash
ssh ops@HOST 'ls -la /srv/weblog/site/releases; readlink /srv/weblog/site/current'
```

- [ ] **Step 3: Test rollback once** by triggering `workflow_dispatch` with a deliberately broken build is not worth it; instead run the script by hand as `ops` and confirm the site still answers:

```bash
sudo -u deploy weblog-release rollback <previous-release-name>
curl -sI https://webcodr.io/ | head -1
sudo -u deploy weblog-release rollback <newest-release-name>
```

- [ ] **Step 4: Verify headers and HTTP/3**

```bash
curl -sI https://webcodr.io/ | grep -iE 'strict-transport|content-security|alt-svc|server'
```

Expect HSTS, CSP, an `alt-svc: h3=` header, and no `server` header.

- [ ] **Step 5: Delete the snapshot** after a few days of normal operation, and remove `~/weblog-migration` from your workstation.

### Task 9: Documentation

**Files:**
- Modify: `AGENTS.md`

- [ ] **Step 1: Update the Deployment section**

Replace the references to `~/projects/weblog/site` with `/srv/weblog/site`, note the `ops` and `deploy` identities, state that the deploy key is restricted to `rrsync` into `releases/` and to `weblog-release` subcommands, note that the compose stack lives at `/opt/weblog` and infra changes (compose, Caddyfile) are applied with `git pull && docker compose up -d` as `ops`, and remove the paragraph about the one-time migration from root-level `current`/`releases`.

- [ ] **Step 2: Commit**

```bash
git add AGENTS.md
git commit -m "docs: describe the rebuilt production host and restricted deploy path"
```

---

## Post-Rebuild Checklist

- `docker compose exec caddy id` shows uid 1000, and the host process runs as the remapped uid.
- `docker compose exec caddy touch /x` fails with a read-only filesystem error.
- `ssh deploy@HOST id` is refused; `ssh deploy@HOST weblog-release current` works.
- `ssh root@HOST` is refused; `ssh ops@HOST` works with key only.
- `nft list ruleset` shows the input policy `drop` with 22, 80, 443 open.
- `systemctl status unattended-upgrades` is active and `/var/log/unattended-upgrades/` fills over the following week.
- Dependabot still opens PRs for the Caddy image digest; merging one and running `git pull && docker compose up -d` as `ops` recreates the container.

## Deliberately Not Done

- **Rootless Docker.** See Decisions. User-namespace remapping covers the main risk with less networking friction.
- **fail2ban.** SSH is key-only with `MaxAuthTries 3` and a connection-rate limit in nftables. Brute-force noise in the logs is not a risk worth another daemon.
- **Caddy access logs.** Not enabled today, not needed for a blog, and enabling them would add a personal-data retention question. Leave off.
- **AppArmor profile for Caddy.** Debian ships AppArmor enabled and Docker applies its default `docker-default` profile automatically. A custom profile adds maintenance for marginal gain on a read-only, non-root, capability-less container.

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

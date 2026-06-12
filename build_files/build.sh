#!/bin/bash

set -ouex pipefail

### Install packages

# Packages can be installed from any enabled yum repo on the image.
# RPMfusion repos are available by default in ublue main images
# List of rpmfusion packages can be found here:
# https://mirrors.rpmfusion.org/mirrorlist?path=free/fedora/updates/43/x86_64/repoview/index.html&protocol=https&redirect=1

# 1Password
rpm --import https://downloads.1password.com/linux/keys/1password.asc

cat > /etc/yum.repos.d/1password.repo << 'EOF'
[1password]
name=1Password Stable Channel
baseurl=https://downloads.1password.com/linux/rpm/stable/$basearch
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey="https://downloads.1password.com/linux/keys/1password.asc"
EOF

dnf5 install -y 1password

# Cider
rpm --import https://repo.cider.sh/RPM-GPG-KEY

cat > /etc/yum.repos.d/cider.repo << 'EOF'
[cidercollective]
name=Cider Collective Repository
baseurl=https://repo.cider.sh/rpm/RPMS
enabled=1
gpgcheck=1
gpgkey=https://repo.cider.sh/RPM-GPG-KEY
EOF

dnf5 install -y Cider

# Discord
curl -Lo /tmp/discord.rpm "https://discord.com/api/download?platform=linux&format=rpm"
dnf5 install -y /tmp/discord.rpm
rm -f /tmp/discord.rpm

# Mullvad
dnf5 config-manager addrepo --from-repofile=https://repository.mullvad.net/rpm/stable/mullvad.repo
dnf5 install -y mullvad-vpn
systemctl enable mullvad-daemon.service
systemctl enable mullvad-early-boot-blocking.service

# Syncthing
dnf5 install -y syncthing 
systemctl --global enable syncthing.service
mkdir -p /etc/systemd/user/syncthing.service.d/
cat > /etc/systemd/user/syncthing.service.d/condition-user.conf << 'EOF'
[Unit]
ConditionUser=!@system
EOF

# DNSCrypt
dnf5 install -y dnscrypt-proxy
systemctl disable systemd-resolved
systemctl enable dnscrypt-proxy

mkdir -p /etc/NetworkManager/conf.d/
cat > /etc/NetworkManager/conf.d/dns.conf << 'EOF'
[main]
dns=none
EOF

rm -f /etc/resolv.conf
cat > /etc/resolv.conf << 'EOF'
nameserver 127.0.0.1
options edns0
EOF

sed -i "s/^# server_names = .*/server_names = ['NextDNS-baf169']/" \
    /etc/dnscrypt-proxy/dnscrypt-proxy.toml

sed -i "s/^bootstrap_resolvers = .*/bootstrap_resolvers = ['9.9.9.9:53', '149.112.112.112:53']/" \
    /etc/dnscrypt-proxy/dnscrypt-proxy.toml

sed -i 's/^block_ipv6 = false/block_ipv6 = true/' \
    /etc/dnscrypt-proxy/dnscrypt-proxy.toml

cat >> /etc/dnscrypt-proxy/dnscrypt-proxy.toml << 'EOF'

[static.'NextDNS-baf169']
  stamp = 'sdns://AgEAAAAAAAAAAAAOZG5zLm5leHRkbnMuaW8HL2JhZjE2OQ'
EOF
#!/bin/bash

set -ouex pipefail

### Install packages

# Packages can be installed from any enabled yum repo on the image.
# RPMfusion repos are available by default in ublue main images
# List of rpmfusion packages can be found here:
# https://mirrors.rpmfusion.org/mirrorlist?path=free/fedora/updates/43/x86_64/repoview/index.html&protocol=https&redirect=1

# Proton Pass
read -r RPM_URL RPM_SHA < <(curl -sS https://proton.me/download/PassDesktop/linux/x64/version.json | jq -r '
  [.Releases[] | select(.CategoryName == "Stable")] 
  | sort_by(.ReleaseDate) 
  | last 
  | .File[] 
  | select(.Identifier | contains(".rpm")) 
  | "\(.Url) \(.Sha512CheckSum)"
')

pushd /tmp || exit 1

curl -Lo proton-pass.rpm "$RPM_URL"

if ! echo "$RPM_SHA  proton-pass.rpm" | sha512sum -c -; then
  echo "Error: proton pass checksum doesn't match"
  popd
  exit 1
fi

popd
dnf5 install -y /tmp/proton-pass.rpm
rm -f /tmp/proton-pass.rpm

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

# ripgrep
dnf5 install -y ripgrep

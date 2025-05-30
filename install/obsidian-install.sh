#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: Your Name
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://obsidian.md/ (Inspired by Dockerfile from sytone/obsidian-remote)

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
  curl \
  libgtk-3-0 \
  libnotify4 \
  libatspi2.0-0 \
  libsecret-1-0 \
  libnss3 \
  desktop-file-utils \
  fonts-noto-color-emoji \
  git \
  ssh-askpass
msg_ok "Installed Dependencies"

msg_info "Fetching latest Obsidian version"
OBSIDIAN_VERSION=$(curl -s https://api.github.com/repos/obsidianmd/obsidian-releases/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
if [ -z "$OBSIDIAN_VERSION" ]; then
  msg_error "Failed to fetch the latest Obsidian version. Exiting."
  exit 1
fi
msg_ok "Fetched latest Obsidian version: v${OBSIDIAN_VERSION}"

msg_info "Installing Obsidian v${OBSIDIAN_VERSION}"
$STD curl --location --output obsidian.deb "https://github.com/obsidianmd/obsidian-releases/releases/download/v${OBSIDIAN_VERSION}/obsidian_${OBSIDIAN_VERSION}_amd64.deb"
$STD dpkg -i obsidian.deb
$STD apt-get install -f -y # Install missing dependencies for obsidian if any
rm obsidian.deb
echo "${OBSIDIAN_VERSION}" >"/opt/${APPLICATION}_version.txt"
msg_ok "Installed Obsidian v${OBSIDIAN_VERSION}"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"

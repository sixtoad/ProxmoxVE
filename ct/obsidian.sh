#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: Your Name
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://obsidian.md/

APP="Obsidian-App"
var_os="debian"
var_version="12"
var_disk="4"
var_cpu="1"
var_ram="1024" # Obsidian can be resource-intensive with many plugins
var_arch="amd64"
var_description="Obsidian is a powerful and extensible knowledge base. This installs the application only; GUI access requires separate setup (e.g., X11 forwarding)."
var_tags="utility;productivity;notes"
var_unprivileged="1" # Obsidian doesn't typically need privileged access

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -f /opt/${APP}_version.txt ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  CURRENT_VERSION=$(cat /opt/${APP}_version.txt)
  LATEST_VERSION=$(curl -s https://api.github.com/repos/obsidianmd/obsidian-releases/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')

  if [[ "$CURRENT_VERSION" == "$LATEST_VERSION" ]]; then
    msg_ok "No update required. ${APP} is already at v${LATEST_VERSION}."
    exit
  fi

  msg_info "Updating ${APP} from v${CURRENT_VERSION} to v${LATEST_VERSION}"
  $STD apt-get update
  $STD apt-get install -y curl
  $STD curl --location --output obsidian.deb "https://github.com/obsidianmd/obsidian-releases/releases/download/v${LATEST_VERSION}/obsidian_${LATEST_VERSION}_amd64.deb"
  $STD dpkg -i obsidian.deb
  $STD apt-get install -f -y # Install missing dependencies if any
  rm obsidian.deb
  echo "${LATEST_VERSION}" >/opt/${APP}_version.txt
  msg_ok "Updated ${APP} to v${LATEST_VERSION}"
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Obsidian application is installed. GUI access requires separate setup (e.g., X11 forwarding from your desktop).${CL}"
echo -e "${INFO}${YW} Consider creating a '/vaults' directory in the LXC and mounting your Obsidian vaults there for data persistence.${CL}"

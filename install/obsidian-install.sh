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
  ssh-askpass \
  tigervnc-standalone-server \
  tigervnc-xorg-extension \
  novnc \
  websockify \
  fluxbox \
  supervisor \
  xvfb \
  dbus-x11 \
  libxss1 \
  xdg-utils
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

msg_info "Setting up VNC and Web Access"
# Configure VNC
mkdir -p /root/.vnc
VNC_PASS=$(openssl rand -base64 12 | tr -dc 'a-zA-Z0-9' | head -c8)
echo "$VNC_PASS" | tigervncpasswd -f >/root/.vnc/passwd
chmod 600 /root/.vnc/passwd

cat <<EOF >/root/.vnc/xstartup
#!/bin/sh
# Start a D-Bus session if not already started
if [ -z "\$DBUS_SESSION_BUS_ADDRESS" ]; then
    eval \$(dbus-launch --sh-syntax --exit-with-session)
fi

export FONTCONFIG_PATH=/etc/fonts
export _JAVA_AWT_WM_NONREPARENTING=1
[ -x /etc/vnc/xstartup ] && exec /etc/vnc/xstartup
[ -r \$HOME/.Xresources ] && xrdb \$HOME/.Xresources
fluxbox &
sleep 3
if [ -x "/opt/Obsidian/obsidian" ]; then
    /opt/Obsidian/obsidian --no-sandbox
else
    obsidian --no-sandbox
fi
EOF
chmod +x /root/.vnc/xstartup

# Configure Supervisor
mkdir -p /var/log/supervisor/
cat <<EOF >/etc/supervisor/conf.d/obsidian-vnc.conf
[supervisord]
nodaemon=true
user=root

[program:vncserver]
command=tigervncserver :1 -localhost yes -desktop Obsidian -geometry 1280x800 -depth 24 -fg -passwd /root/.vnc/passwd -xstartup /root/.vnc/xstartup
user=root
autostart=true
autorestart=true
stdout_logfile=/var/log/supervisor/vncserver_stdout.log
stderr_logfile=/var/log/supervisor/vncserver_stderr.log

[program:novnc]
command=websockify --web=/usr/share/novnc/ 8080 localhost:5901
user=root
autostart=true
autorestart=true
stdout_logfile=/var/log/supervisor/novnc_stdout.log
stderr_logfile=/var/log/supervisor/novnc_stderr.log
EOF

# Enable and start Supervisor
systemctl enable -q --now supervisor

# Store VNC password
echo "VNC Password: $VNC_PASS (access via http://<IP>:8080)" >>~/"$APPLICATION".creds
msg_ok "VNC and Web Access Setup Complete. Access at http://<IP>:8080"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"

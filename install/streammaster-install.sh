#!/usr/bin/env bash

# Copyright (c) 2021-2024 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/r0ckf3l3r/Proxmox/raw/main/LICENSE

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y curl
$STD apt-get install -y sudo
$STD apt-get install -y mc
msg_ok "Installed Dependencies"

get_latest_release() {
  curl -sL https://api.github.com/repos/$1/releases/latest | grep '"tag_name":' | cut -d'"' -f4
}

DOCKER_LATEST_VERSION=$(get_latest_release "moby/moby")
STREAMMASTER_LATEST_VERSION=$(get_latest_release "senexcrenshaw/streammaster")
PORTAINER_LATEST_VERSION=$(get_latest_release "portainer/portainer")

msg_info "Installing Docker $DOCKER_LATEST_VERSION"
DOCKER_CONFIG_PATH='/etc/docker/daemon.json'
mkdir -p $(dirname $DOCKER_CONFIG_PATH)
echo -e '{\n  "log-driver": "journald"\n}' >/etc/docker/daemon.json
$STD sh <(curl -sSL https://get.docker.com)
msg_ok "Installed Docker $DOCKER_LATEST_VERSION"

msg_info "Pulling Portainer $PORTAINER_LATEST_VERSION Image"
$STD docker pull portainer/portainer-ce:latest
msg_ok "Pulled Portainer $PORTAINER_LATEST_VERSION Image"

msg_info "Installing Portainer $PORTAINER_LATEST_VERSION"
$STD docker volume create portainer_data
$STD docker run -d \
  -p 8000:8000 \
  -p 9443:9443 \
  --name=portainer \
  --restart=always \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v portainer_data:/data \
  portainer/portainer-ce:latest
msg_ok "Installed Portainer $PORTAINER_LATEST_VERSION"

msg_info "Pulling StreamMaster $STREAMMASTER_LATEST_VERSION Image"
$STD docker pull senexcrenshaw/streammaster:latest
msg_ok "Pulled StreamMaster $STREAMMASTER_LATEST_VERSION Image"

msg_info "Installing StreamMaster $STREAMMASTER_LATEST_VERSION"
$STD docker volume create streammaster_config
$STD docker run -d \
  --name streammaster \
  -p 7095:7095 \
  -p 7096:7096 \
  --privileged \
  --restart unless-stopped \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /dev:/dev \
  -v streammaster_config:/config \
  -v /etc/localtime:/etc/localtime:ro \
  --net=host \
  senexcrenshaw/streammaster:latest
mkdir -p /root/streammaster_config/tv-logos
cd /root/streammaster_config/tv-logos
$STD git clone https://github.com/tv-logo/tv-logos.git .
msg_ok "Installed Home StreamMaster $STREAMMASTER_LATEST_VERSION"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"

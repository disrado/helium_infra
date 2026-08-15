#!/usr/bin/env bash
set -euo pipefail

# systemd (needed for dockerd, systemd-timesyncd)
sudo grep -q '^systemd=true' /etc/wsl.conf 2>/dev/null || printf '[boot]\nsystemd=true\n' | sudo tee -a /etc/wsl.conf >/dev/null

# clock-drift fix: systemd-timesyncd's ConditionVirtualization trips on WSL2
dpkg -s systemd-timesyncd &>/dev/null || { sudo apt-get update -qq && sudo apt-get install -y systemd-timesyncd; }
sudo cp /usr/lib/systemd/system/systemd-timesyncd.service /etc/systemd/system/systemd-timesyncd.service
sudo sed -i '/ConditionVirtualization/d' /etc/systemd/system/systemd-timesyncd.service
sudo systemctl daemon-reload
sudo systemctl enable --now systemd-timesyncd

# native Docker Engine; patches out get.docker.com's WSL-detected nag sleep
if ! command -v docker &>/dev/null; then
    curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
    sed -i 's/sleep 20/sleep 1/' /tmp/get-docker.sh
    sudo sh /tmp/get-docker.sh
    rm -f /tmp/get-docker.sh
    sudo usermod -aG docker "$USER"
fi

# passwordless sudo, for non-interactive remote automation
sudo grep -q "^$USER ALL=(ALL) NOPASSWD:ALL" /etc/sudoers.d/wsl-agent 2>/dev/null || \
    echo "$USER ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/wsl-agent >/dev/null

curl -fsSL https://raw.githubusercontent.com/disrado/helium_infra/main/build_env/wsl/agent/bootstrap.sh -o /tmp/bootstrap.sh
chmod +x /tmp/bootstrap.sh

# sudo not sg: group change needs a new session anyway, and sg isn't always present
sudo /tmp/bootstrap.sh "$1" "$2" "$3"

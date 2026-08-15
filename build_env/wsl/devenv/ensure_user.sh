#!/usr/bin/env bash
set -euo pipefail

username="${1:?Usage: ensure_user.sh <username>}"

id -u "$username" &>/dev/null || useradd -m -s /bin/bash -G sudo "$username"
echo "$username ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/$username"

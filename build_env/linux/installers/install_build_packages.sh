#!/usr/bin/env bash
set -euo pipefail

apt-get update
apt-get install -y \
    build-essential libc6-dev make dpkg-dev python3-pip ninja-build git curl zip unzip tar pkg-config \
    libx11-dev libxcursor-dev libxrandr-dev libxi-dev libxext-dev libxft-dev libxtst-dev \
    libgl1-mesa-dev libwayland-dev libxkbcommon-dev libegl1-mesa-dev \
    gcc-16 g++-16
rm -rf /var/lib/apt/lists/*

pip install --break-system-packages --root-user-action=ignore cmake scons

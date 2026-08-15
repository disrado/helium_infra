#!/usr/bin/env bash
set -euo pipefail

sudo apt-get update && sudo apt-get install -y git-lfs zsh
git lfs install
sudo chsh -s "$(which zsh)" "$USER"

curl -fsSL https://raw.githubusercontent.com/disrado/helium_infra/main/build_env/linux/installers/install_build_packages.sh -o /tmp/install_build_packages.sh
curl -fsSL https://raw.githubusercontent.com/disrado/helium_infra/main/build_env/linux/installers/install_vcpkg.sh -o /tmp/install_vcpkg.sh
chmod +x /tmp/install_build_packages.sh /tmp/install_vcpkg.sh

sudo /tmp/install_build_packages.sh
RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" < /dev/null
/tmp/install_vcpkg.sh
grep -q '^export VCPKG_ROOT=' ~/.zshenv 2>/dev/null || echo 'export VCPKG_ROOT=$HOME/vcpkg' >> ~/.zshenv

mkdir -p ~/src
[ -d ~/src/helium/.git ] || git clone https://github.com/disrado/helium.git ~/src/helium
git -C ~/src/helium submodule update --init deps/godot_cpp

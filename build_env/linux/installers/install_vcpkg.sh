#!/usr/bin/env bash
set -euo pipefail

vcpkg_dir="$HOME/vcpkg"
# .git check, not just dir existence - a clone interrupted mid-run leaves the dir
# behind without a completed .git, which a bare -d check would wrongly treat as done.
if [ ! -d "$vcpkg_dir/.git" ]; then
    rm -rf "$vcpkg_dir"
    git clone https://github.com/microsoft/vcpkg "$vcpkg_dir"
fi
"$vcpkg_dir/bootstrap-vcpkg.sh"

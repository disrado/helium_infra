#!/bin/bash
set -euo pipefail

workspaces_root="$(dirname "$WORKSPACE")"

# Reset persisted build state across all job workspaces.
for ws in "$workspaces_root"/*/; do
    rm -rf "${ws}build" "${ws}deps/godot/bin" "${ws}deps/godot/.sconsign.dblite"
done

# Purge stuck cleanWs() quarantine dirs.
find "$workspaces_root" -maxdepth 1 -name '*_ws-cleanup_*' -exec rm -rf {} +

docker system prune -af --volumes

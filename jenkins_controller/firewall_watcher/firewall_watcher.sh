#!/usr/bin/env bash
set -euo pipefail

TAG="webhook-allowlist"
HOME_HOSTNAME="disrado.ddns.net"
PORTS=(80 443)

home_v4="$(dig +short -t A "$HOME_HOSTNAME" | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' | tail -n1 || true)"
home_v6="$(dig +short -t AAAA "$HOME_HOSTNAME" | grep -E '^[0-9a-fA-F:]+$' | tail -n1 || true)"
github_ranges="$(curl -s https://api.github.com/meta | jq -r '.hooks[]')"

# re-derive from scratch every run - simpler than diffing current vs desired state, and cheap enough to run on a timer.
old_rule_numbers="$(ufw status numbered | grep "$TAG" | grep -oE '^\[[0-9]+\]' | tr -d '[]' | sort -rn || true)"
for num in $old_rule_numbers; do
    ufw --force delete "$num" >/dev/null
done

for port in "${PORTS[@]}"; do
    [ -n "$home_v4" ] && ufw allow from "$home_v4" to any port "$port" proto tcp comment "$TAG"
    [ -n "$home_v6" ] && ufw allow from "$home_v6" to any port "$port" proto tcp comment "$TAG"
    for cidr in $github_ranges; do
        ufw allow from "$cidr" to any port "$port" proto tcp comment "$TAG"
    done
done

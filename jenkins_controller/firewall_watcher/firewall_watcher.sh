#!/usr/bin/env bash
set -euo pipefail

TAG="webhook-allowlist"
HOME_HOSTNAME="disrado.ddns.net"

# Docker-published ports (Caddy's 80/443) are handled via NAT + the FORWARD chain, not INPUT - ufw never
# sees this traffic. DOCKER-USER is the chain Docker reserves for user filtering of forwarded container
# traffic; rules here are respected and survive Docker/daemon restarts.

home_v4="$(dig +short -t A "$HOME_HOSTNAME" | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' | tail -n1 || true)"
github_v4_ranges="$(curl -s https://api.github.com/meta | jq -r '.hooks[]' | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' || true)"

# re-derive from scratch every run - simpler than diffing current vs desired state, and cheap enough to run on a timer.
old_rule_numbers="$(iptables -L DOCKER-USER --line-numbers -n | grep "$TAG" | grep -oE '^[0-9]+' | sort -rn || true)"
for num in $old_rule_numbers; do
    iptables -D DOCKER-USER "$num"
done

# -i eth0 scopes this to traffic arriving from the internet only - without it, this also caught containers'
# own outbound calls (e.g. Jenkins hitting api.github.com), which broke GitHub App token generation entirely.
#
# insertion order matters: each -I ... 1 lands on top of whatever's already there, so insert the DROP
# first, then the RETURN rules after - by the end, all RETURNs sit above the DROP.
iptables -I DOCKER-USER 1 -i eth0 -p tcp -m multiport --dports 80,443 -j DROP -m comment --comment "$TAG"

[ -n "$home_v4" ] && iptables -I DOCKER-USER 1 -i eth0 -p tcp -s "$home_v4" -m multiport --dports 80,443 -j RETURN -m comment --comment "$TAG"
for cidr in $github_v4_ranges; do
    iptables -I DOCKER-USER 1 -i eth0 -p tcp -s "$cidr" -m multiport --dports 80,443 -j RETURN -m comment --comment "$TAG"
done

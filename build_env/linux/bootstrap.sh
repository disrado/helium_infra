#!/usr/bin/env bash
set -euo pipefail

JENKINS_URL="${1:?Usage: bootstrap.sh <jenkins-url> <agent-secret> <agent-name>}"
JENKINS_SECRET="${2:?}"
JENKINS_AGENT_NAME="${3:?}"

# defensive strip: a stray \r was observed reaching here through the PowerShell
# wrapper's argument passing, breaking docker run --name's validation
JENKINS_URL="$(echo -n "$JENKINS_URL" | tr -d '\r')"
JENKINS_SECRET="$(echo -n "$JENKINS_SECRET" | tr -d '\r')"
JENKINS_AGENT_NAME="$(echo -n "$JENKINS_AGENT_NAME" | tr -d '\r')"

REPO_DIR="$HOME/helium_infra"
[ -d "$REPO_DIR" ] || git clone https://github.com/disrado/helium_infra.git "$REPO_DIR"
cd "$REPO_DIR/build_env/linux"

docker build -t helium-linux-build-env:latest .

docker build -t helium-linux-jenkins-agent:latest ../../jenkins_agent/linux

DOCKER_GID="$(getent group docker | cut -d: -f3)"

sudo mkdir -p /home/jenkins/agent
sudo chown -R 1000:1000 /home/jenkins/agent

# safe to re-run: removes any leftover container from an interrupted prior attempt
docker rm -f "$JENKINS_AGENT_NAME" 2>/dev/null || true

docker run -d --name "$JENKINS_AGENT_NAME" --restart unless-stopped \
  --group-add "$DOCKER_GID" \
  -e JENKINS_URL="$JENKINS_URL" \
  -e JENKINS_SECRET="$JENKINS_SECRET" \
  -e JENKINS_AGENT_NAME="$JENKINS_AGENT_NAME" \
  -e JENKINS_WEB_SOCKET=true \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /home/jenkins/agent:/home/jenkins/agent \
  helium-linux-jenkins-agent:latest

echo "Waiting for agent to connect..."
CONNECTED=false
for i in $(seq 1 15); do
    if docker logs "$JENKINS_AGENT_NAME" 2>&1 | grep -q "INFO: Connected"; then
        CONNECTED=true
        break
    fi
    if docker logs "$JENKINS_AGENT_NAME" 2>&1 | grep -qiE "error|exception|refused"; then
        break
    fi
    sleep 2
done

if [ "$CONNECTED" != "true" ]; then
    echo "ERROR: agent did not connect to Jenkins. Recent logs:" >&2
    docker logs --tail 20 "$JENKINS_AGENT_NAME" >&2
    exit 1
fi

echo "Agent connected successfully."

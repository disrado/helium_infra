#!/usr/bin/env bash
set -euo pipefail

JENKINS_URL="${1:?Usage: bootstrap.sh <jenkins-url> <agent-secret> <agent-name>}"
JENKINS_SECRET="${2:?}"
JENKINS_AGENT_NAME="${3:?}"

REPO_DIR="$HOME/helium_infra"
[ -d "$REPO_DIR" ] || git clone https://github.com/disrado/helium_infra.git "$REPO_DIR"
cd "$REPO_DIR/build_env/linux"

docker build -t helium-linux-build-env:latest .

docker build -t helium-linux-jenkins-agent:latest ../../jenkins_agent/linux

DOCKER_GID="$(getent group docker | cut -d: -f3)"

sudo mkdir -p /home/jenkins/agent
sudo chown -R 1000:1000 /home/jenkins/agent

docker run -d --name "$JENKINS_AGENT_NAME" --restart unless-stopped \
  --group-add "$DOCKER_GID" \
  -e JENKINS_URL="$JENKINS_URL" \
  -e JENKINS_SECRET="$JENKINS_SECRET" \
  -e JENKINS_AGENT_NAME="$JENKINS_AGENT_NAME" \
  -e JENKINS_WEB_SOCKET=true \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /home/jenkins/agent:/home/jenkins/agent \
  helium-linux-jenkins-agent:latest

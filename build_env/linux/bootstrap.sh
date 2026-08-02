#!/usr/bin/env bash
set -euo pipefail

JENKINS_URL="${1:?Usage: bootstrap.sh <jenkins-url> <agent-secret> <agent-name>}"
JENKINS_SECRET="${2:?}"
JENKINS_AGENT_NAME="${3:?}"

cd "$(dirname "$0")"
docker build -t helium-linux-build-env:latest .

docker build -t helium-linux-jenkins-agent:latest ../../jenkins_agent/linux

docker run -d --name "$JENKINS_AGENT_NAME" --restart unless-stopped \
  -e JENKINS_URL="$JENKINS_URL" \
  -e JENKINS_SECRET="$JENKINS_SECRET" \
  -e JENKINS_AGENT_NAME="$JENKINS_AGENT_NAME" \
  -e JENKINS_WEB_SOCKET=true \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v jenkins_agent_workdir:/home/jenkins/agent \
  helium-linux-jenkins-agent:latest

#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

docker build -f Dockerfile -t helium-linux-build-env:latest ..
docker build -t helium-linux-jenkins-agent:latest ../../../jenkins_agent/linux

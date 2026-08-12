FROM jenkins/inbound-agent:latest

USER root
RUN apt-get update && apt-get install -y docker.io git-lfs && rm -rf /var/lib/apt/lists/* && git lfs install --system
USER jenkins

# helium_infra

## Setup new Linux agent

Prerequisites: Docker running on the machine (WSL2 + `get.docker.com` if Windows host).

1. Jenkins → Manage Jenkins → Nodes → New Node → Permanent Agent, label `linux`, launch: inbound. Copy the secret.
2. ```
   git clone https://github.com/disrado/helium_infra.git
   cd helium_infra/build_env/linux
   ./bootstrap.sh <jenkins-url> <agent-secret> <agent-name>
   ```
3. Check node shows connected in Jenkins.

## Updating an existing agent's images

Don't re-run `bootstrap.sh`. Run the `setup_agent` Jenkins job instead — rebuilds images without touching the
running container.

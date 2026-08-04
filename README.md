# helium_infra

## Setup new Linux agent

### 1. Create the Jenkins node

Jenkins → Manage Jenkins → Nodes → New Node → Permanent Agent, label `linux`, launch: inbound.

### 2. Run the bootstrap

#### Windows

Requires virtualization enabled in BIOS/firmware (needed for WSL2/Hyper-V) - if disabled, `wsl --install` and the
script's own reboot check will keep failing since it's a firmware setting, not something Windows/a reboot fixes.

Fresh machine (elevated PowerShell):
```powershell
irm https://raw.githubusercontent.com/disrado/helium_infra/main/bootstrap_linux_agent.ps1 -OutFile bootstrap_linux_agent.ps1
```
```powershell
powershell -ExecutionPolicy Bypass -File .\bootstrap_linux_agent.ps1 -JenkinsUrl <jenkins-url> -AgentSecret <agent-secret> -AgentName <agent-name>
```
Args:
- `-JenkinsUrl` Jenkins controller URL.
- `-AgentSecret` from the node's config page.
- `-AgentName` name for the Jenkins node/container.
- `-Distro` WSL distro name, defaults to `Ubuntu`.

#### Linux

Docker already running:
```
curl -fsSL https://raw.githubusercontent.com/disrado/helium_infra/main/build_env/linux/bootstrap.sh | bash -s -- <jenkins-url> <agent-secret> <agent-name>
```

### 3. Verify

Check node shows connected in Jenkins.

## Updating an existing agent's images

Don't re-run `bootstrap.sh`. Run the `setup_agent` Jenkins job instead — rebuilds images without touching the
running container.

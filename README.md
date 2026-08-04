# helium project infrastructure

## Setup WSL agent

### 1. Create the Jenkins node

Jenkins → Manage Jenkins → Nodes → New Node → Permanent Agent, label `wsl`, launch: inbound, remote root
directory `/home/jenkins/agent`.

### 2. Run the bootstrap

#### Windows

Requires virtualization enabled in BIOS/firmware

Fresh machine (elevated PowerShell):
```powershell
irm https://raw.githubusercontent.com/disrado/helium_infra/main/build_env/linux/bootstrap_wsl_agent.ps1 -OutFile bootstrap_wsl_agent.ps1
```
```powershell
powershell -ExecutionPolicy Bypass -File .\bootstrap_wsl_agent.ps1 -JenkinsUrl <jenkins-url> -AgentSecret <agent-secret> -AgentName <agent-name>
```
Args:
- `-JenkinsUrl` Jenkins controller URL.
- `-AgentSecret` from the node's config page.
- `-AgentName` Jenkins node name.

#### Linux

Docker already running:
```
curl -fsSL https://raw.githubusercontent.com/disrado/helium_infra/main/build_env/linux/bootstrap.sh | bash -s -- <jenkins-url> <agent-secret> <agent-name>
```

### 3. Verify

Check node shows connected in Jenkins.

## Setup new Windows agent

Native (no containers) - installs the toolchain and registers the agent directly on the host.

### 1. Create the Jenkins node

Jenkins → Manage Jenkins → Nodes → New Node → Permanent Agent, label `windows`, launch: inbound, remote root
directory `C:\jenkins-agent\workDir`.

### 2. Run the bootstrap

Fresh machine (elevated PowerShell):
```powershell
irm https://raw.githubusercontent.com/disrado/helium_infra/main/build_env/windows/bootstrap_windows_agent.ps1 -OutFile bootstrap_windows_agent.ps1
```
```powershell
powershell -ExecutionPolicy Bypass -File .\bootstrap_windows_agent.ps1 -JenkinsUrl <jenkins-url> -AgentSecret <agent-secret> -AgentName <agent-name>
```
Args:
- `-JenkinsUrl` Jenkins controller URL.
- `-AgentSecret` from the node's config page.
- `-AgentName` Jenkins node name.

### 3. Verify

Check node shows connected in Jenkins.

## Updating an existing agent's environment

Don't re-run the bootstrap scripts. Run the `update_agent_env` Jenkins job instead - rebuilds images or reinstalls the toolchain without touching the running agent.

## Removing an agent

Run on the machine itself (elevated PowerShell), not through Jenkins. Leaves the Jenkins node itself in place -
delete it manually in Jenkins after the script finishes.

**WSL:**
```powershell
irm https://raw.githubusercontent.com/disrado/helium_infra/main/build_env/linux/tear_down_wsl_agent.ps1 -OutFile tear_down_wsl_agent.ps1
```
```powershell
powershell -ExecutionPolicy Bypass -File .\tear_down_wsl_agent.ps1
```

**Windows:**
```powershell
irm https://raw.githubusercontent.com/disrado/helium_infra/main/build_env/windows/tear_down_windows_agent.ps1 -OutFile tear_down_windows_agent.ps1
```
```powershell
powershell -ExecutionPolicy Bypass -File .\tear_down_windows_agent.ps1
```

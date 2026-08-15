# helium project infrastructure

- [Setup controller](#setup-controller)
- [Setup agent](#setup-agent)
  - [WSL](#wsl)
  - [Windows](#windows)
- [Setup devenv](#setup-devenv)
  - [WSL](#wsl-1)
  - [Windows](#windows-1)
- [Updating an existing agent's environment](#updating-an-existing-agents-environment)
- [Remove agent](#remove-agent)

## Setup controller

### 1. Provision a host

Any Docker-capable Linux host with a public IP works. `jenkins_controller/cloud-config` is cloud-init
user-data that installs required dependencies and setups firewall.

### 2. Clone this repo onto the host

```
git clone https://github.com/disrado/helium_infra.git
```

### 3. Point a domain at it

Create a DNS A record for your domain pointing at the host's IP. Then edit `jenkins_controller/Caddyfile`, replacing the placeholder domain
with your own - it reverse-proxies to Jenkins.

### 4. Start the stack

```
cd jenkins_controller
docker compose up -d
```

### 5. Finish setup

Complete Jenkins's own setup wizard (take generated password fomr `jenkins_home/secrets/initialAdminPassword` or from logs). 

Set executors on the controller to 0 before registering any agents.

### 6. Set up GitHub App access

Create a GitHub App with `Contents: Read-only`
and `Commit statuses: Read & write` permissions. Set its webhook active,
pointing at `https://<jenkins-url>/github-webhook/`, subscribed to `Push` + `Pull request` events. Install the App on `helium` and
`helium_infra`.

Generate a private key - GitHub issues it as PKCS#1, but Jenkins' GitHub Branch Source plugin needs PKCS#8:
```
openssl pkcs8 -topk8 -inform PEM -outform PEM -in downloaded-key.pem -out converted-key.pem -nocrypt
```

In Jenkins Credentials:
- add a **GitHub App** credential with the App ID + converted key, ID `helium_github_app`
- add the webhook's shared secret as a **Secret text** credential, ID `gh_webhook_secret` - verifies incoming webhook signatures

### 7. Create and run the seed job

Manually create one Pipeline job named `seed`:
- pipeline script from SCM
- `https://github.com/disrado/helium_infra.git`
- branch `infra/main`
- script path `jobs/seed/Jenkinsfile`.
- uses the `helium_github_app` credential from the previous step (same one the generated jobs use)
- requires at least one connected agent (`seed`'s pipeline runs `agent any`, and the controller itself has 0 executors).

## Setup agent

### WSL

#### 1. Create the Jenkins node

Jenkins → Manage Jenkins → Nodes → New Node → Permanent Agent, label `wsl`, launch: inbound, remote root
directory `/home/jenkins/agent`.

#### 2. Run the bootstrap

##### Windows

Requires virtualization enabled in BIOS/firmware

Fresh machine (elevated PowerShell):
```powershell
irm https://raw.githubusercontent.com/disrado/helium_infra/main/build_env/wsl/bootstrap_wsl_agent.ps1 -OutFile bootstrap_wsl_agent.ps1
```
```powershell
powershell -ExecutionPolicy Bypass -File .\bootstrap_wsl_agent.ps1 -JenkinsUrl <jenkins-url> -AgentSecret <agent-secret> -AgentName <agent-name>
```
Args:
- `-JenkinsUrl` Jenkins controller URL.
- `-AgentSecret` from the node's config page.
- `-AgentName` Jenkins node name.

##### Linux

Docker already running:
```
curl -fsSL https://raw.githubusercontent.com/disrado/helium_infra/main/build_env/wsl/agent/bootstrap.sh | bash -s -- <jenkins-url> <agent-secret> <agent-name>
```

#### 3. Verify

Check node shows connected in Jenkins.

### Windows

Native (no containers) - installs the toolchain and registers the agent directly on the host.

#### 1. Create the Jenkins node

Jenkins → Manage Jenkins → Nodes → New Node → Permanent Agent, label `windows`, launch: inbound, remote root
directory `C:\helium_agent\workDir`.

#### 2. Run the bootstrap

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

#### 3. Verify

Check node shows connected in Jenkins.

## Setup devenv

### WSL

No Jenkins registration, no Docker - just the toolchain and a clone of `helium`, for building locally.

Fresh machine (elevated PowerShell):
```powershell
irm https://raw.githubusercontent.com/disrado/helium_infra/main/build_env/wsl/bootstrap_wsl_devenv.ps1 -OutFile bootstrap_wsl_devenv.ps1
```
```powershell
powershell -ExecutionPolicy Bypass -File .\bootstrap_wsl_devenv.ps1
```
Optional args:
- `-Distro` WSL distro name to create/use. Defaults to `Ubuntu`.
- `-Username` Linux user to create/use. Defaults to the current Windows username.

### Windows

No Jenkins registration - just the toolchain and a clone of `helium`, for building locally.

Fresh machine (elevated PowerShell):
```powershell
irm https://raw.githubusercontent.com/disrado/helium_infra/main/build_env/windows/bootstrap_windows_devenv.ps1 -OutFile bootstrap_windows_devenv.ps1
```
```powershell
powershell -ExecutionPolicy Bypass -File .\bootstrap_windows_devenv.ps1
```

## Updating an existing agent's environment

Don't re-run the bootstrap scripts. Run the `update_agent_env` Jenkins job instead - rebuilds images or reinstalls the toolchain without touching the running agent.

## Remove agent

Run on the machine itself (elevated PowerShell), not through Jenkins. Leaves the Jenkins node itself in place -
delete it manually in Jenkins after the script finishes.

**WSL:**
```powershell
irm https://raw.githubusercontent.com/disrado/helium_infra/main/build_env/wsl/tear_down_wsl_agent.ps1 -OutFile tear_down_wsl_agent.ps1
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

# helium_infra

## Setup new Linux agent

Requires virtualization enabled in BIOS/firmware (needed for WSL2/Hyper-V) - if disabled, `wsl --install` and the
script's own reboot check will keep failing since it's a firmware setting, not something Windows/a reboot fixes.

1. Jenkins → Manage Jenkins → Nodes → New Node → Permanent Agent, label `linux`, launch: inbound. Copy the secret.
2. **Fresh Windows machine** (no WSL/Docker yet): run `bootstrap_linux_agent.ps1` from an elevated PowerShell —
   handles WSL2 install, Docker, and everything else, then hands off to `bootstrap.sh` below.
   ```powershell
   irm https://raw.githubusercontent.com/disrado/helium_infra/main/bootstrap_linux_agent.ps1 -OutFile bootstrap_linux_agent.ps1
   ```
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\bootstrap_linux_agent.ps1 -JenkinsUrl <jenkins-url> -AgentSecret <agent-secret> -AgentName <agent-name>
   ```
   **Machine already has Docker running** (WSL2 or bare Linux): skip straight to the Linux-side script.
   ```
   curl -fsSL https://raw.githubusercontent.com/disrado/helium_infra/main/build_env/linux/bootstrap.sh | bash -s -- <jenkins-url> <agent-secret> <agent-name>
   ```
3. Check node shows connected in Jenkins.

## Updating an existing agent's images

Don't re-run `bootstrap.sh`. Run the `setup_agent` Jenkins job instead — rebuilds images without touching the
running container.

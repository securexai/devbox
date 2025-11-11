# VS Code Remote SSH Setup for Multipass DevBox

This guide provides step-by-step instructions for connecting Visual Studio Code to your multipass devbox VM using the Remote - SSH extension.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Detailed Setup](#detailed-setup)
  - [1. Windows SSH Configuration](#1-windows-ssh-configuration)
  - [2. SSH Key Authentication (Recommended)](#2-ssh-key-authentication-recommended)
  - [3. VS Code Remote SSH Configuration](#3-vs-code-remote-ssh-configuration)
  - [4. First Connection](#4-first-connection)
- [Post-Setup Optimization](#post-setup-optimization)
- [Troubleshooting](#troubleshooting)
- [Advanced Configuration](#advanced-configuration)

---

## Prerequisites

Before starting, verify you have:

- **Windows 11** with PowerShell
- **VS Code** installed ([Download](https://code.visualstudio.com/))
- **Remote - SSH extension** installed in VS Code
- **Multipass devbox VM** running
- **Working SSH connection** from PowerShell

### Verify Prerequisites

```powershell
# Check VS Code is installed
code --version

# Verify multipass VM is running
multipass list

# Test SSH connection (replace IP with your VM's IP)
ssh devbox@172.29.10.254
```

---

## Quick Start

**For users who want to connect immediately:**

1. Open VS Code
2. Press `F1` or `Ctrl+Shift+P`
3. Type "Remote-SSH: Connect to Host"
4. Enter: `ssh devbox@172.29.10.254` (use your VM's IP)
5. Select "Linux" as the remote platform
6. Enter your password when prompted
7. Wait for VS Code server to install (first time only)
8. Open a folder: `File > Open Folder` → `/home/devbox`

**Note:** This works but requires password entry each time. For a better experience, follow the detailed setup below.

---

## Detailed Setup

### 1. Windows SSH Configuration

Creating an SSH config file makes connections easier and more reliable.

#### Step 1.1: Check if SSH config exists

```powershell
# Check if .ssh directory exists
Test-Path $env:USERPROFILE\.ssh
```

If it doesn't exist, create it:

```powershell
# Create .ssh directory
New-Item -Path $env:USERPROFILE\.ssh -ItemType Directory -Force

# Set proper permissions (secure the directory)
icacls "$env:USERPROFILE\.ssh" /inheritance:r
icacls "$env:USERPROFILE\.ssh" /grant:r "$env:USERNAME:(OI)(CI)F"
```

#### Step 1.2: Get your devbox VM IP address

```powershell
# Get the current IP address of devbox VM
multipass info devbox
```

Look for the IPv4 address in the output (e.g., `172.29.10.254`).

#### Step 1.3: Create SSH config file

Create or edit `C:\Users\s.tapia\.ssh\config`:

```ssh-config
# Multipass DevBox VM
Host devbox
    HostName 172.29.10.254
    User devbox
    Port 22
    ForwardAgent yes
    ServerAliveInterval 60
    ServerAliveCountMax 3
    ConnectTimeout 10

# Alternative: Use multipass command to get IP dynamically
# Note: This requires multipass in PATH
Host devbox-auto
    HostName 172.29.10.254
    User devbox
    Port 22
    ProxyCommand multipass exec devbox -- nc -q0 localhost 22
```

**Configuration explanation:**

- `Host devbox` - Friendly name for the connection
- `HostName` - IP address of the VM
- `User` - Username on the VM (default: devbox)
- `ForwardAgent` - Forward SSH keys to VM
- `ServerAliveInterval` - Keep connection alive (send keepalive every 60 seconds)
- `ServerAliveCountMax` - Retry 3 times before disconnecting
- `ConnectTimeout` - Timeout after 10 seconds if connection fails

#### Step 1.4: Test SSH config

```powershell
# Test connection using the config
ssh devbox
```

You should now be able to connect by just typing `ssh devbox` instead of the full command.

---

### 2. SSH Key Authentication (Recommended)

Using SSH keys eliminates the need to enter passwords and is more secure.

#### Step 2.1: Generate SSH key on Windows (if you don't have one)

```powershell
# Generate ED25519 key (modern and secure)
ssh-keygen -t ed25519 -C "vscode-devbox-connection"

# Or generate RSA key (for compatibility)
ssh-keygen -t rsa -b 4096 -C "vscode-devbox-connection"
```

**When prompted:**
- File location: Press Enter for default (`C:\Users\s.tapia\.ssh\id_ed25519`)
- Passphrase: Press Enter for no passphrase (or enter one for extra security)

#### Step 2.2: Copy public key to devbox VM

**Option A: Using ssh-copy-id (if available)**

```powershell
# Install OpenSSH client features if not available
Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0

# Copy the key
ssh-copy-id -i $env:USERPROFILE\.ssh\id_ed25519.pub devbox@172.29.10.254
```

**Option B: Manual copy (recommended for Windows)**

```powershell
# Read your public key
Get-Content $env:USERPROFILE\.ssh\id_ed25519.pub | Set-Clipboard

# Connect to VM and add the key
ssh devbox@172.29.10.254

# On the VM, run:
mkdir -p ~/.ssh
echo "YOUR_PUBLIC_KEY_HERE" >> ~/.ssh/authorized_keys
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
exit
```

**Option C: One-liner (PowerShell)**

```powershell
# Copy key in one command
$pubKey = Get-Content $env:USERPROFILE\.ssh\id_ed25519.pub
ssh devbox@172.29.10.254 "mkdir -p ~/.ssh && echo '$pubKey' >> ~/.ssh/authorized_keys && chmod 700 ~/.ssh && chmod 600 ~/.ssh/authorized_keys"
```

#### Step 2.3: Test passwordless authentication

```powershell
# Try connecting - should not ask for password
ssh devbox

# If successful, you should be logged in without a password prompt
```

#### Step 2.4: Update SSH config to use the key

Edit `C:\Users\s.tapia\.ssh\config` and add the `IdentityFile` line:

```ssh-config
Host devbox
    HostName 172.29.10.254
    User devbox
    Port 22
    IdentityFile C:\Users\s.tapia\.ssh\id_ed25519
    ForwardAgent yes
    ServerAliveInterval 60
    ServerAliveCountMax 3
    ConnectTimeout 10
```

---

### 3. VS Code Remote SSH Configuration

#### Step 3.1: Install Remote - SSH extension

1. Open VS Code
2. Click Extensions icon (or press `Ctrl+Shift+X`)
3. Search for "Remote - SSH"
4. Click "Install" on the official Microsoft extension

#### Step 3.2: Configure VS Code SSH settings

1. Open VS Code Settings (`Ctrl+,`)
2. Search for "remote ssh"
3. Configure these settings:

**Recommended settings:**

```json
{
    "remote.SSH.configFile": "C:\\Users\\s.tapia\\.ssh\\config",
    "remote.SSH.remotePlatform": {
        "devbox": "linux"
    },
    "remote.SSH.showLoginTerminal": true,
    "remote.SSH.useLocalServer": false,
    "remote.SSH.connectTimeout": 15
}
```

**To add these settings:**

1. Press `Ctrl+Shift+P`
2. Type "Preferences: Open Settings (JSON)"
3. Add the above settings to your `settings.json`

#### Step 3.3: Verify SSH config path

In VS Code:

1. Press `F1` or `Ctrl+Shift+P`
2. Type "Remote-SSH: Open SSH Configuration File"
3. Select `C:\Users\s.tapia\.ssh\config`
4. Verify the devbox host entry exists

---

### 4. First Connection

#### Step 4.1: Connect to devbox

1. Press `F1` or `Ctrl+Shift+P`
2. Type "Remote-SSH: Connect to Host"
3. Select `devbox` from the list
4. A new VS Code window will open
5. **First time only**: VS Code will install the server components (takes 1-2 minutes)

#### Step 4.2: Verify connection

Once connected, you should see:

- Bottom left corner: `SSH: devbox` in green
- Terminal shows: `devbox@devbox:~$`

#### Step 4.3: Open a folder

1. Click `File > Open Folder` or press `Ctrl+K Ctrl+O`
2. Navigate to `/home/devbox` or `/home/devbox/code`
3. Click "OK"

#### Step 4.4: Open integrated terminal

1. Press `` Ctrl+` `` or `View > Terminal`
2. You should see a terminal connected to the devbox VM
3. Test: `pwd` should show your home directory

---

## Post-Setup Optimization

### Recommended Extensions for Remote Development

Install these extensions on the remote (devbox VM):

**Essential:**

- Git History
- GitLens
- Docker (if using containers)
- Remote - Containers (for devbox projects)

**Language Support:**

- Python (if using Python)
- Go (if using Go)
- Rust Analyzer (if using Rust)

**To install extensions on remote:**

1. Click Extensions icon
2. Search for the extension
3. Click "Install in SSH: devbox"

### VS Code Remote Settings

Create `.vscode/settings.json` in your remote project:

```json
{
    "files.watcherExclude": {
        "**/.git/objects/**": true,
        "**/node_modules/**": true,
        "**/.devbox/**": true
    },
    "terminal.integrated.defaultProfile.linux": "bash",
    "git.enableSmartCommit": true,
    "git.confirmSync": false
}
```

### Performance Tuning

For large projects, adjust these settings in VS Code remote:

```json
{
    "files.watcherExclude": {
        "**/.git/objects/**": true,
        "**/node_modules/**": true,
        "**/.devbox/**": true,
        "**/target/**": true,
        "**/dist/**": true,
        "**/build/**": true
    },
    "search.exclude": {
        "**/node_modules": true,
        "**/bower_components": true,
        "**/.devbox": true,
        "**/target": true,
        "**/dist": true
    },
    "files.maxMemoryForLargeFilesMB": 4096
}
```

---

## Troubleshooting

### Connection Issues

#### Problem: "Could not establish connection to devbox"

**Solution 1: Check VM is running**

```powershell
multipass list
# If not running:
multipass start devbox
```

**Solution 2: Verify IP address hasn't changed**

```powershell
multipass info devbox
# Update C:\Users\s.tapia\.ssh\config with new IP
```

**Solution 3: Test SSH connection**

```powershell
ssh -v devbox
# Check for errors in verbose output
```

#### Problem: "Permission denied (publickey)"

**Solutions:**

```powershell
# Verify key exists
Test-Path $env:USERPROFILE\.ssh\id_ed25519

# Check key permissions
icacls $env:USERPROFILE\.ssh\id_ed25519

# Verify public key is on VM
ssh devbox "cat ~/.ssh/authorized_keys"

# Re-copy public key if missing
Get-Content $env:USERPROFILE\.ssh\id_ed25519.pub | ssh devbox "cat >> ~/.ssh/authorized_keys"
```

#### Problem: Connection timeout

**Solutions:**

1. Increase timeout in SSH config:

```ssh-config
Host devbox
    ConnectTimeout 30
    ServerAliveInterval 60
```

2. Check Windows Firewall:

```powershell
# Allow SSH through firewall
New-NetFirewallRule -DisplayName "SSH Outbound" -Direction Outbound -Protocol TCP -LocalPort 22 -Action Allow
```

3. Restart VM networking:

```powershell
multipass restart devbox
```

### VS Code Server Issues

#### Problem: VS Code server installation fails

**Solution 1: Clear VS Code server cache**

```powershell
# Connect to VM and remove old server
ssh devbox "rm -rf ~/.vscode-server"

# Reconnect from VS Code
```

**Solution 2: Manual server download**

```bash
# On the VM
cd ~
wget https://update.code.visualstudio.com/latest/server-linux-x64/stable -O vscode-server.tar.gz
mkdir -p ~/.vscode-server/bin/latest
tar -xzf vscode-server.tar.gz -C ~/.vscode-server/bin/latest --strip-components=1
```

#### Problem: Extensions not working on remote

**Solutions:**

1. Check extension compatibility: Some extensions only work locally
2. Install extension on remote explicitly: Extensions panel > "Install in SSH: devbox"
3. Reload window: `Ctrl+Shift+P` > "Developer: Reload Window"

### Network Issues

#### Problem: IP address changes after VM restart

**Workaround 1: Set static IP**

Edit `devbox-config-v2.yaml` before launching VM to include network configuration.

**Workaround 2: Use dynamic connection**

Update SSH config to use multipass command:

```ssh-config
Host devbox
    HostName 172.29.10.254
    User devbox
    ProxyCommand multipass exec devbox -- nc -q0 localhost 22
```

**Workaround 3: Create PowerShell script to update config**

```powershell
# save as update-devbox-ip.ps1
$ip = (multipass info devbox | Select-String "IPv4:" | ForEach-Object { $_.ToString().Split()[1] })
$configPath = "$env:USERPROFILE\.ssh\config"
(Get-Content $configPath) -replace 'HostName.*', "HostName $ip" | Set-Content $configPath
Write-Host "Updated devbox IP to: $ip"
```

Run before connecting:

```powershell
.\update-devbox-ip.ps1
```

### Performance Issues

#### Problem: Slow file operations

**Solutions:**

1. Exclude large directories from file watcher (see Performance Tuning above)
2. Increase VM resources:

```powershell
# Stop VM first
multipass stop devbox

# Increase memory and CPUs
multipass set local.devbox.memory=4G
multipass set local.devbox.cpus=4

# Restart
multipass start devbox
```

3. Use Remote - Containers for better isolation

---

## Advanced Configuration

### Multiple VM Configurations

Add multiple VMs to SSH config:

```ssh-config
# Production-like environment
Host devbox-prod
    HostName 172.29.10.254
    User devbox
    IdentityFile C:\Users\s.tapia\.ssh\id_ed25519

# Testing environment
Host devbox-test
    HostName 172.29.10.255
    User devbox
    IdentityFile C:\Users\s.tapia\.ssh\id_ed25519
```

### Port Forwarding

Forward ports from VM to Windows:

```ssh-config
Host devbox
    HostName 172.29.10.254
    User devbox
    LocalForward 3000 localhost:3000  # Web server
    LocalForward 5432 localhost:5432  # PostgreSQL
    LocalForward 6379 localhost:6379  # Redis
```

Or forward dynamically in VS Code:

1. `Ctrl+Shift+P`
2. "Remote-SSH: Forward Port from Active Host"
3. Enter port number (e.g., 3000)
4. Access via `http://localhost:3000` on Windows

### SSH Agent Forwarding

To use Windows SSH keys on the VM (for Git operations):

1. Start SSH agent on Windows:

```powershell
# Start ssh-agent
Start-Service ssh-agent
Set-Service -Name ssh-agent -StartupType Automatic

# Add your key
ssh-add $env:USERPROFILE\.ssh\id_ed25519
```

2. Verify `ForwardAgent yes` in SSH config

3. Test on VM:

```bash
# Should show your Windows key
ssh-add -l
```

### VS Code Workspace for DevBox

Create a workspace file `devbox.code-workspace`:

```json
{
    "folders": [
        {
            "name": "Work Projects",
            "path": "vscode-remote://ssh-remote+devbox/home/devbox/code/work"
        },
        {
            "name": "Personal Projects",
            "path": "vscode-remote://ssh-remote+devbox/home/devbox/code/personal"
        }
    ],
    "settings": {
        "terminal.integrated.defaultProfile.linux": "bash",
        "git.enableSmartCommit": true
    }
}
```

Open workspace: `File > Open Workspace from File`

---

## Additional Resources

- [Official Multipass Documentation](https://documentation.ubuntu.com/multipass/stable/tutorial/)
- [VS Code Remote SSH Documentation](https://code.visualstudio.com/docs/remote/ssh)
- [DevBox Documentation](https://www.jetify.com/devbox/docs/)
- [Cloud-init Documentation](https://cloudinit.readthedocs.io/en/latest/)

---

## Quick Reference Commands

```powershell
# Multipass commands
multipass list                    # List all VMs
multipass info devbox            # Get VM info (including IP)
multipass start devbox           # Start VM
multipass stop devbox            # Stop VM
multipass restart devbox         # Restart VM
multipass shell devbox           # Open shell in VM

# SSH commands
ssh devbox                       # Connect to VM
ssh devbox "command"             # Run command on VM
ssh-copy-id devbox              # Copy SSH key to VM

# VS Code commands (in Command Palette)
Remote-SSH: Connect to Host      # Connect to remote
Remote-SSH: Open Configuration   # Edit SSH config
Remote-SSH: Kill VS Code Server  # Restart server on remote
```

---

## Support

If you encounter issues not covered in this guide:

1. Check multipass logs: `multipass exec devbox -- tail -f /var/log/cloud-init-output.log`
2. Check VS Code Remote logs: `Ctrl+Shift+P` > "Remote-SSH: Show Log"
3. Review SSH verbose output: `ssh -vvv devbox`

---

**Last updated:** 2025-11-11
**Tested with:** VS Code 1.95+, Multipass 1.14+, Windows 11

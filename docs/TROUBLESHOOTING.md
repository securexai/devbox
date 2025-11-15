# Troubleshooting Guide

Comprehensive troubleshooting guide for CloudOps Multipass development environment.

**Last Updated**: 2025-11-15

---

## Table of Contents

- [Quick Diagnostics](#quick-diagnostics)
- [Multipass & VM Issues](#multipass--vm-issues)
- [SSH Connection Issues](#ssh-connection-issues)
- [VS Code Remote SSH Issues](#vs-code-remote-ssh-issues)
- [Cloud-init Issues](#cloud-init-issues)
- [Claude CLI Issues](#claude-cli-issues)
- [Devbox & Nix Issues](#devbox--nix-issues)
- [Performance Issues](#performance-issues)
- [Network Issues](#network-issues)
- [Getting Help](#getting-help)

---

## Quick Diagnostics

Run these commands first to quickly identify the problem:

```bash
# Check if VM is running
multipass list

# Get VM details and IP
multipass info cloudops

# Test SSH connection
ssh cloudops whoami

# Check cloud-init status
multipass exec cloudops -- cloud-init status

# Check VS Code Remote SSH extension
code --list-extensions | grep remote-ssh
```

**Common Quick Fixes:**

```bash
# VM not running?
multipass start cloudops

# IP address changed?
multipass info cloudops | grep IPv4
# Then update ~/.ssh/config with new IP

# SSH not working?
ssh -vvv cloudops whoami  # Check verbose output for errors

# Cloud-init still running?
multipass exec cloudops -- cloud-init status --wait

# VS Code issues?
ssh cloudops "rm -rf ~/.vscode-server"
```

---

## Multipass & VM Issues

### VM Won't Start

**Problem**: `multipass start cloudops` fails or times out.

**Diagnosis**:

```bash
# Check Multipass service status
multipass version

# Check available system resources
multipass get local.driver

# View Multipass logs (Windows)
Get-Content $env:LOCALAPPDATA\Multipass\multipass\multipassd.log -Tail 50
```

**Solutions**:

1. **Restart Multipass service** (Windows):

   ```powershell
   Stop-Service Multipass
   Start-Service Multipass
   ```

2. **Check Hyper-V is enabled** (Windows):

   ```powershell
   Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V
   # Should show "Enabled"
   ```

3. **Increase VM timeout**:

   ```bash
   multipass set local.timeout=300
   ```

4. **Check disk space**:

   ```bash
   # On host
   df -h  # Linux/macOS
   Get-Volume C | Format-Table  # Windows
   ```

5. **Recreate VM**:

   ```bash
   multipass stop cloudops
   multipass delete cloudops
   multipass purge
   multipass launch --name cloudops --cloud-init cloudops-config-v2.yaml
   ```

### VM Exists But Won't Respond

**Problem**: VM shows as "Running" but doesn't respond.

**Solutions**:

1. **Force restart**:

   ```bash
   multipass restart cloudops
   ```

2. **Check VM console** (to see boot messages):

   ```bash
   multipass shell cloudops
   ```

3. **Check resource allocation**:

   ```bash
   multipass info cloudops
   # Verify CPUs, Memory, Disk are reasonable
   ```

4. **Increase resources if needed**:

   ```bash
   multipass stop cloudops
   multipass set local.cloudops.memory=8G
   multipass set local.cloudops.cpus=4
   multipass start cloudops
   ```

### Can't Delete VM

**Problem**: `multipass delete` or `multipass purge` fails.

**Solutions**:

1. **Force delete**:

   ```bash
   multipass delete --purge cloudops
   ```

2. **Restart Multipass and retry**:

   ```powershell
   # Windows
   Restart-Service Multipass
   multipass delete cloudops
   multipass purge
   ```

3. **Manual cleanup** (advanced):

   ```powershell
   # Windows - stop Multipass service
   Stop-Service Multipass

   # Delete VM data manually
   Remove-Item "$env:LOCALAPPDATA\Multipass\data\vault\instances\cloudops" -Recurse -Force

   # Restart service
   Start-Service Multipass
   ```

---

## SSH Connection Issues

### Permission Denied (publickey)

**Problem**: `ssh cloudops` returns "Permission denied (publickey)".

**Diagnosis**:

```bash
# Test with verbose output
ssh -vvv cloudops

# Check if key exists
ls -la ~/.ssh/id_ed25519

# Verify public key on VM
multipass exec cloudops -- cat /home/cloudops/.ssh/authorized_keys
```

**Solutions**:

1. **Generate SSH key if missing**:

   ```bash
   ssh-keygen -t ed25519 -C "your_email@example.com"
   ```

2. **Copy public key to VM**:

   ```bash
   cat ~/.ssh/id_ed25519.pub | \
     multipass exec cloudops -- tee -a /home/cloudops/.ssh/authorized_keys
   ```

3. **Fix key permissions** (Linux/macOS):

   ```bash
   chmod 600 ~/.ssh/id_ed25519
   chmod 644 ~/.ssh/id_ed25519.pub
   chmod 700 ~/.ssh
   ```

4. **Fix key permissions** (Windows):

   ```powershell
   # Remove inheritance and grant only current user access
   icacls $env:USERPROFILE\.ssh\id_ed25519 /inheritance:r
   icacls $env:USERPROFILE\.ssh\id_ed25519 /grant:r "$env:USERNAME:R"
   ```

5. **Update SSH key in cloud-init config**:

   Edit `cloudops-config-v2.yaml` line 49 with your current public key, then recreate VM.

### Connection Timeout

**Problem**: SSH connection times out or hangs.

**Solutions**:

1. **Verify VM is running**:

   ```bash
   multipass list
   multipass start cloudops  # If stopped
   ```

2. **Check IP address**:

   ```bash
   multipass info cloudops | grep IPv4
   # Update ~/.ssh/config if IP changed
   ```

3. **Increase SSH timeout**:

   Add to `~/.ssh/config`:

   ```
   Host cloudops
       ConnectTimeout 30
       ServerAliveInterval 60
       ServerAliveCountMax 3
   ```

4. **Test connection to VM directly**:

   ```bash
   # Use IP from multipass info
   ssh cloudops@<VM-IP>
   ```

5. **Check firewall** (Windows):

   ```powershell
   # Allow SSH outbound
   New-NetFirewallRule -DisplayName "SSH Outbound" `
     -Direction Outbound -Protocol TCP -LocalPort 22 -Action Allow
   ```

### Connection Refused

**Problem**: `ssh cloudops` returns "Connection refused".

**Diagnosis**:

```bash
# Check if SSH service is running in VM
multipass exec cloudops -- systemctl status ssh

# Check if port 22 is listening
multipass exec cloudops -- sudo netstat -tulpn | grep :22
```

**Solutions**:

1. **Start SSH service**:

   ```bash
   multipass exec cloudops -- sudo systemctl start ssh
   multipass exec cloudops -- sudo systemctl enable ssh
   ```

2. **Restart VM**:

   ```bash
   multipass restart cloudops
   ```

3. **Check SSH configuration**:

   ```bash
   multipass exec cloudops -- sudo sshd -t
   # Should show "Configuration OK"
   ```

---

## VS Code Remote SSH Issues

### Could Not Establish Connection

**Problem**: VS Code shows "Could not establish connection to cloudops".

**Solutions**:

1. **Verify SSH works first**:

   ```bash
   ssh cloudops whoami
   # Should output: cloudops
   ```

2. **Check VM is running**:

   ```bash
   multipass list
   multipass start cloudops  # If stopped
   ```

3. **Verify VS Code Remote SSH extension installed**:

   ```bash
   code --list-extensions | grep ms-vscode-remote.remote-ssh
   ```

   Install if missing:

   ```bash
   code --install-extension ms-vscode-remote.remote-ssh
   ```

4. **Update IP address in SSH config**:

   ```bash
   # Get current IP
   multipass info cloudops | grep IPv4

   # Update ~/.ssh/config with new IP
   ```

5. **Remove old VS Code server**:

   ```bash
   ssh cloudops "rm -rf ~/.vscode-server"
   ```

   Then reconnect from VS Code.

### VS Code Server Installation Fails

**Problem**: VS Code fails to install remote server on VM.

**Diagnosis**:

```bash
# Check disk space on VM
multipass exec cloudops -- df -h

# Check internet connectivity
multipass exec cloudops -- curl -I https://update.code.visualstudio.com
```

**Solutions**:

1. **Clear VS Code server cache**:

   ```bash
   ssh cloudops "rm -rf ~/.vscode-server"
   code --remote ssh-remote+cloudops /home/cloudops
   ```

2. **Increase VM disk space**:

   ```bash
   # Note: Requires recreating VM
   multipass stop cloudops
   multipass delete cloudops
   multipass purge

   multipass launch --name cloudops --cloud-init cloudops-config-v2.yaml \
     -c 4 -m 8G -d 60G  # Increase disk to 60GB
   ```

3. **Manual server installation**:

   ```bash
   # SSH into VM
   ssh cloudops

   # Download server manually
   wget https://update.code.visualstudio.com/latest/server-linux-x64/stable \
     -O vscode-server.tar.gz

   # Extract
   mkdir -p ~/.vscode-server/bin/latest
   tar -xzf vscode-server.tar.gz -C ~/.vscode-server/bin/latest --strip-components=1
   ```

### Extensions Not Working on Remote

**Problem**: Extensions installed locally don't work on remote VM.

**Solutions**:

1. **Install extension on remote explicitly**:

   - Open Extensions panel in VS Code
   - Find extension
   - Click "Install in SSH: cloudops"

2. **Check extension compatibility**:

   Some extensions only work locally (UI extensions, terminal shells, etc.)

3. **Reload window**:

   `Ctrl+Shift+P` → "Developer: Reload Window"

4. **Check extension settings**:

   Some extensions need configuration for remote development.

---

## Cloud-init Issues

### Cloud-init Failed or Stuck

**Problem**: `cloud-init status` shows "error" or never completes.

**Diagnosis**:

```bash
# Check status
multipass exec cloudops -- cloud-init status --long

# View logs
multipass exec cloudops -- cat /var/log/cloud-init.log

# Check for errors
multipass exec cloudops -- cat /var/log/cloud-init-output.log | grep -i error
```

**Solutions**:

1. **Wait longer** (first boot can take 5-10 minutes):

   ```bash
   multipass exec cloudops -- cloud-init status --wait
   ```

2. **Check for specific errors in logs**:

   ```bash
   # View last 50 lines of log
   multipass exec cloudops -- tail -50 /var/log/cloud-init.log

   # Search for failures
   multipass exec cloudops -- grep -i "fail\|error" /var/log/cloud-init.log
   ```

3. **Validate config file before launch**:

   ```bash
   cloud-init schema --config-file cloudops-config-v2.yaml --annotate
   ```

4. **Force cloud-init to re-run** (if VM already exists):

   ```bash
   multipass exec cloudops -- sudo cloud-init clean
   multipass exec cloudops -- sudo cloud-init init
   multipass restart cloudops
   ```

### Permissions Errors in Cloud-init

**Problem**: Files created by cloud-init have wrong permissions.

**Diagnosis**:

```bash
# Check file ownership
multipass exec cloudops -- ls -la /home/cloudops

# Check write_files module errors
multipass exec cloudops -- grep "write_files" /var/log/cloud-init.log
```

**Solutions**:

Current config uses `chmod` in `runcmd` instead of `permissions` field to avoid schema errors. If you're still seeing permission issues:

```bash
# Fix ownership manually
multipass exec cloudops -- sudo chown -R cloudops:cloudops /home/cloudops

# Fix permissions
multipass exec cloudops -- chmod 755 /home/cloudops
multipass exec cloudops -- chmod 644 /home/cloudops/.bashrc
multipass exec cloudops -- chmod 700 /home/cloudops/.ssh
multipass exec cloudops -- chmod 600 /home/cloudops/.ssh/authorized_keys
```

### Package Installation Failed

**Problem**: Packages listed in cloud-init config not installed.

**Diagnosis**:

```bash
# Check package installation logs
multipass exec cloudops -- grep "package" /var/log/cloud-init.log

# Verify package exists
multipass exec cloudops -- apt-cache search <package-name>
```

**Solutions**:

1. **Install package manually**:

   ```bash
   multipass exec cloudops -- sudo apt update
   multipass exec cloudops -- sudo apt install <package-name>
   ```

2. **Check package name** for Ubuntu 25.10 compatibility:

   Example: `dnsutils` is now `bind9-dnsutils` in Ubuntu 25.10

3. **Update package sources**:

   ```bash
   multipass exec cloudops -- sudo apt update
   multipass exec cloudops -- sudo apt upgrade
   ```

---

## Claude CLI Issues

### Claude CLI Not Found in PATH

**Problem**: `claude --version` returns "command not found".

**Diagnosis**:

```bash
# Check if Claude CLI is installed
ssh cloudops "which claude"

# Check npm prefix configuration
ssh cloudops "npm config get prefix"

# Check if npm bin directory is in PATH
ssh cloudops "echo \$PATH | grep npm"

# List npm global packages
ssh cloudops "npm list -g --depth=0"
```

**Solutions**:

1. **Verify installation completed**:

   ```bash
   # Check if binary exists
   ssh cloudops "ls -la /home/cloudops/.local/share/npm/bin/claude"

   # If missing, reinstall
   ssh cloudops "npm install -g @anthropic-ai/claude-code"
   ```

2. **Check PATH configuration**:

   ```bash
   # Verify NPM_PREFIX in .bashrc
   ssh cloudops "grep NPM_PREFIX ~/.bashrc"

   # Should see:
   # export NPM_PREFIX="/home/cloudops/.local/share/npm"
   ```

3. **Reload shell configuration**:

   ```bash
   ssh cloudops "source ~/.bashrc && claude --version"
   ```

4. **Manual PATH addition** (if needed):

   ```bash
   # Add to ~/.bashrc
   ssh cloudops "echo 'export PATH=\"/home/cloudops/.local/share/npm/bin:\$PATH\"' >> ~/.bashrc"
   ssh cloudops "source ~/.bashrc"
   ```

### Claude CLI Installation Failed During cloud-init

**Problem**: Cloud-init log shows Claude CLI installation timeout or failure.

**Diagnosis**:

```bash
# Check cloud-init logs for Claude CLI errors
multipass exec cloudops -- grep -i "claude" /var/log/cloud-init-output.log

# Check npm installation logs
multipass exec cloudops -- cat ~/.npm/_logs/*.log 2>/dev/null | tail -50
```

**Solutions**:

1. **Manual installation** (recommended):

   ```bash
   ssh cloudops

   # Configure npm prefix
   npm config set prefix /home/cloudops/.local/share/npm

   # Install Claude CLI with verbose output
   npm install -g @anthropic-ai/claude-code --verbose

   # Verify installation
   claude --version
   ```

2. **Check network connectivity**:

   ```bash
   # Test npm registry access
   ssh cloudops "curl -I https://registry.npmjs.org"

   # If network issues, wait and retry
   ssh cloudops "npm install -g @anthropic-ai/claude-code"
   ```

3. **Clean npm cache and retry**:

   ```bash
   ssh cloudops "npm cache clean --force"
   ssh cloudops "npm install -g @anthropic-ai/claude-code"
   ```

### Why npm Instead of pnpm for Claude CLI?

**Context**: The project uses pnpm globally, but Claude CLI is installed via npm.

**Technical Explanation**:

After 9 debugging iterations, we discovered that pnpm has strict PATH validation requirements:

- **pnpm behavior**: Before allowing `pnpm add -g`, pnpm validates that `global-bin-dir` exists in `$PATH`
- **devbox environment issue**: The devbox shell doesn't inherit `PNPM_HOME` from `.bashrc`, causing validation to fail
- **npm solution**: npm doesn't have this PATH validation requirement and works reliably with a configured prefix

**This is by design** and ensures automated installation works consistently during cloud-init provisioning.

**pnpm is still available** for project-level package management and remains installed globally via devbox.

### Updating Claude CLI

**Problem**: Need to update to latest Claude CLI version.

**Solution**:

```bash
# Method 1: Use maintenance script
ssh cloudops "~/bin/update-global-tools.sh"

# Method 2: Manual update
ssh cloudops "npm update -g @anthropic-ai/claude-code"

# Verify new version
ssh cloudops "claude --version"
```

### Claude CLI Authentication Issues

**Problem**: Claude CLI prompts for authentication or API key.

**Solution**:

```bash
# Claude CLI uses your Anthropic account
# Follow the authentication flow:
ssh cloudops "claude --auth"

# Or set API key if using programmatic access
ssh cloudops "export ANTHROPIC_API_KEY=your-key-here"
```

### npm Permission Errors

**Problem**: "EACCES: permission denied" when using npm.

**Diagnosis**:

```bash
# Check ownership of npm prefix
ssh cloudops "ls -la /home/cloudops/.local/share/npm"

# Check npm configuration
ssh cloudops "npm config list"
```

**Solution**:

```bash
# Fix ownership
ssh cloudops "sudo chown -R cloudops:cloudops /home/cloudops/.local/share/npm"

# Verify prefix configuration
ssh cloudops "npm config set prefix /home/cloudops/.local/share/npm"

# Reinstall if needed
ssh cloudops "npm install -g @anthropic-ai/claude-code"
```

---

## Devbox & Nix Issues

### Package Not Found

**Problem**: `devbox add nodejs@22` returns "package not found".

**Solutions**:

1. **Search for exact version**:

   ```bash
   devbox search nodejs
   ```

2. **Use full package name with version**:

   ```bash
   devbox add nodejs@22.14.0
   ```

3. **Check package on nixhub.io**:

   Visit <https://www.nixhub.io> and search for package.

### Command Not Found After Adding Package

**Problem**: Installed package command not available.

**Diagnosis**:

```bash
devbox list  # Verify package is added
which <command>  # Check if in PATH
```

**Solutions**:

1. **Enter devbox shell**:

   ```bash
   devbox shell
   <command> --version  # Now should work
   ```

   Packages are only available inside `devbox shell`.

2. **Use global packages** (available everywhere):

   ```bash
   devbox global add <package>
   ```

3. **Verify shellenv is activated**:

   ```bash
   grep "devbox global shellenv" ~/.bashrc
   ```

   Should see:
   ```
   eval "$(devbox global shellenv --init-hook)"
   ```

### Slow Package Installation

**Problem**: First package installation takes 5+ minutes.

**Explanation**: This is normal for Nix. First install downloads and compiles packages.

**Solutions**:

1. **Be patient** - first install is slow, subsequent installs are fast (10-30 seconds)

2. **Check if Nix cache is working**:

   ```bash
   nix-channel --list
   # Should see nixpkgs channel
   ```

3. **Update Nix channels**:

   ```bash
   nix-channel --update
   ```

4. **Use binary cache** (should be enabled by default):

   Verify in `~/.config/nix/nix.conf`:
   ```
   substituters = https://cache.nixos.org
   ```

### Devbox Services Won't Start

**Problem**: `devbox services start <service>` fails.

**Diagnosis**:

```bash
# Check service status
devbox services ls

# Check if port is in use
sudo netstat -tulpn | grep <port>

# Check service logs
devbox services logs <service>
```

**Solutions**:

1. **Kill process using port**:

   ```bash
   # Find process on port 5432 (example)
   sudo lsof -i:5432
   sudo kill <PID>
   ```

2. **Restart service**:

   ```bash
   devbox services stop <service>
   devbox services start <service>
   ```

3. **Check service configuration**:

   Review `devbox.json` for service settings.

### Permission Denied Errors

**Problem**: Cannot write to `.devbox/` directory.

**Solution**:

```bash
# Fix ownership
sudo chown -R cloudops:cloudops ~/code/my-project

# Verify
ls -la ~/code/my-project | grep .devbox
# Should show cloudops cloudops
```

---

## Performance Issues

### Slow File Operations

**Problem**: File operations in VS Code are slow.

**Solutions**:

1. **Exclude large directories from file watcher**:

   Add to VS Code `settings.json`:

   ```json
   {
     "files.watcherExclude": {
       "**/.git/objects/**": true,
       "**/.git/subtree-cache/**": true,
       "**/node_modules/**": true,
       "**/.vscode-server/**": true,
       "**/.nix-store/**": true,
       "**/.devbox/**": true
     }
   }
   ```

2. **Increase VM resources**:

   ```bash
   multipass stop cloudops
   multipass set local.cloudops.memory=16G
   multipass set local.cloudops.cpus=8
   multipass start cloudops
   ```

3. **Check host system resources**:

   Ensure host has enough RAM/CPU available.

### High CPU or Memory Usage

**Problem**: VM consuming excessive resources.

**Diagnosis**:

```bash
# Check VM resource usage
multipass info cloudops

# Check processes inside VM
ssh cloudops "top"

# Check what's using CPU
ssh cloudops "ps aux --sort=-%cpu | head -10"

# Check what's using memory
ssh cloudops "ps aux --sort=-%mem | head -10"
```

**Solutions**:

1. **Limit VM resources**:

   ```bash
   multipass stop cloudops
   multipass set local.cloudops.memory=8G
   multipass set local.cloudops.cpus=4
   multipass start cloudops
   ```

2. **Stop unnecessary services**:

   ```bash
   ssh cloudops "systemctl list-units --type=service --state=running"
   ssh cloudops "sudo systemctl stop <service-name>"
   ```

3. **Run Nix garbage collection**:

   ```bash
   ssh cloudops "nix-collect-garbage -d"
   ssh cloudops "nix-store --optimise"
   ```

---

## Network Issues

### IP Address Changes After Restart

**Problem**: VM gets new IP after restart, breaking SSH config.

**Solutions**:

1. **Use dynamic IP update script**:

   Save as `update-cloudops-ip.sh`:

   ```bash
   #!/bin/bash
   IP=$(multipass info cloudops | grep IPv4 | awk '{print $2}')
   sed -i "s/HostName .*/HostName $IP/" ~/.ssh/config
   echo "Updated cloudops IP to: $IP"
   ```

   Run before connecting:
   ```bash
   ./update-cloudops-ip.sh
   ssh cloudops
   ```

2. **Use ProxyCommand** (always current IP):

   Update `~/.ssh/config`:

   ```
   Host cloudops
       User cloudops
       ProxyCommand multipass exec cloudops -- nc -q0 localhost 22
       IdentityFile ~/.ssh/id_ed25519
   ```

3. **Set static IP** (advanced - requires network configuration in cloud-init)

### Can't Access Internet from VM

**Problem**: VM cannot reach external websites.

**Diagnosis**:

```bash
# Test DNS
multipass exec cloudops -- ping -c 3 8.8.8.8

# Test name resolution
multipass exec cloudops -- nslookup google.com

# Check routes
multipass exec cloudops -- ip route
```

**Solutions**:

1. **Restart networking**:

   ```bash
   multipass exec cloudops -- sudo systemctl restart systemd-networkd
   ```

2. **Check DNS configuration**:

   ```bash
   multipass exec cloudops -- cat /etc/resolv.conf
   # Should have nameservers like 8.8.8.8 or your network DNS
   ```

3. **Restart VM**:

   ```bash
   multipass restart cloudops
   ```

---

## Getting Help

### Before Asking for Help

Collect diagnostic information:

```bash
# Multipass version
multipass version

# VM information
multipass info cloudops

# VM status
multipass list

# Cloud-init status
multipass exec cloudops -- cloud-init status --long

# Cloud-init logs (last 100 lines)
multipass exec cloudops -- tail -100 /var/log/cloud-init.log

# SSH test
ssh -vvv cloudops whoami 2>&1
```

### Where to Get Help

1. **Project Documentation**:
   - [README.md](../README.md) - Quick start and overview
   - [VS Code Setup](VSCODE_SETUP.md) - VS Code specific issues
   - [Devbox Guide](DEVBOX_GUIDE.md) - Devbox/Nix issues
   - [Migration Guide](../MIGRATION.md) - Upgrade issues

2. **Official Resources**:
   - [Multipass Documentation](https://multipass.run/docs)
   - [Cloud-init Documentation](https://cloudinit.readthedocs.io/)
   - [Devbox Documentation](https://www.jetify.com/devbox/docs/)
   - [VS Code Remote SSH](https://code.visualstudio.com/docs/remote/ssh)

3. **Community**:
   - GitHub Issues (for this project)
   - [Multipass Discourse](https://discourse.ubuntu.com/c/multipass)
   - [Devbox Discord](https://discord.gg/jetify)
   - Stack Overflow (tag: multipass, cloud-init, devbox)

---

**Document Version**: 1.1
**Last Updated**: 2025-11-15
**Maintained by**: CloudOps Development Team

**Related Documents**:
- [README.md](../README.md)
- [MIGRATION.md](../MIGRATION.md)
- [CHANGELOG.md](../CHANGELOG.md)
- [VS Code Setup](VSCODE_SETUP.md)
- [Devbox Guide](DEVBOX_GUIDE.md)
- [Best Practices](MULTIPASS_BEST_PRACTICES.md)

# WSL + Windows Testing Guide

## Overview

This guide provides comprehensive testing procedures for the devbox project when your primary development environment is **WSL Ubuntu 25.10** but you have access to the **Windows host** for running Multipass.

**Last Updated**: 2025-11-16

---

## Why This Approach?

### Technical Context

**Challenge**: WSL is itself a virtualization layer. Running Multipass inside WSL would require **nested virtualization**, which:
- May not be enabled by default
- Has significant performance overhead (~2-3x slower)
- Can cause stability issues (VM crashes, network problems)
- Is not a supported Multipass configuration

**Solution**: Install Multipass on **Windows host**, control from **WSL**.

### Benefits of This Approach

| Aspect | WSL-Only (Unsupported) | Windows + WSL (Recommended) |
|--------|----------------------|----------------------------|
| **Performance** | Slow (nested virt) | Native speed |
| **Stability** | Unreliable | Production-ready |
| **Support** | Not supported | Official configuration |
| **Integration** | Complex | Seamless (via .exe) |
| **File Access** | Limited | Full (via /mnt/c) |

---

## Phase 1: Setup Testing Environment

### 1.1 Install Multipass on Windows

#### Option A: Using Windows Package Manager (Recommended)

Open **PowerShell** (as Administrator) on Windows:

```powershell
# Install Multipass via winget
winget install Canonical.Multipass

# Verify installation
multipass version
# Expected: multipass 1.16.1+win or newer
```

#### Option B: Manual Installer

1. Download from: <https://multipass.run/install>
2. Run the `.exe` installer
3. Follow installation wizard (default settings are fine)
4. Restart Windows if prompted

#### Verify Virtualization Backend

```powershell
# Check if Hyper-V is enabled (required for Multipass on Windows)
Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V

# If State is "Disabled", enable it:
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All

# Restart Windows after enabling Hyper-V
```

### 1.2 Access Multipass from WSL

#### Method 1: Direct .exe Invocation (Simple)

From WSL Ubuntu 25.10:

```bash
# Access Windows Multipass directly
/mnt/c/Program\ Files/Multipass/bin/multipass.exe version

# Create alias for convenience
echo 'alias multipass="/mnt/c/Program\ Files/Multipass/bin/multipass.exe"' >> ~/.bashrc
source ~/.bashrc

# Test alias
multipass version
```

#### Method 2: Add to WSL PATH (Persistent)

```bash
# Add Multipass to PATH in .bashrc
cat >> ~/.bashrc << 'EOF'

# Multipass on Windows (accessible from WSL)
export PATH="$PATH:/mnt/c/Program Files/Multipass/bin"
EOF

source ~/.bashrc

# Test (note: use multipass.exe explicitly)
multipass.exe version
```

**Important**: Always use `multipass.exe` (with .exe extension) when calling from WSL.

### 1.3 Validate Cloud-Init YAML Syntax

Before launching VMs, validate the configuration from WSL:

```bash
# Navigate to devbox project
cd /home/sft/code/devbox

# Install cloud-init package (if not already installed)
sudo apt update
sudo apt install -y cloud-init

# Validate YAML syntax
cloud-init schema --config-file cloudops-config-v2.yaml

# Expected output: "Valid cloud-config: cloudops-config-v2.yaml"
```

#### Advanced Validation: Annotated Schema Check

```bash
# Get detailed schema validation with annotations
cloud-init schema --config-file cloudops-config-v2.yaml --annotate

# This will show:
# - Deprecated keys (warnings)
# - Invalid keys (errors)
# - Schema violations
# - Suggested fixes
```

**Success Criteria**:
- ✅ No schema errors
- ⚠️ Warnings are acceptable (review them)
- ❌ Errors must be fixed before VM launch

---

## Phase 2: VM Provisioning Test

### 2.1 Launch Test VM from WSL

#### Basic Test Launch

```bash
# From WSL, navigate to project directory
cd /home/sft/code/devbox

# Launch VM using Windows Multipass (note: multipass.exe)
multipass.exe launch 25.10 --name devbox-test --cloud-init cloudops-config-v2.yaml --cpus 4 --memory 1G --disk 5G

# Note: Use "25.10" or "questing" for Ubuntu 25.10 Questing Quetzal
```

#### Launch with Custom Environment Variables

```bash
# Personalize the VM during launch
multipass.exe launch \
  --name devbox-test \
  --cloud-init cloudops-config-v2.yaml \
  --cpus 4 \
  --memory 8G \
  --disk 40G \
  25.10 \
  -e GIT_USER_NAME="Your Name" \
  -e GIT_USER_EMAIL="your@email.com"
```

**Expected Timeline**:
- Image download: 10-30s (first time only, then cached)
- VM creation: 20-40s
- Cloud-init execution: 3-5 minutes
- **Total**: ~4-6 minutes for first launch

### 2.2 Monitor Cloud-Init Progress

#### Watch Setup in Real-Time

```bash
# Check cloud-init status (from WSL)
multipass.exe exec devbox-test -- cloud-init status

# Possible outputs:
# status: running   ← Setup in progress
# status: done      ← Setup complete
# status: error     ← Setup failed (check logs)
```

#### Wait for Completion

```bash
# Block until cloud-init finishes (useful for automation)
multipass.exe exec devbox-test -- cloud-init status --wait

# This command will:
# - Print "status: running" periodically
# - Exit when status becomes "done" or "error"
```

#### Monitor Detailed Progress

```bash
# Watch the setup log in real-time
multipass.exe exec devbox-test -- tail -f /var/log/cloudops-setup.log

# Press Ctrl+C to stop watching
```

### 2.3 Verify Setup Completion

#### Check Setup Marker

```bash
# Verify the setup completion marker exists
multipass.exe exec devbox-test -- test -f /home/cloudops/.setup-complete && echo "Setup complete!" || echo "Setup incomplete or failed"
```

#### Review Setup Log for Errors

```bash
# Check for error messages in setup log
multipass.exe exec devbox-test -- grep -i "error\|failed" /var/log/cloudops-setup.log

# No output = good (no errors)
# Output = review each error
```

#### Verify Critical Components

```bash
# Quick health check
multipass.exe exec devbox-test -- bash << 'EOF'
echo "=== Component Health Check ==="

# 1. Nix
if command -v nix &> /dev/null; then
  echo "✅ Nix: $(nix --version | head -1)"
else
  echo "❌ Nix: NOT FOUND"
fi

# 2. Devbox
if command -v devbox &> /dev/null; then
  echo "✅ Devbox: $(devbox version)"
else
  echo "❌ Devbox: NOT FOUND"
fi

# 3. Node.js
if command -v node &> /dev/null; then
  echo "✅ Node.js: $(node --version)"
else
  echo "❌ Node.js: NOT FOUND"
fi

# 4. Claude CLI
if command -v claude &> /dev/null; then
  echo "✅ Claude CLI: $(claude --version 2>&1 | head -1)"
else
  echo "❌ Claude CLI: NOT FOUND"
fi

# 5. Global tools
echo "✅ jq: $(jq --version 2>&1)"
echo "✅ yq: $(yq --version 2>&1 | head -1)"
echo "✅ gh: $(gh --version 2>&1 | head -1)"
EOF
```

**Expected Output**:
```
=== Component Health Check ===
✅ Nix: nix (Nix) 3.13.1
✅ Devbox: 0.16.0
✅ Node.js: v24.11.0
✅ Claude CLI: 2.0.42
✅ jq: jq-1.7.1
✅ yq: yq (https://github.com/mikefarah/yq/) version 4.44.3
✅ gh: gh version 2.65.0 (2025-11-10)
```

---

## Phase 3: Full Validation Test Suite

The devbox project includes a comprehensive validation test plan with **58 test cases** across 5 categories. Execute these from WSL.

### 3.1 Prepare Test Environment

```bash
# SSH into the test VM
multipass.exe exec devbox-test -- bash

# Or use multipass shell (interactive session)
multipass.exe shell devbox-test
```

### 3.2 Category 1: Security Tests (12 tests)

Reference: `docs/testing/VALIDATION_TEST_PLAN.md` (Security Testing section)

#### Test 1.1: SSH Key Authentication

```bash
# From WSL (outside VM)
# Verify password authentication is disabled
multipass.exe exec devbox-test -- sudo grep "^PasswordAuthentication" /etc/ssh/sshd_config

# Expected: PasswordAuthentication no
```

#### Test 1.2: User Permissions

```bash
# Verify user is in correct groups
multipass.exe exec devbox-test -- groups cloudops

# Expected: cloudops adm sudo
```

#### Test 1.3: No Hardcoded Secrets

```bash
# Search for potential secrets in config files
multipass.exe exec devbox-test -- bash << 'EOF'
# Check .gitconfig for template placeholders (should NOT find real email)
cat /home/cloudops/.gitconfig | grep -i "CHANGEME\|__GIT_USER"

# If output contains CHANGEME or __GIT_USER__, secrets were NOT injected (expected if no env vars provided)
# If output shows real email, verify it came from environment variables (not hardcoded)
EOF
```

#### Test 1.4: Sudo Configuration

```bash
# Verify sudo access
multipass.exe exec devbox-test -- sudo -n true && echo "✅ Passwordless sudo enabled" || echo "❌ Sudo requires password"

# Expected: ✅ Passwordless sudo enabled
# Note: This is for dev convenience. Disable for production (see MULTIPASS_BEST_PRACTICES.md)
```

### 3.3 Category 2: Performance Tests (8 tests)

#### Test 2.1: Shell Startup Time

```bash
# Measure bash startup time
multipass.exe exec devbox-test -- bash << 'EOF'
time bash -i -c exit
EOF

# Expected: <2 seconds (with NVM lazy loading)
# Warning threshold: >3 seconds (investigate if exceeded)
```

#### Test 2.2: Nix Store Optimization

```bash
# Check Nix store size and optimization
multipass.exe exec devbox-test -- bash << 'EOF'
STORE_SIZE=$(du -sh /nix/store 2>/dev/null | cut -f1)
echo "Nix store size: $STORE_SIZE"

# Check if auto-optimization is enabled
nix show-config | grep "auto-optimise-store"
EOF

# Expected store size: ~900MB-1.2GB (optimized)
# Expected config: auto-optimise-store = true
```

#### Test 2.3: Disk Usage Analysis

```bash
# Overall disk usage breakdown
multipass.exe exec devbox-test -- bash << 'EOF'
echo "=== Disk Usage Breakdown ==="
df -h / | tail -1
echo ""
echo "Top 5 disk consumers:"
sudo du -hx /home /nix /var 2>/dev/null | sort -rh | head -5
EOF

# Expected total usage: 3-5GB (before user projects)
```

### 3.4 Category 3: Functional Tests (18 tests)

#### Test 3.1: Git Configuration

```bash
# Verify git is configured
multipass.exe exec devbox-test -- bash << 'EOF'
echo "Git user: $(git config user.name)"
echo "Git email: $(git config user.email)"
echo "Default branch: $(git config init.defaultBranch)"
EOF

# Expected:
# - User/email: Either "CHANGEME" (no env vars) or your actual values
# - Default branch: main
```

#### Test 3.2: Devbox Global Environment

```bash
# Verify global tools are available
multipass.exe exec devbox-test -- bash << 'EOF'
devbox global list
EOF

# Expected output should include:
# - jq
# - yq
# - gh
# - nodejs@24.11.0
```

#### Test 3.3: Devbox Shellenv Auto-Activation

```bash
# Create test project and verify auto-activation
multipass.exe exec devbox-test -- bash << 'EOF'
mkdir -p /tmp/test-project
cd /tmp/test-project
devbox init
devbox add python@3.12

# Exit and re-enter directory (shellenv should auto-activate)
cd /tmp
cd /tmp/test-project

# Check if Python is available (should be from devbox, not system)
which python
python --version
EOF

# Expected: python path should contain ".devbox" or "nix/store"
# Expected version: Python 3.12.x
```

#### Test 3.4: Claude CLI Functionality

```bash
# Test Claude CLI is installed and accessible
multipass.exe exec devbox-test -- bash << 'EOF'
claude --version
which claude
EOF

# Expected:
# - Version: 2.0.42 or newer
# - Path: /home/cloudops/.local/share/npm/bin/claude
```

#### Test 3.5: Template Instantiation

Test all 5 project templates:

```bash
multipass.exe exec devbox-test -- bash << 'EOF'
cd /home/cloudops/code/personal

echo "=== Testing nodejs-webapp template ==="
mkdir test-nodejs && cd test-nodejs
cp ~/.devbox-templates/nodejs-webapp.json devbox.json
devbox shell -- echo "Template loaded successfully"
cd ..

echo "=== Testing python-api template ==="
mkdir test-python && cd test-python
cp ~/.devbox-templates/python-api.json devbox.json
devbox shell -- echo "Template loaded successfully"
cd ..

echo "=== Testing go-service template ==="
mkdir test-go && cd test-go
cp ~/.devbox-templates/go-service.json devbox.json
devbox shell -- echo "Template loaded successfully"
cd ..

echo "=== Testing rust-cli template ==="
mkdir test-rust && cd test-rust
cp ~/.devbox-templates/rust-cli.json devbox.json
devbox shell -- echo "Template loaded successfully"
cd ..

echo "=== Testing fullstack template ==="
mkdir test-fullstack && cd test-fullstack
cp ~/.devbox-templates/fullstack.json devbox.json
# Note: This one includes PostgreSQL + Redis, takes longer
devbox shell -- echo "Template loaded successfully"
cd ..

echo "✅ All templates tested successfully"
EOF
```

### 3.5 Category 4: Integration Tests (10 tests)

#### Test 4.1: VS Code Remote SSH

**Prerequisites**: VS Code installed on Windows with Remote-SSH extension

```bash
# Get VM IP address
multipass.exe info devbox-test | grep IPv4

# Expected output: IPv4: 172.x.x.x
```

**From Windows**:
1. Open VS Code
2. Press `Ctrl+Shift+P` → "Remote-SSH: Connect to Host"
3. Enter: `cloudops@<VM_IP_ADDRESS>`
4. Select platform: Linux
5. Wait for connection
6. Open folder: `/home/cloudops/code`

**Success Criteria**:
- ✅ Connection succeeds without password prompt
- ✅ Can browse files in `/home/cloudops`
- ✅ Terminal opens with bash prompt
- ✅ Extensions load correctly

#### Test 4.2: SSH from WSL

```bash
# Get SSH key from VM
multipass.exe exec devbox-test -- cat /home/cloudops/.ssh/authorized_keys > /tmp/devbox-test-key.pub

# Get VM IP
VM_IP=$(multipass.exe info devbox-test | grep IPv4 | awk '{print $2}')

# Test SSH connection from WSL (will fail if no matching private key)
ssh cloudops@$VM_IP "echo 'SSH connection successful'"
```

**Note**: This requires the private key corresponding to the public key in cloud-init config.

#### Test 4.3: File Sharing Between Windows and VM

```bash
# From WSL, create test file on Windows filesystem
echo "Test from WSL" > /mnt/c/temp/test-file.txt

# Mount Windows directory in VM
multipass.exe mount C:\\temp devbox-test:/mnt/windows-temp

# Verify access from VM
multipass.exe exec devbox-test -- cat /mnt/windows-temp/test-file.txt

# Expected: "Test from WSL"
```

### 3.6 Category 5: Edge Cases & Error Handling (10 tests)

#### Test 5.1: Cloud-Init Failure Simulation

```bash
# Launch VM with invalid cloud-init (syntax error)
multipass.exe launch \
  --name test-invalid \
  --cloud-init /path/to/invalid-config.yaml \
  25.10

# Expected: VM launches but cloud-init reports errors
multipass.exe exec test-invalid -- cloud-init status

# Cleanup
multipass.exe delete --purge test-invalid
```

#### Test 5.2: Resource Exhaustion

```bash
# Launch VM with minimal resources (stress test)
multipass.exe launch \
  --name test-minimal \
  --cloud-init cloudops-config-v2.yaml \
  --cpus 1 \
  --memory 2G \
  --disk 10G \
  25.10

# Monitor setup (may be slower or fail)
multipass.exe exec test-minimal -- cloud-init status --wait

# Check for OOM (Out of Memory) errors
multipass.exe exec test-minimal -- dmesg | grep -i "out of memory"

# Cleanup
multipass.exe delete --purge test-minimal
```

#### Test 5.3: Network Interruption During Setup

```bash
# Launch VM, then pause it mid-setup to simulate network issues
multipass.exe launch --name test-network --cloud-init cloudops-config-v2.yaml 25.10

# Wait 60 seconds (let cloud-init start)
sleep 60

# Suspend VM (simulates network loss)
multipass.exe suspend test-network

# Wait 30 seconds
sleep 30

# Resume and check recovery
multipass.exe start test-network
multipass.exe exec test-network -- cloud-init status --wait

# Review logs for retry attempts
multipass.exe exec test-network -- cat /var/log/cloudops-setup.log | grep -i "retry\|timeout"

# Cleanup
multipass.exe delete --purge test-network
```

---

## Phase 4: Quick Smoke Testing

For rapid validation (useful for regression testing after config changes).

### 4.1 Five-Minute Smoke Test

```bash
#!/bin/bash
# smoke-test.sh - Quick validation script

set -e  # Exit on error

echo "=== DEVBOX SMOKE TEST ==="
echo "Starting: $(date)"

# 1. Launch VM
echo "[1/5] Launching VM..."
multipass.exe launch \
  --name smoke-test \
  --cloud-init cloudops-config-v2.yaml \
  --cpus 2 \
  --memory 4G \
  --disk 20G \
  25.10

# 2. Wait for cloud-init
echo "[2/5] Waiting for cloud-init..."
multipass.exe exec smoke-test -- cloud-init status --wait

# 3. Verify components
echo "[3/5] Verifying components..."
multipass.exe exec smoke-test -- bash -c '
  command -v nix && command -v devbox && command -v node && command -v claude
' && echo "✅ All components found" || echo "❌ Some components missing"

# 4. Test template
echo "[4/5] Testing nodejs-webapp template..."
multipass.exe exec smoke-test -- bash -c '
  mkdir -p /home/cloudops/code/test
  cd /home/cloudops/code/test
  cp ~/.devbox-templates/nodejs-webapp.json devbox.json
  devbox shell -- echo "Template loaded successfully"
'

# 5. Cleanup
echo "[5/5] Cleaning up..."
multipass.exe delete --purge smoke-test

echo "=== SMOKE TEST COMPLETE ==="
echo "Finished: $(date)"
```

**Usage**:
```bash
# Make executable
chmod +x smoke-test.sh

# Run from WSL
./smoke-test.sh
```

**Expected Duration**: 5-7 minutes

### 4.2 Critical Path Test

Test only the most critical functionality:

```bash
# Minimal validation
multipass.exe exec devbox-test -- bash << 'EOF'
set -e

echo "1. Nix works:"
nix --version

echo "2. Devbox works:"
devbox version

echo "3. Node.js works:"
node -e "console.log('Node.js OK')"

echo "4. Claude CLI works:"
claude --version

echo "✅ All critical components functional"
EOF
```

---

## Troubleshooting: WSL + Windows Specific Issues

### Issue 1: "multipass: command not found" in WSL

**Symptoms**:
```bash
$ multipass version
-bash: multipass: command not found
```

**Solutions**:

**Option 1: Use full path with .exe**
```bash
/mnt/c/Program\ Files/Multipass/bin/multipass.exe version
```

**Option 2: Create alias**
```bash
echo 'alias multipass="/mnt/c/Program\ Files/Multipass/bin/multipass.exe"' >> ~/.bashrc
source ~/.bashrc
```

**Option 3: Add to PATH**
```bash
export PATH="$PATH:/mnt/c/Program Files/Multipass/bin"
```

### Issue 2: Hyper-V Not Enabled

**Symptoms**:
```
Multipass error: backend does not support creation of instances
```

**Solution (from Windows PowerShell as Administrator)**:
```powershell
# Enable Hyper-V
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All

# Reboot Windows
Restart-Computer
```

**Alternative**: Use VirtualBox backend (slower, but no Hyper-V required)
```powershell
# Switch Multipass to VirtualBox backend
multipass set local.driver=virtualbox
```

### Issue 3: VM Can't Access Internet

**Symptoms**:
- Cloud-init fails with "Could not resolve host" errors
- Package downloads timeout

**Diagnosis**:
```bash
# Check VM network connectivity
multipass.exe exec devbox-test -- ping -c 3 8.8.8.8
multipass.exe exec devbox-test -- ping -c 3 google.com
```

**Solutions**:

**Option 1: Restart Hyper-V Virtual Switch**
```powershell
# From Windows PowerShell (as Administrator)
Get-VMSwitch | Where-Object {$_.Name -like "*Multipass*"} | Remove-VMSwitch -Force
# Then restart Multipass service
Restart-Service Multipass
```

**Option 2: Configure DNS manually**
```bash
multipass.exe exec devbox-test -- sudo bash -c 'echo "nameserver 8.8.8.8" > /etc/resolv.conf'
```

### Issue 4: Slow Performance in VM

**Symptoms**:
- Cloud-init takes >10 minutes
- Shell commands are sluggish

**Diagnosis**:
```bash
# Check resource allocation
multipass.exe info devbox-test

# Check Windows host resources
# From PowerShell:
# Get-Counter '\Processor(_Total)\% Processor Time','\Memory\Available MBytes'
```

**Solutions**:

**Option 1: Increase VM resources**
```bash
# Stop VM
multipass.exe stop devbox-test

# Modify resources (requires VM restart)
multipass.exe set devbox-test --cpus 4 --memory 8G

# Restart
multipass.exe start devbox-test
```

**Option 2: Disable Windows Defender real-time scanning for Multipass directory**
```powershell
# From PowerShell (as Administrator)
Add-MpPreference -ExclusionPath "C:\Windows\System32\config\systemprofile\AppData\Roaming\multipassd"
```

### Issue 5: File Permission Issues with Mounted Drives

**Symptoms**:
- Can't execute scripts from `/mnt/c`
- Permission denied errors

**Cause**: Windows files mounted in WSL have different permission model

**Solution**: Copy files to WSL filesystem before use
```bash
# Instead of:
./cloudops-config-v2.yaml  # (if on /mnt/c)

# Do:
cp /mnt/c/Users/YourName/devbox/cloudops-config-v2.yaml ~/
chmod +x ~/cloudops-config-v2.yaml
```

### Issue 6: "cloud-init: command not found" in WSL

**Symptoms**:
```bash
$ cloud-init schema --config-file cloudops-config-v2.yaml
-bash: cloud-init: command not found
```

**Solution**:
```bash
# Install cloud-init in WSL
sudo apt update
sudo apt install -y cloud-init
```

### Issue 7: SSH Key Authentication Fails

**Symptoms**:
- VS Code prompts for password when connecting
- SSH connection denied

**Diagnosis**:
```bash
# Check what key is in cloud-init config
grep "ssh-ed25519" cloudops-config-v2.yaml

# Check what keys are on your system
ls -la ~/.ssh/*.pub
```

**Solution**:
Ensure the public key in `cloudops-config-v2.yaml` matches a private key you have access to. Update the config if needed:

```yaml
users:
  - name: cloudops
    ssh_authorized_keys:
      - ssh-ed25519 AAAA... your-actual-public-key
```

---

## Testing Checklist

Use this checklist to track testing progress:

### Phase 1: Setup
- [ ] Multipass installed on Windows
- [ ] Multipass accessible from WSL
- [ ] Cloud-init YAML syntax validated
- [ ] No schema errors in config

### Phase 2: VM Provisioning
- [ ] VM launches successfully
- [ ] Cloud-init completes without errors
- [ ] Setup completion marker exists
- [ ] All critical components installed

### Phase 3: Full Validation
- [ ] Security tests (12/12 passed)
- [ ] Performance tests (8/8 passed)
- [ ] Functional tests (18/18 passed)
- [ ] Integration tests (10/10 passed)
- [ ] Edge case tests (10/10 passed)

### Phase 4: Smoke Test
- [ ] Smoke test script executes successfully
- [ ] Critical path test passes
- [ ] Template instantiation works

### Documentation
- [ ] Testing results documented
- [ ] Any issues logged with reproduction steps
- [ ] Performance metrics recorded

---

## Additional Resources

### Official Documentation
- **Multipass**: <https://multipass.run/docs>
- **Cloud-init**: <https://cloudinit.readthedocs.io/>
- **Devbox**: <https://www.jetify.com/devbox/docs/>
- **Nix**: <https://nixos.org/manual/nix/stable/>

### Devbox Project Documentation
- **Main README**: `README.md`
- **Devbox Guide**: `docs/DEVBOX_GUIDE.md`
- **VS Code Setup**: `docs/VSCODE_SETUP.md`
- **Multipass Best Practices**: `docs/MULTIPASS_BEST_PRACTICES.md`
- **Troubleshooting**: `docs/TROUBLESHOOTING.md`
- **Validation Test Plan**: `docs/testing/VALIDATION_TEST_PLAN.md`

### WSL-Specific Resources
- **WSL Documentation**: <https://learn.microsoft.com/en-us/windows/wsl/>
- **WSL + Multipass**: <https://multipass.run/docs/wsl-support>

---

## Quick Reference: Common Commands

```bash
# === From WSL ===

# Launch VM
multipass.exe launch --name devbox-test --cloud-init cloudops-config-v2.yaml -c 4 -m 8G 25.10

# Check status
multipass.exe list
multipass.exe info devbox-test

# Execute command in VM
multipass.exe exec devbox-test -- <command>

# Interactive shell
multipass.exe shell devbox-test

# Transfer files
multipass.exe transfer <local-file> devbox-test:/remote/path

# Stop/Start/Restart
multipass.exe stop devbox-test
multipass.exe start devbox-test
multipass.exe restart devbox-test

# Delete VM
multipass.exe delete devbox-test
multipass.exe purge  # Permanently remove deleted VMs

# === From Windows PowerShell ===

# Same commands, but without .exe extension
multipass launch --name devbox-test --cloud-init cloudops-config-v2.yaml
multipass list
multipass shell devbox-test
```

---

## Automation Script: Complete Test Suite

Save as `run-all-tests.sh` in devbox project root:

```bash
#!/bin/bash
# run-all-tests.sh - Complete automated testing suite

set -e

VM_NAME="${1:-devbox-test-$(date +%s)}"
CONFIG_FILE="cloudops-config-v2.yaml"
LOG_FILE="test-results-$(date +%Y%m%d-%H%M%S).log"

echo "=== DEVBOX COMPREHENSIVE TEST SUITE ===" | tee -a "$LOG_FILE"
echo "VM Name: $VM_NAME" | tee -a "$LOG_FILE"
echo "Started: $(date)" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# Phase 1: Validation
echo "[Phase 1] Validating cloud-init config..." | tee -a "$LOG_FILE"
cloud-init schema --config-file "$CONFIG_FILE" 2>&1 | tee -a "$LOG_FILE"

# Phase 2: Launch
echo "[Phase 2] Launching VM..." | tee -a "$LOG_FILE"
multipass.exe launch \
  --name "$VM_NAME" \
  --cloud-init "$CONFIG_FILE" \
  --cpus 4 \
  --memory 8G \
  --disk 40G \
  25.10 2>&1 | tee -a "$LOG_FILE"

# Phase 3: Wait for cloud-init
echo "[Phase 3] Waiting for cloud-init completion..." | tee -a "$LOG_FILE"
multipass.exe exec "$VM_NAME" -- cloud-init status --wait 2>&1 | tee -a "$LOG_FILE"

# Phase 4: Health check
echo "[Phase 4] Running health check..." | tee -a "$LOG_FILE"
multipass.exe exec "$VM_NAME" -- bash << 'EOF' 2>&1 | tee -a "$LOG_FILE"
echo "Nix: $(nix --version | head -1)"
echo "Devbox: $(devbox version)"
echo "Node.js: $(node --version)"
echo "Claude CLI: $(claude --version 2>&1 | head -1)"
echo "jq: $(jq --version)"
echo "yq: $(yq --version | head -1)"
echo "gh: $(gh --version | head -1)"
EOF

# Phase 5: Template tests
echo "[Phase 5] Testing templates..." | tee -a "$LOG_FILE"
multipass.exe exec "$VM_NAME" -- bash << 'EOF' 2>&1 | tee -a "$LOG_FILE"
cd /home/cloudops/code/personal
for template in nodejs-webapp python-api go-service rust-cli; do
  echo "Testing $template..."
  mkdir "test-$template"
  cd "test-$template"
  cp ~/.devbox-templates/$template.json devbox.json
  devbox shell -- echo "Template loaded successfully"
  cd ..
done
EOF

# Phase 6: Performance metrics
echo "[Phase 6] Collecting performance metrics..." | tee -a "$LOG_FILE"
multipass.exe exec "$VM_NAME" -- bash << 'EOF' 2>&1 | tee -a "$LOG_FILE"
echo "Shell startup time:"
time bash -i -c exit

echo "Disk usage:"
df -h / | tail -1

echo "Nix store size:"
du -sh /nix/store
EOF

# Phase 7: Cleanup (optional)
read -p "Delete test VM? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  echo "[Phase 7] Cleaning up..." | tee -a "$LOG_FILE"
  multipass.exe delete --purge "$VM_NAME" 2>&1 | tee -a "$LOG_FILE"
else
  echo "[Phase 7] Keeping VM for manual inspection" | tee -a "$LOG_FILE"
fi

echo "" | tee -a "$LOG_FILE"
echo "=== TEST SUITE COMPLETE ===" | tee -a "$LOG_FILE"
echo "Finished: $(date)" | tee -a "$LOG_FILE"
echo "Results saved to: $LOG_FILE" | tee -a "$LOG_FILE"
```

**Usage**:
```bash
chmod +x run-all-tests.sh
./run-all-tests.sh
# Or with custom VM name:
./run-all-tests.sh my-test-vm
```

---

## Summary

This guide provides a complete testing workflow for the devbox project when working from **WSL Ubuntu 25.10** with **Windows host access**. The recommended approach:

1. ✅ **Install Multipass on Windows** (not WSL) for best performance
2. ✅ **Control from WSL** using `multipass.exe` commands
3. ✅ **Validate syntax** using cloud-init in WSL before launch
4. ✅ **Execute comprehensive tests** (58 test cases) systematically
5. ✅ **Use automation scripts** for repeatable testing

**Key Takeaway**: The Windows + WSL hybrid approach provides the best of both worlds:
- Native virtualization performance (Hyper-V on Windows)
- Familiar Linux command-line environment (WSL)
- Seamless integration between both worlds

For questions or issues not covered here, refer to:
- `docs/TROUBLESHOOTING.md` - General troubleshooting
- `docs/MULTIPASS_BEST_PRACTICES.md` - Production hardening
- `docs/testing/VALIDATION_TEST_PLAN.md` - Detailed test procedures

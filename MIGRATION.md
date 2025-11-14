# Migration Guide

This guide helps you upgrade CloudOps Multipass configurations between major versions.

---

## Table of Contents

- [Migrating from 1.x to 2.0.0](#migrating-from-1x-to-200)
- [Migrating from 2.0.0 to 2.1.0](#migrating-from-200-to-210)
- [General Migration Best Practices](#general-migration-best-practices)

---

## Migrating from 1.x to 2.0.0

**Release Date**: 2025-11-13
**Breaking Changes**: Yes (user account migration)

### What Changed

Version 2.0.0 introduces a **breaking change**: the default user account changed from `devbox` to `cloudops`.

**Reasons for change:**
- Clearer separation between "Devbox" (the Jetify development tool) and the VM user account
- Reduced confusion about terminology
- Preparation for Devbox tool integration in version 2.1.0

### Impact Assessment

| Component | Impact | Action Required |
|-----------|--------|-----------------|
| **VM User** | High | Recreate VM or manually migrate |
| **SSH Config** | High | Update SSH config entries |
| **Home Directory** | High | Data migration required |
| **Git Config** | Medium | Will regenerate automatically |
| **VS Code** | Medium | Reconnect to new user |
| **File Paths** | High | Update any hardcoded paths |

### Migration Options

You have **two options** for migration:

#### Option 1: Fresh Start (Recommended)

**Best for**: New projects or when you can easily recreate your work.

**Advantages**:
- Clean, tested configuration
- No manual steps
- Latest optimizations included

**Steps**:

1. **Backup Important Data**

   ```bash
   # From your host machine
   multipass exec devbox -- tar -czf /tmp/backup.tar.gz \
     /home/devbox/code \
     /home/devbox/.ssh \
     /home/devbox/.gitconfig

   multipass transfer devbox:/tmp/backup.tar.gz ./devbox-backup.tar.gz
   ```

2. **Delete Old VM**

   ```bash
   multipass stop devbox
   multipass delete devbox
   multipass purge
   ```

3. **Launch New VM with cloudops User**

   ```bash
   # Update your SSH public key in cloudops-config-v2.yaml first!
   multipass launch --name cloudops --cloud-init cloudops-config-v2.yaml \
     -c 4 -m 8G -d 40G \
     -e GIT_USER_NAME="Your Name" \
     -e GIT_USER_EMAIL="your@email.com"

   # Wait for cloud-init to complete
   multipass exec cloudops -- cloud-init status --wait
   ```

4. **Update SSH Config**

   Edit `~/.ssh/config` and update:

   ```diff
   - Host devbox
   + Host cloudops
       HostName <NEW-VM-IP>
   -   User devbox
   +   User cloudops
       IdentityFile ~/.ssh/id_ed25519
       StrictHostKeyChecking accept-new
   ```

   Get new IP:
   ```bash
   multipass info cloudops | grep IPv4
   ```

5. **Restore Your Data**

   ```bash
   # Copy backup to new VM
   multipass transfer ./devbox-backup.tar.gz cloudops:/tmp/

   # Extract in new VM
   multipass exec cloudops -- tar -xzf /tmp/backup.tar.gz -C /

   # Fix ownership
   multipass exec cloudops -- sudo chown -R cloudops:cloudops /home/cloudops/code
   ```

6. **Verify Connection**

   ```bash
   ssh cloudops whoami
   # Expected: cloudops

   code --remote ssh-remote+cloudops /home/cloudops
   ```

---

#### Option 2: In-Place Migration (Advanced)

**Best for**: Large projects, complex setups, or when downtime must be minimized.

**Warning**: ⚠️ This approach is more error-prone. Test thoroughly.

**Steps**:

1. **Backup Everything**

   ```bash
   multipass exec devbox -- sudo tar -czf /tmp/full-backup.tar.gz \
     /home/devbox \
     /etc/ssh

   multipass transfer devbox:/tmp/full-backup.tar.gz ./full-backup.tar.gz
   ```

2. **Create New User in Existing VM**

   ```bash
   multipass exec devbox -- sudo useradd -m -s /bin/bash -G adm,cdrom,dip,plugdev,sudo cloudops
   multipass exec devbox -- sudo sh -c 'echo "cloudops ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/cloudops'
   ```

3. **Copy Data to New User**

   ```bash
   multipass exec devbox -- sudo cp -r /home/devbox/. /home/cloudops/
   multipass exec devbox -- sudo chown -R cloudops:cloudops /home/cloudops
   ```

4. **Update SSH Keys**

   ```bash
   multipass exec devbox -- sudo mkdir -p /home/cloudops/.ssh
   multipass exec devbox -- sudo cp /home/devbox/.ssh/authorized_keys /home/cloudops/.ssh/
   multipass exec devbox -- sudo chown -R cloudops:cloudops /home/cloudops/.ssh
   multipass exec devbox -- sudo chmod 700 /home/cloudops/.ssh
   multipass exec devbox -- sudo chmod 600 /home/cloudops/.ssh/authorized_keys
   ```

5. **Update SSH Config on Host**

   ```bash
   # Add new entry in ~/.ssh/config
   Host cloudops
       HostName <SAME-IP-AS-DEVBOX>
       User cloudops
       IdentityFile ~/.ssh/id_ed25519
       StrictHostKeyChecking accept-new
   ```

6. **Test New User**

   ```bash
   ssh cloudops whoami
   # Expected: cloudops

   ssh cloudops "ls /home/cloudops/code"
   # Verify your files are there
   ```

7. **Update VS Code**

   ```bash
   code --remote ssh-remote+cloudops /home/cloudops
   ```

8. **Verify Everything Works**

   - Test git configuration: `ssh cloudops "git config --list"`
   - Test file access: `ssh cloudops "ls -la /home/cloudops/code"`
   - Test sudo: `ssh cloudops "sudo whoami"` (should output: root)

9. **Optional: Remove Old User**

   ```bash
   # Only after confirming everything works!
   multipass exec devbox -- sudo userdel -r devbox

   # Optionally rename the VM
   multipass stop devbox
   # Note: Multipass doesn't support renaming, so you'd need to:
   # 1. Export VM: multipass export devbox devbox.tar.gz
   # 2. Delete VM: multipass delete devbox && multipass purge
   # 3. Import with new name: (not currently supported in Multipass)
   # Recommendation: Keep VM name as "devbox" or create fresh VM named "cloudops"
   ```

---

## Migrating from 2.0.0 to 2.1.0

**Release Date**: 2025-11-14
**Breaking Changes**: No

### What Changed

Version 2.1.0 adds **Devbox integration** with Nix package manager. This is an additive change that does not affect existing functionality.

**New Features**:
- Nix package manager for reproducible environments
- Devbox CLI for project isolation
- 5 production-ready project templates
- Automatic shell environment activation

### Migration Options

#### Option 1: Recreate VM (Recommended)

Get all new features automatically:

```bash
# Backup your data first
multipass exec cloudops -- tar -czf /tmp/backup.tar.gz /home/cloudops/code

multipass transfer cloudops:/tmp/backup.tar.gz ./backup.tar.gz

# Delete and recreate
multipass stop cloudops
multipass delete cloudops
multipass purge

# Launch with new config
multipass launch --name cloudops --cloud-init cloudops-config-v2.yaml \
  -c 4 -m 8G -d 40G \
  -e GIT_USER_NAME="Your Name" \
  -e GIT_USER_EMAIL="your@email.com"

# Restore data
multipass transfer ./backup.tar.gz cloudops:/tmp/
multipass exec cloudops -- tar -xzf /tmp/backup.tar.gz -C /home/cloudops/
```

#### Option 2: Manual Installation (Keep Existing VM)

Add Devbox to your existing VM:

```bash
# SSH into VM
multipass shell cloudops

# Install Nix
sh <(curl -L https://nixos.org/nix/install) --daemon

# Configure Nix (add to ~/.config/nix/nix.conf)
mkdir -p ~/.config/nix
cat >> ~/.config/nix/nix.conf << 'EOF'
experimental-features = nix-command flakes
auto-optimise-store = true
max-jobs = auto
cores = 0
keep-outputs = true
keep-derivations = true
EOF

# Install Devbox
curl -fsSL https://get.jetify.com/devbox | bash

# Add to shell (add to ~/.bashrc)
echo 'eval "$(devbox global shellenv --init-hook)"' >> ~/.bashrc

# Install global tools
devbox global add jq yq gh

# Source new config
source ~/.bashrc

# Verify installation
devbox version
nix --version
```

**Result**: Your existing VM now has Devbox capabilities without losing any data.

---

## General Migration Best Practices

### Before Any Migration

1. **Backup Your Data**
   - Code projects
   - SSH keys
   - Git configurations
   - Custom scripts or tools

2. **Document Your Setup**
   - List installed packages beyond cloud-init
   - Note custom configurations
   - Document VS Code extensions

3. **Test in Staging**
   - Create a test VM first
   - Validate the migration process
   - Identify issues before production migration

### During Migration

1. **Follow Steps Sequentially**
   - Don't skip steps
   - Verify each step before proceeding
   - Keep backup accessible

2. **Monitor for Errors**
   - Check cloud-init logs: `multipass exec <vm> -- cat /var/log/cloud-init.log`
   - Watch for SSH connection issues
   - Verify file permissions

3. **Keep Old VM Until Verified**
   - Don't delete old VM immediately
   - Run both VMs in parallel during testing
   - Only purge after 24-48 hours of successful operation

### After Migration

1. **Verify Functionality**
   ```bash
   # Test SSH
   ssh cloudops whoami

   # Test VS Code
   code --remote ssh-remote+cloudops /home/cloudops

   # Test git
   ssh cloudops "git config --list"

   # Test sudo
   ssh cloudops "sudo whoami"

   # Test file access
   ssh cloudops "ls -la /home/cloudops/code"
   ```

2. **Update Documentation**
   - Update team wiki/docs with new VM name
   - Update any scripts that reference old VM name
   - Share migration guide with team

3. **Clean Up**
   - Delete backup files (after confirming everything works)
   - Remove old SSH config entries
   - Purge old VM: `multipass delete <old-vm> && multipass purge`

---

## Troubleshooting

### Issue: SSH Key Not Working After Migration

**Problem**: `Permission denied (publickey)` when connecting to new VM.

**Solution**:
```bash
# Verify key is in new VM
ssh-copy-id cloudops@<VM-IP>

# Or manually copy
cat ~/.ssh/id_ed25519.pub | \
  multipass exec cloudops -- tee -a /home/cloudops/.ssh/authorized_keys
```

### Issue: VS Code Can't Find Remote Server

**Problem**: VS Code shows "Could not establish connection to cloudops".

**Solution**:
```bash
# Remove old VS Code server files
ssh cloudops "rm -rf /home/cloudops/.vscode-server"

# Reconnect
code --remote ssh-remote+cloudops /home/cloudops
```

### Issue: Git Config Not Working

**Problem**: Git commands fail or use wrong name/email.

**Solution**:
```bash
# Manually set git config
ssh cloudops "git config --global user.name 'Your Name'"
ssh cloudops "git config --global user.email 'your@email.com'"
```

### Issue: Files Missing After Migration

**Problem**: Projects missing in `/home/cloudops/code`.

**Solution**:
```bash
# Verify backup contents
tar -tzf ./backup.tar.gz | grep code

# Re-extract backup
multipass transfer ./backup.tar.gz cloudops:/tmp/
multipass exec cloudops -- tar -xzf /tmp/backup.tar.gz -C /
multipass exec cloudops -- sudo chown -R cloudops:cloudops /home/cloudops/code
```

---

## Support

For migration issues:

1. Check [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)
2. Review [CHANGELOG.md](CHANGELOG.md) for version-specific notes
3. Open an issue on GitHub with:
   - Source version
   - Target version
   - Migration option used
   - Error messages and logs

---

**Document Version**: 1.0
**Last Updated**: 2025-11-14
**Maintained by**: CloudOps Development Team

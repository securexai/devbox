# CloudOps Multipass Development Environment

**Status:** ✅ **Production Ready** | **Last Updated:** 2025-11-15 | **Version:** 2.3.0

A production-ready cloud-init configuration for Multipass VMs featuring Ubuntu 25.10, complete development tools, Devbox/Nix integration, Claude CLI, and VS Code Remote SSH support.

## What Is This?

This project provides a **declarative, reproducible development environment** using:

- **Multipass** - Lightweight Ubuntu VMs on Windows, macOS, and Linux
- **Cloud-init** - Automated VM configuration and provisioning
- **Devbox** - Isolated, reproducible development environments with Nix
- **Claude CLI** - AI-powered coding assistant (@anthropic-ai/claude-code)
- **VS Code Remote SSH** - Full-featured remote development experience

**Key Features:**

- ✅ Fully automated setup (one command to launch)
- ✅ Ubuntu 25.10 with cloud-init schema validation
- ✅ Devbox + Nix for project isolation
- ✅ Claude CLI globally installed via npm
- ✅ Pre-configured VS Code Remote SSH support
- ✅ Security hardening with ED25519 keys
- ✅ Production-ready git workflows
- ✅ Comprehensive documentation and troubleshooting

---

## Quick Start

### Prerequisites

- [Multipass](https://multipass.run/) 1.16.0 or later
- SSH key pair (ED25519 recommended)
- VS Code with Remote-SSH extension (for remote development)

### 1. Configure SSH Key

Edit `cloudops-config-v2.yaml` and replace the SSH public key (line 49):

```yaml
ssh_authorized_keys:
  - ssh-ed25519 YOUR_PUBLIC_KEY_HERE your_email@example.com
```

**Generate a new ED25519 key if needed:**

```bash
ssh-keygen -t ed25519 -C "your_email@example.com"
cat ~/.ssh/id_ed25519.pub  # Copy this to the config file
```

### 2. Launch VM

```bash
multipass launch --name cloudops --cloud-init cloudops-config-v2.yaml \
  -c 4 -m 8G -d 40G \
  -e GIT_USER_NAME="Your Name" \
  -e GIT_USER_EMAIL="your@email.com"
```

**Wait for cloud-init to complete:**

```bash
multipass exec cloudops -- cloud-init status --wait
# Expected output: status: done
```

### 3. Get VM IP Address

```bash
multipass info cloudops | grep IPv4
# Example output: IPv4: 172.29.1.216
```

**Configure SSH (replace `<VM-IP>` with actual IP):**

Add to `~/.ssh/config`:

```
Host cloudops
    HostName <VM-IP>
    User cloudops
    IdentityFile ~/.ssh/id_ed25519
    StrictHostKeyChecking accept-new
```

### 4. Verify Connection

```bash
ssh cloudops whoami
# Expected output: cloudops
```

### 5. Connect with VS Code

```bash
code --remote ssh-remote+cloudops /home/cloudops
```

**You're ready to develop!**

---

## Quick Reference

### Essential Commands

```bash
# VM Management
multipass list                          # List all VMs
multipass info cloudops                 # Get VM details including IP
multipass shell cloudops                # Open shell in VM
multipass stop cloudops                 # Stop VM
multipass start cloudops                # Start VM
multipass delete cloudops               # Delete VM
multipass purge                         # Permanently remove deleted VMs

# SSH Connection
ssh cloudops                            # Connect to VM
ssh cloudops "command"                  # Run command remotely

# VS Code Remote
code --remote ssh-remote+cloudops /path # Open remote directory
code --remote ssh-remote+cloudops .     # Open current directory remotely

# Claude CLI Usage (available everywhere in VM)
ssh cloudops "claude --help"            # Show Claude CLI help
ssh cloudops "claude 'explain this code'" # Ask Claude for help

# Cloud-init Status
multipass exec cloudops -- cloud-init status --wait  # Wait for completion
multipass exec cloudops -- cat /var/log/cloud-init-output.log  # View logs
```

### Key Paths in VM

| Path | Purpose |
|------|---------|
| `/home/cloudops` | User home directory |
| `/home/cloudops/code/work` | Work projects workspace |
| `/home/cloudops/code/personal` | Personal projects workspace |
| `/home/cloudops/.ssh/authorized_keys` | SSH public keys |
| `/var/log/cloud-init.log` | Cloud-init detailed log |
| `/var/log/cloud-init-output.log` | Cloud-init stdout/stderr |

### VM Configuration

| Setting | Value |
|---------|-------|
| **VM Name** | cloudops |
| **OS** | Ubuntu 25.10 (Oracular Oriole) |
| **User** | cloudops (passwordless sudo) |
| **SSH Auth** | ED25519 public key (no password) |
| **Default CPUs** | 4 cores (configurable) |
| **Default RAM** | 8GB (configurable) |
| **Default Disk** | 40GB (configurable) |

---

## Detailed Documentation

### Core Guides

- **[VS Code Remote SSH Setup](docs/VSCODE_SETUP.md)** - Complete VS Code Remote SSH configuration and troubleshooting
- **[Devbox Integration Guide](docs/DEVBOX_GUIDE.md)** - Comprehensive guide to Devbox and Nix package management
- **[Multipass Best Practices](docs/MULTIPASS_BEST_PRACTICES.md)** - Production deployment and security hardening
- **[Troubleshooting Guide](docs/TROUBLESHOOTING.md)** - Common issues and solutions

### Testing & Validation

- **[Validation Test Results](docs/testing/)** - Historical validation test results and methodology

### Migration & Contributing

- **[Migration Guide](MIGRATION.md)** - Upgrading from previous versions
- **[Changelog](CHANGELOG.md)** - Version history and release notes

---

## Troubleshooting

### VM Won't Start

```bash
# Check Multipass status
multipass list

# Check system resources
multipass info cloudops

# Check Multipass logs
multipass get local.driver  # Verify driver (hyperv, qemu, etc.)
```

### SSH Connection Refused

```bash
# Verify VM is running
multipass list | grep cloudops

# Get current IP (may have changed)
multipass info cloudops | grep IPv4

# Update SSH config with new IP
# Edit ~/.ssh/config and replace HostName value

# Test with verbose output
ssh -vvv cloudops whoami
```

### Cloud-init Failed

```bash
# Check cloud-init status
multipass exec cloudops -- cloud-init status --long

# View error logs
multipass exec cloudops -- cat /var/log/cloud-init.log

# Validate config file before launch
cloud-init schema --config-file cloudops-config-v2.yaml --annotate
```

### VS Code Can't Connect

```bash
# Verify SSH works first
ssh cloudops whoami

# Check VS Code Remote SSH extension is installed
code --list-extensions | grep ms-vscode-remote.remote-ssh

# Try connecting with explicit path
code --remote ssh-remote+cloudops /home/cloudops
```

**For detailed troubleshooting, see [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)**

---

## Glossary

**cloudops** - The default username for the VM user account (not related to Devbox)

**Devbox** - Jetify's development environment tool that uses Nix for package management and project isolation

**Multipass** - Canonical's tool for launching and managing lightweight Ubuntu VMs

**Cloud-init** - Industry-standard tool for cloud instance initialization and automated configuration

**Nix** - Package manager providing reproducible, isolated development environments

---

## Customization

### Git Configuration

The config file includes placeholder git settings. Customize before launch:

**Option 1: Environment Variables (Recommended)**

```bash
multipass launch --name cloudops --cloud-init cloudops-config-v2.yaml \
  -e GIT_USER_NAME="Your Name" \
  -e GIT_USER_EMAIL="your@email.com" \
  -e GIT_WORK_NAME="Work Name" \
  -e GIT_WORK_EMAIL="work@company.com"
```

**Option 2: Manual Edit**

Edit `cloudops-config-v2.yaml` lines ~619-650 and replace CHANGEME placeholders.

### VM Resources

Adjust CPU, memory, and disk when launching:

```bash
multipass launch --name cloudops --cloud-init cloudops-config-v2.yaml \
  -c 8 -m 16G -d 100G  # 8 CPUs, 16GB RAM, 100GB disk
```

---

## Security Considerations

- **Passwordless sudo**: Enabled by default for development convenience. Remove `NOPASSWD` from config for production.
- **SSH key authentication**: Only ED25519 keys recommended. No password authentication.
- **Cloud-init secrets**: Never commit sensitive data to the config file. Use environment variables.
- **VM network**: VMs use bridged networking and get IPs from your network's DHCP.

**For production security hardening, see [docs/MULTIPASS_BEST_PRACTICES.md](docs/MULTIPASS_BEST_PRACTICES.md)**

---

## Contributing

Contributions welcome! Please:

1. Validate config changes: `cloud-init schema --config-file cloudops-config-v2.yaml --annotate`
2. Test in a fresh VM before submitting PR
3. Update relevant documentation
4. Follow [Conventional Commits](https://www.conventionalcommits.org/) for commit messages

---

## License

MIT License - See LICENSE file for details

---

## Project Status

| Component | Status | Version | Last Tested |
|-----------|--------|---------|-------------|
| Cloud-init Config | ✅ Valid | v2.2.0 | 2025-11-15 |
| Ubuntu 25.10 | ✅ Compatible | Oracular | 2025-11-15 |
| Multipass | ✅ Working | 1.16.1+ | 2025-11-15 |
| VS Code Remote | ✅ Functional | Latest | 2025-11-15 |
| Devbox Integration | ✅ Operational | 0.16.0 | 2025-11-15 |
| Nix Package Manager | ✅ Operational | 3.13.1 | 2025-11-15 |
| Claude CLI | ✅ Installed | 2.0.42 | 2025-11-15 |
| Node.js (Global) | ✅ Available | 24.11.0 | 2025-11-15 |
| pnpm | ✅ Per-Project | via Devbox | Add with `devbox add pnpm` |

**Maintained by:** CloudOps Development Team
**Questions or Issues:** Open an issue on GitHub

---

**Get Started:** `multipass launch --name cloudops --cloud-init cloudops-config-v2.yaml`

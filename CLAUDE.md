# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This repository contains a production-ready Multipass VM configuration using cloud-init to create a minimal, secure Ubuntu 25.10 development environment. The VM is optimized for per-project tool isolation via Devbox, eliminating global runtime pollution and version conflicts.

## Core Architecture

### Configuration Structure

- **devbox-config-v2.yaml**: Main cloud-init configuration (YAML-only format)
  - User configuration with passwordless sudo (development-focused)
  - Minimal package set (no global runtimes like Node.js, Python, Go)
  - Dual SSH identity (work RSA 4096-bit + personal ed25519)
  - Dual Git identity with directory-based switching
  - 100+ productivity bash aliases
  - Kernel tuning for development workloads
  - Devbox integration for per-project environments

### Key Design Principles

1. **True Minimalism**: VM provides only essential system utilities and Devbox. Projects bring their own tools via `devbox.json`.

2. **Per-Project Isolation**: No global runtimes installed. Each project defines its toolchain independently.

3. **Dual Identity Management**:
   - Git auto-switches identity based on directory (`~/code/work/` vs `~/code/personal/`)
   - Pre-generated SSH keys for work and personal use

4. **Security-First**:
   - SSH key authentication (no password hardcoding)
   - Minimal attack surface (only essential packages)
   - Kernel security tuning (swappiness, vfs_cache_pressure, inotify limits)

## Official Documentation

**IMPORTANT**: Always consult official documentation for accurate, up-to-date information:

- **Multipass**: https://documentation.ubuntu.com/multipass/stable/tutorial/
- **Cloud-init**: https://cloudinit.readthedocs.io/en/latest/

## Common Development Tasks

### Testing Cloud-Init Changes

When modifying `devbox-config-v2.yaml`:

```bash
# 1. Validate YAML syntax
cloud-init schema --config-file devbox-config-v2.yaml --annotate

# 2. Launch test VM
multipass launch 24.10 --name test-devbox --cloud-init devbox-config-v2.yaml --cpus 1 --memory 1G --disk 5G

# 3. Wait for cloud-init to complete
multipass exec test-devbox -- cloud-init status --wait

# 4. Check logs for errors
multipass exec test-devbox -- cat /var/log/cloud-init-output.log
multipass exec test-devbox -- cat /var/log/cloud-init.log

# 5. Verify expected state
multipass shell test-devbox

# 6. Clean up
multipass delete test-devbox && multipass purge
```

### Validating Configuration

Before committing changes to cloud-init:

```bash
# YAML validation
cloud-init schema --config-file devbox-config-v2.yaml --annotate

# YAML linting (if yamllint is installed)
yamllint devbox-config-v2.yaml

# Git validation (if modified)
python -c "import yaml; yaml.safe_load(open('devbox-config-v2.yaml'))"
```

### Launching Production VM

Standard production launch:

```bash
multipass launch 25.10 --name devbox --cloud-init devbox-config-v2.yaml --cpus 2 --memory 2G --disk 20G
```

Minimal resource launch (tested and verified):

```bash
multipass launch 25.10 --name devbox --cloud-init devbox-config-v2.yaml --cpus 1 --memory 1G --disk 10G
```

### Debugging Cloud-Init Issues

```bash
# Check cloud-init status
multipass exec devbox -- cloud-init status --long

# View detailed logs
multipass exec devbox -- sudo cat /var/log/cloud-init.log

# View command output
multipass exec devbox -- sudo cat /var/log/cloud-init-output.log

# Analyze module execution
multipass exec devbox -- cloud-init analyze show

# Re-run cloud-init (for testing only)
multipass shell devbox
sudo cloud-init clean --logs --reboot
```

## Critical Constraints

### Multipass Limitations

1. **YAML-Only Format**: Multipass only accepts cloud-init YAML format. Shell scripts, MIME archives, and other cloud-init formats will fail validation.

2. **Blueprints Deprecated**: Do NOT use `multipass launch --blueprint`. Use `--cloud-init` with YAML files instead.

3. **Mount Security**:
   - **Windows**: Mounts run as SYSTEM with full host write access (disabled by default)
   - **Linux (snap)**: Restricted to `/home` directory, no hidden files
   - **macOS**: Requires privileged users (sudo/wheel/admin groups)

4. **Resource Modification**: CPU and memory can be changed after creation (VM must be stopped). Disk size cannot be changed after launch.

### Cloud-Init Behavior

1. **Execution Order**:
   - `package_update`: Update package repositories
   - `package_upgrade`: Upgrade existing packages
   - `packages`: Install new packages
   - `write_files`: Create configuration files
   - `runcmd`: Execute commands

2. **Idempotency Caveats**: Some cloud-init modules are NOT fully idempotent. Design `runcmd` sections with guards:

```yaml
runcmd:
  - |
    if ! grep -q "custom_setting" /home/devbox/.bashrc; then
      echo "custom_setting" >> /home/devbox/.bashrc
    fi
```

3. **YAML Sensitivity**:
   - First line must be `#cloud-config`
   - Use spaces (not tabs) for indentation
   - YAML 1.1 syntax (beware of octal literals like `0755`)
   - Multiline strings require `|` or `>` indicators

## File Structure Context

```
.
├── devbox-config-v2.yaml       # Main cloud-init configuration (YAML ONLY)
├── README.md                   # Comprehensive user documentation
├── CLAUDE.md                   # This file - AI assistant guidance
├── docs/
│   ├── VSCODE_SETUP.md         # VS Code Remote SSH setup guide
│   ├── MULTIPASS_BEST_PRACTICES.md  # Multipass and cloud-init standards
│   └── OPTIMIZATION_SUMMARY.md # Performance optimization notes
└── .gitignore                  # Git ignore patterns
```

## Important Configuration Sections

### Git Dual-Identity (lines ~619-650 in devbox-config-v2.yaml)

**TEMPLATE VALUES**: Must be customized before use:

```yaml
# Global git config (default for personal)
[user]
    name = CHANGEME
    email = changeme@example.com

# Work override (activated in ~/code/work/**)
[includeIf "gitdir/i:~/code/work/**"]
    path = ~/code/work/.gitconfig
```

The configuration uses `includeIf` directive for automatic identity switching:
- `~/code/personal/`: Uses personal identity
- `~/code/work/`: Uses work identity

### SSH Key Generation (lines ~675-685)

Pre-generates two SSH key pairs:
- **Work**: RSA 4096-bit (`~/.ssh/id_rsa`)
- **Personal**: ed25519 (`~/.ssh/id_ed25519_personal`)

Keys are stored in `~/.setup-complete` for retrieval.

### Kernel Tuning (sysctl configuration)

```ini
vm.swappiness=10                    # Minimize swap usage
vm.vfs_cache_pressure=50            # Improve filesystem cache
fs.inotify.max_user_watches=524288  # Support large projects with file watchers
```

Applied via `/etc/sysctl.d/99-devbox.conf`.

## Coding Standards

### Commit Message Format

Follow Conventional Commits 1.0.0:

```
<type>(<scope>): <description>

[optional body]
```

**Types**: feat, fix, docs, style, refactor, perf, test, build, ci, chore

**Examples**:
```bash
feat(cloud-init): add Devbox integration
fix(git): resolve dual identity switching
docs(readme): add troubleshooting section
```

### Branch Strategy

- `main`: Production-ready code
- `develop`: Integration branch
- `feature/*`: New features
- `fix/*`: Bug fixes

## Troubleshooting Patterns

### Cloud-Init Validation Errors

**Error**: "File is not valid yaml"
**Solution**: Run `cloud-init schema --config-file devbox-config-v2.yaml --annotate`

**Error**: "Unknown module X"
**Solution**: Verify module name against cloud-init documentation

### Multipass VM Issues

**Issue**: VM won't start
**Debug**:
```bash
multipass list
multipass info devbox
multipass exec devbox -- cloud-init status --wait
```

**Issue**: Out of memory during cloud-init
**Solution**: Increase VM memory to 2G minimum for full package installation

### SSH Key Not Found

**Issue**: `~/.setup-complete` missing or empty
**Debug**:
```bash
multipass exec devbox -- ls -la /home/devbox/.ssh/
multipass exec devbox -- cat /home/devbox/.setup-complete
```

**Solution**: Check cloud-init logs for SSH key generation failures

## Testing Strategy

### Pre-Commit Testing

1. Validate YAML syntax
2. Launch test VM with minimal resources
3. Verify cloud-init completion
4. Check logs for errors
5. Verify expected state (SSH keys, Git config, Devbox installation)
6. Delete test VM and purge

### Post-Commit Verification

1. Launch production VM
2. Retrieve SSH keys from `~/.setup-complete`
3. Test Git dual-identity switching
4. Verify Devbox installation
5. Test sample project initialization

## Security Considerations

### Development vs Production

**Current Configuration**: Optimized for development
- Passwordless sudo enabled
- SSH keys with no passphrase
- Aggressive cleanup for minimal footprint

**Production Hardening** (if needed):
- Remove `NOPASSWD` from sudo configuration
- Add passphrase to SSH keys
- Enable UFW firewall
- Configure security monitoring

### Secret Management

**NEVER**:
- Hardcode passwords in cloud-init
- Commit private SSH keys
- Store sensitive data in version control

**ALWAYS**:
- Use SSH key authentication
- Reference external secret management services
- Use template placeholders for sensitive values

## Common Pitfalls

1. **Using Tabs Instead of Spaces**: Cloud-init YAML is space-sensitive
2. **Forgetting `#cloud-config` Header**: Required as first line
3. **Non-Idempotent `runcmd`**: Always use guards for repeated execution
4. **Hardcoding Git Identity**: Use template values `CHANGEME`
5. **Ignoring YAML 1.1 Octal Parsing**: Quote permission strings like `'0644'`
6. **Assuming Blueprint Support**: Use `--cloud-init`, not `--blueprint`

## Performance Optimization

### VM Resource Sizing

- **Minimal**: 1 CPU, 1GB RAM, 5GB disk (tested, works for basic setup)
- **Development**: 2 CPUs, 2GB RAM, 20GB disk (recommended)
- **Heavy Workload**: 4 CPUs, 4GB RAM, 50GB disk

### Cloud-Init Optimization

- Set `package_update: false` and `package_upgrade: false` to skip apt operations
- Use `packages` module instead of `apt-get install` in `runcmd`
- Minimize `runcmd` complexity (move logic to external scripts if needed)

## Additional Resources

- **README.md**: Complete user documentation with usage examples
- **docs/VSCODE_SETUP.md**: VS Code Remote SSH configuration
- **docs/MULTIPASS_BEST_PRACTICES.md**: Comprehensive best practices guide
- **Multipass Docs**: https://documentation.ubuntu.com/multipass/stable/tutorial/
- **Cloud-Init Docs**: https://cloudinit.readthedocs.io/en/latest/

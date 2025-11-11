# Multipass and Cloud-Init Best Practices (2025)

This document defines best practices for using Multipass and cloud-init for
Ubuntu VM management, updated for 2025 standards.

## Table of Contents

- [Multipass Best Practices](#multipass-best-practices)
  - [Instance Management](#instance-management)
  - [Cloud-Init Integration](#cloud-init-integration)
  - [Data Management](#data-management)
  - [Resource Management](#resource-management)
  - [Security Considerations](#security-considerations)
- [Cloud-Init Best Practices](#cloud-init-best-practices)
  - [Configuration Design](#configuration-design)
  - [Security Standards](#security-standards)
  - [Development Workflow](#development-workflow)
  - [Troubleshooting](#troubleshooting)

## Multipass Best Practices

### Instance Management

#### Naming Conventions

Use descriptive instance names to track their purpose, especially when managing
multiple VMs:

```bash
# Good - descriptive names
multipass launch --name dev-backend
multipass launch --name test-frontend
multipass launch --name staging-database

# Poor - generic names
multipass launch --name vm1
multipass launch --name test
```

#### Lifecycle Management

Manage instance lifecycle efficiently to conserve host resources:

```bash
# Stop unused instances to free resources
multipass stop dev-backend

# Delete instances no longer needed
multipass delete test-frontend

# Purge deleted instances to reclaim disk space
multipass purge

# List all instances with status
multipass list
```

#### Resource Monitoring

Regularly monitor resource usage to optimize allocations:

```bash
# Check detailed instance information
multipass info dev-backend

# Monitor CPU, memory, and disk usage
multipass info --all

# Adjust resources if needed (requires restart)
multipass set local.dev-backend.cpus=4
multipass set local.dev-backend.memory=8G
```

### Cloud-Init Integration

#### Launch with Cloud-Init

**IMPORTANT:** Use cloud-init configuration at launch for automated setup
rather than manual post-launch configuration:

```bash
# Launch with cloud-init configuration
multipass launch --name dev-vm \
  --cloud-init cloud-config.yaml \
  --cpus 2 \
  --memory 4G \
  --disk 20G
```

#### YAML-Only Limitation

**Critical:** Multipass only supports YAML cloud-config format. Other
cloud-init formats (scripts, MIME archives) will fail validation:

```yaml
#cloud-config
# This is the ONLY format Multipass accepts

packages:
  - git
  - docker.io

runcmd:
  - echo "Setup complete"
```

Multipass validates YAML syntax before starting the VM, catching errors early.

#### Blueprints Are Deprecated

**DEPRECATED (2025):** Multipass blueprints are deprecated and will be removed
in a future release. Use cloud-init configurations directly instead:

```bash
# OLD (deprecated)
multipass launch --name dev --blueprint docker

# NEW (recommended)
multipass launch --name dev --cloud-init docker-setup.yaml
```

Migrate existing blueprint workflows to cloud-init YAML configurations.

### Data Management

#### Mount Host Directories

Use `multipass mount` for sharing data between host and instances rather than
storing everything inside the VM:

```bash
# Mount host directory to instance
multipass mount ~/projects dev-backend:/home/ubuntu/projects

# Mount is persistent until explicitly unmounted
multipass umount dev-backend:/home/ubuntu/projects

# Define mounts at launch
multipass launch --name dev \
  --mount ~/projects:/home/ubuntu/projects
```

**Benefits:**

- Data portability across instances
- Easier backups (backup host directory)
- Shared codebase across multiple VMs
- Persist data when instances are deleted

#### Backup Strategy

Implement regular backup practices:

- **Host mounts:** Back up mounted host directories regularly
- **Instance snapshots:** Use hypervisor snapshots if available
- **Critical data:** Export important data from instances periodically
- **Configuration:** Version control cloud-init files

Keep instances updated with security patches:

```bash
# Inside instance
sudo apt update && sudo apt upgrade -y
```

### Resource Management

#### Specify Resources at Launch

Define CPU, memory, and disk requirements at launch rather than relying on
defaults (1 CPU, 1GB RAM, 5GB disk):

```bash
# Specify resources for development workload
multipass launch --name dev-heavy \
  --cpus 4 \
  --memory 8G \
  --disk 50G

# Lightweight instance for testing
multipass launch --name test-light \
  --cpus 1 \
  --memory 2G \
  --disk 10G
```

#### Resource Optimization

Monitor and optimize resource allocation:

- **Over-allocation:** Wastes host resources
- **Under-allocation:** Poor instance performance
- **Right-sizing:** Match resources to workload requirements

Use `multipass info` to check current usage and adjust as needed.

### Security Considerations

#### Mount Security Risks

**CRITICAL WARNING:** Mounts are performed with elevated privileges, creating
security implications:

**Linux (snap installation):**

- Snap confinement restricts mounts to `/home` directory only
- Cannot mount hidden files/folders in `/home`
- User A can access mounts created by User B in B's home directory
- Cannot mount outside `/home` or to system directories

**macOS:**

- Only privileged users (sudo/wheel/admin groups) can use Multipass
- Mount security relies on macOS user permissions

**Windows:**

- Mounts run as SYSTEM user with write access to entire host OS
- Mounts are disabled by default for security reasons
- Must be explicitly enabled (understand risks first)

**Security Best Practices:**

- Mount only necessary directories (principle of least privilege)
- Avoid mounting sensitive system directories
- Review mounted paths regularly: `multipass info <instance>`
- Use read-only mounts when write access isn't needed
- Be aware of cross-user mount access on Linux

#### Quick Access Methods

Use appropriate access methods for different scenarios:

```bash
# Quick shell access (interactive)
multipass shell dev-backend

# Execute single command (automation/scripting)
multipass exec dev-backend -- ls -la /var/log

# SSH access (full features, port forwarding)
ssh ubuntu@$(multipass info dev-backend --format json | jq -r '.info."dev-backend".ipv4[0]')
```

**When to use each:**

- `multipass shell`: Quick interactive access, debugging
- `multipass exec`: Automation, scripting, CI/CD pipelines
- `ssh`: Port forwarding, advanced features, external access

## Cloud-Init Best Practices

### Configuration Design

#### Idempotency

Design cloud-init configurations to be idempotent (safe to run multiple times):

**Important caveat:** Some cloud-init modules are not fully idempotent. Design
your configurations to handle multiple executions when possible.

```yaml
#cloud-config

# Idempotent - can run multiple times safely
packages:
  - git
  - docker.io

# Idempotent - creates user only if doesn't exist
users:
  - name: developer
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash

# Be careful - may create duplicates
runcmd:
  - echo "export PATH=$PATH:/usr/local/bin" >> /home/ubuntu/.bashrc
```

**Better approach for runcmd:**

```yaml
runcmd:
  - |
    if ! grep -q "/usr/local/bin" /home/ubuntu/.bashrc; then
      echo "export PATH=$PATH:/usr/local/bin" >> /home/ubuntu/.bashrc
    fi
```

#### YAML Syntax Requirements

Cloud-init is extremely sensitive to YAML formatting:

- Use **spaces for indentation** (not tabs)
- Maintain consistent indentation (2 or 4 spaces)
- First line must be `#cloud-config`
- Use YAML version 1.1 syntax

```yaml
#cloud-config

# Correct indentation
packages:
  - package1
  - package2

# List format
runcmd:
  - command1
  - command2

# Dictionary format
write_files:
  - path: /etc/example.conf
    content: |
      Line 1
      Line 2
    permissions: '0644'
```

#### Module Organization

Use cloud-init modules appropriately:

- **packages:** Package installation (preferred over apt commands)
- **users:** User creation and configuration
- **write_files:** Create files with specific content
- **runcmd:** Run commands after other modules complete
- **bootcmd:** Run commands early in boot (before networking)

```yaml
#cloud-config

# Use packages module (best practice)
packages:
  - git
  - curl
  - build-essential

# Not this (less maintainable)
runcmd:
  - apt-get update
  - apt-get install -y git curl build-essential
```

#### Configuration Structure

Organize complex configurations with `#include` directives:

```yaml
#cloud-config

# Main configuration
#include
  - base-packages.yaml
  - development-tools.yaml
  - security-hardening.yaml
```

**Benefits:**

- Modular, reusable components
- Easier to maintain
- Version control individual pieces
- Mix and match for different scenarios

### Security Standards

#### Never Hardcode Secrets

**CRITICAL:** Never include passwords or sensitive data in cloud-init files:

```yaml
#cloud-config

# WRONG - hardcoded password
users:
  - name: admin
    passwd: $6$rounds=4096$saltsalt$hashedhashed
    lock_passwd: false

# RIGHT - use SSH keys
users:
  - name: admin
    ssh_authorized_keys:
      - ssh-rsa AAAAB3NzaC1yc2E... user@host
    lock_passwd: true
```

#### External Secret Management

Use proper secret management services:

- AWS Secrets Manager
- Azure Key Vault
- HashiCorp Vault
- Google Secret Manager

```yaml
#cloud-config

runcmd:
  # Fetch secrets at runtime from secure storage
  - |
    aws secretsmanager get-secret-value \
      --secret-id db-password \
      --query SecretString \
      --output text > /etc/db-password
  - chmod 600 /etc/db-password
```

#### Input Validation

Validate user data before processing:

```yaml
#cloud-config

runcmd:
  - |
    # Validate input before use
    if [[ ! "$HOSTNAME" =~ ^[a-z0-9-]+$ ]]; then
      echo "Invalid hostname format"
      exit 1
    fi
    hostnamectl set-hostname "$HOSTNAME"
```

#### Logging Best Practices

Enable verbose logging for debugging but avoid logging sensitive data:

```yaml
#cloud-config

# Good - log command execution
runcmd:
  - echo "Starting database setup..." | tee -a /var/log/setup.log
  - apt-get install -y postgresql | tee -a /var/log/setup.log

# Bad - logs sensitive data
runcmd:
  - echo "Database password: $DB_PASS" >> /var/log/setup.log
```

### Development Workflow

#### Validation Before Deployment

Always validate cloud-init YAML before deployment:

```bash
# Validate syntax and schema
cloud-init schema --config-file cloud-config.yaml

# Annotated validation output
cloud-init schema --config-file cloud-config.yaml --annotate

# Validate network configuration
cloud-init schema --config-file network-config.yaml --annotate
```

Use YAML linting tools for additional validation:

```bash
# Install yamllint
sudo apt install yamllint

# Lint cloud-init file
yamllint cloud-config.yaml
```

#### Testing Workflow

Test cloud-init configurations in non-production environments:

1. Validate YAML syntax locally
2. Test with Multipass in isolated instance
3. Review logs for errors
4. Verify expected state
5. Iterate and refine
6. Deploy to production

```bash
# Test configuration
multipass launch --name test-cloud-init --cloud-init cloud-config.yaml

# Check cloud-init status
multipass exec test-cloud-init -- cloud-init status

# Review logs
multipass exec test-cloud-init -- cat /var/log/cloud-init.log

# Clean up after testing
multipass delete test-cloud-init && multipass purge
```

#### Iterative Development

Use `cloud-init clean` to re-run configurations during development:

```bash
# Inside instance - clean and reboot to re-run cloud-init
sudo cloud-init clean --logs --reboot

# Or clean without reboot
sudo cloud-init clean --logs

# Re-run specific modules
sudo cloud-init single --name package-update-upgrade-install
```

**Note:** Some modules are not idempotent - mileage may vary when re-running.

#### Version Control

Maintain cloud-init configurations in version control:

```bash
# Git repository structure
cloud-init/
├── base/
│   ├── packages.yaml
│   └── users.yaml
├── environments/
│   ├── dev.yaml
│   ├── staging.yaml
│   └── production.yaml
└── modules/
    ├── docker.yaml
    ├── nodejs.yaml
    └── python.yaml
```

#### Documentation

Comment your cloud-init configurations:

```yaml
#cloud-config

# Install base development tools
# Required for building native Node.js modules
packages:
  - build-essential
  - python3-dev

# Create developer user with sudo access
# Used by CI/CD pipeline
users:
  - name: developer
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    # SSH key from GitHub Actions
    ssh_authorized_keys:
      - ssh-rsa AAAAB3...
```

### Troubleshooting

#### Check Cloud-Init Status

Verify cloud-init execution status:

```bash
# Check overall status
cloud-init status

# Detailed status
cloud-init status --long

# Wait for completion (useful in scripts)
cloud-init status --wait
```

#### Review Logs

Cloud-init logs are essential for debugging:

```bash
# Main cloud-init log (detailed)
sudo cat /var/log/cloud-init.log

# Command output log (stdout/stderr)
sudo cat /var/log/cloud-init-output.log

# Follow logs in real-time
sudo tail -f /var/log/cloud-init.log

# Search for errors
sudo grep -i error /var/log/cloud-init.log
```

#### Common Issues

**YAML syntax errors:**

```bash
# Error message
Cloud config schema errors: format-l2: File cloud-config.yaml is not valid yaml

# Solution: Validate YAML
cloud-init schema --config-file cloud-config.yaml --annotate
```

**Module failures:**

```bash
# Check which modules ran
cloud-init analyze show

# Check module timing
cloud-init analyze dump

# Re-run failed module
sudo cloud-init single --name <module-name>
```

**Network issues:**

```bash
# Check network configuration
cloud-init query ds

# Verify network is ready
cloud-init status --wait
```

#### Debug Mode

Enable debug logging for detailed troubleshooting:

```yaml
#cloud-config

# Enable debug logging
debug: true

# Or via kernel command line
# Add to grub: cloud-init.debug=1
```

## Additional Resources

### Official Documentation

- **Multipass:** <https://multipass.run/docs>
- **Cloud-Init:** <https://cloudinit.readthedocs.io/>
- **Ubuntu Cloud-Init Guide:** <https://ubuntu.com/blog/using-cloud-init-with-multipass>

### Community Resources

- **Multipass Discourse:** <https://discourse.ubuntu.com/c/multipass/>
- **Cloud-Init Examples:** <https://cloudinit.readthedocs.io/en/latest/reference/examples.html>
- **GitHub Issues:** <https://github.com/canonical/multipass/issues>

### Tools

- **Schema Validator:** `cloud-init schema`
- **YAML Linter:** `yamllint`
- **Status Checker:** `cloud-init status`
- **Log Analyzer:** `cloud-init analyze`

## Summary

### Key Takeaways

**Multipass:**

- Name instances descriptively
- Specify resources at launch
- Use cloud-init for automation (not blueprints - deprecated)
- Mount host directories for persistent data
- Understand mount security implications
- Monitor resources regularly
- Stop unused instances

**Cloud-Init:**

- Multipass only supports YAML format
- Design for idempotency (with caveats)
- Never hardcode secrets
- Use modules appropriately
- Validate before deployment
- Test in non-production first
- Version control configurations
- Review logs for debugging

**Security:**

- SSH keys, not passwords
- External secret management
- Validate all inputs
- Understand mount privileges
- Review platform-specific restrictions
- Enable logging (avoid sensitive data)

By following these best practices, you'll create reliable, secure, and
maintainable Multipass and cloud-init configurations.

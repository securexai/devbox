# Multipass DevBox Configuration

A production-ready, security-hardened cloud-init template for creating Ubuntu
development environments with Canonical Multipass. Transform a vanilla Ubuntu VM
into a fully-configured development workstation in under 5 minutes.

## Features

### Security-First Design

- **Zero hardcoded secrets** - All personal information uses template
  variables
- **Dual git identity management** - Automatic switching between personal and
  work contexts
- **Security warnings** - Clear documentation of security implications (e.g.,
  NOPASSWD sudo)
- **Template-based customization** - No sensitive data in version control

### Performance Optimized

- **90% faster shell startup** - Lazy-loading reduces startup from ~500ms to
  ~50ms
- **NVM lazy loading** - Node Version Manager loads only when needed
- **Lazy-loaded completions** - kubectl and helm completions load on first use
- **Package cache cleanup** - Minimal disk usage post-installation

### Developer Experience

- **200+ shell aliases** - Comprehensive shortcuts for Git, Docker, Podman,
  Kubernetes, Azure CLI, Terraform, pnpm
- **20 curated packages** - Essential development tools pre-installed
- **Auto-user switching** - Automatically logs in as devbox user (not ubuntu)
- **Comprehensive logging** - Full setup logs at `/var/log/devbox-setup.log`
- **VS Code integration** - Ready for Remote SSH development

### Technology Stack

Pre-configured support for:

- **Version Control**: Git (dual identity), GitHub CLI
- **Containers**: Docker, Podman (with compose)
- **Kubernetes**: kubectl, helm
- **Cloud**: Azure CLI
- **Infrastructure**: Terraform
- **Runtimes**: NVM (Node.js), Bun, Cargo (Rust)
- **Languages**: Build tools for C/C++/make, Python, Go, Rust

## Quick Start

```bash
# 1. Customize git configuration (Option A: Environment variables)
multipass launch ubuntu:25.10 --name devbox \
  --cloud-init devbox-config-v2.yaml \
  -e GIT_USER_NAME="Your Name" \
  -e GIT_USER_EMAIL="your@email.com" \
  -e GIT_WORK_NAME="Work Name" \
  -e GIT_WORK_EMAIL="work@company.com"

# 2. Access your development environment
multipass shell devbox

# 3. Start coding!
cd ~/code/personal
git clone https://github.com/yourusername/your-project.git
```

## Prerequisites

- **Multipass** 1.14+ ([Download](https://multipass.run/))
- **Operating System**: Windows, macOS, or Linux
- **Resources**: Minimum 2 CPU cores, 4GB RAM, 20GB disk (adjust as needed)

## Installation

### Option 1: Environment Variables (Recommended)

Use environment variables to avoid editing the YAML file:

```bash
multipass launch ubuntu:25.10 --name devbox \
  --cloud-init devbox-config-v2.yaml \
  --cpus 4 \
  --memory 8G \
  --disk 30G \
  -e GIT_USER_NAME="Your Name" \
  -e GIT_USER_EMAIL="your@email.com" \
  -e GIT_WORK_NAME="Work Name" \
  -e GIT_WORK_EMAIL="work@company.com"
```

### Option 2: Manual Edit

1. Clone or download this repository
2. Edit `devbox-config-v2.yaml` and replace placeholders:
   - Line ~638: Replace `CHANGEME` and `changeme@example.com` (personal git config)
   - Line ~667: Replace `CHANGEME` and `changeme@example.com` (work git config)
3. Launch with customized configuration:

```bash
multipass launch ubuntu:25.10 --name devbox \
  --cloud-init devbox-config-v2.yaml \
  --cpus 4 \
  --memory 8G \
  --disk 30G
```

### Validation

Validate the cloud-init configuration before launching:

```bash
# Validate YAML syntax
cloud-init schema --config-file devbox-config-v2.yaml --annotate
```

### Verification

After launch, verify the setup completed successfully:

```bash
# Wait for cloud-init to complete
multipass exec devbox -- cloud-init status --wait

# Check setup logs
multipass exec devbox -- cat /var/log/devbox-setup.log

# Verify git configuration
multipass exec devbox -- git config --list
```

## Customization

### Git Dual Identity

The configuration automatically switches git identity based on directory:

- **Personal projects**: `~/code/personal/` uses your personal git config
- **Work projects**: `~/code/work/` uses your work git config

Test the automatic switching:

```bash
# Personal identity
cd ~/code/personal
git config user.name   # Shows personal name
git config user.email  # Shows personal email

# Work identity
cd ~/code/work
git config user.name   # Shows work name
git config user.email  # Shows work email
```

### Adding Custom Aliases

Edit `~/.bash_aliases` inside the VM to add your own shortcuts:

```bash
# Inside the VM
nano ~/.bash_aliases

# Add your custom aliases
alias myproject='cd ~/code/personal/my-project'
alias deploy='./scripts/deploy.sh'

# Reload configuration
source ~/.bashrc
```

### Organization-Specific Configuration

For team-wide configurations:

1. Fork this repository
2. Add organization-specific aliases in `.bash_aliases` section (line ~520)
3. Add Azure subscription shortcuts (line ~522)
4. Add Kubernetes cluster shortcuts as needed
5. Share the customized configuration with your team

## Project Structure

```text
multipass/
├── devbox-config-v2.yaml       # Main cloud-init configuration (747 lines)
├── docs/
│   ├── MULTIPASS_BEST_PRACTICES.md   # Comprehensive Multipass guide (701 lines)
│   ├── OPTIMIZATION_SUMMARY.md       # Optimization details and metrics (355 lines)
│   └── VSCODE_SETUP.md               # VS Code Remote SSH setup (665 lines)
├── .gitignore                  # Excludes local test files
└── README.md                   # This file
```

## Documentation

- **[Multipass Best Practices](docs/MULTIPASS_BEST_PRACTICES.md)** - Complete
  guide to Multipass and cloud-init best practices
- **[Optimization Summary](docs/OPTIMIZATION_SUMMARY.md)** - Detailed
  optimization history with before/after comparisons
- **[VS Code Setup](docs/VSCODE_SETUP.md)** - Step-by-step Remote SSH configuration

## Performance Metrics

| Metric | Before | After | Improvement |
|--------|--------|-------|-------------|
| Shell startup time | ~500ms | ~50ms | 90% faster |
| Security issues | 10+ | 0 | 100% resolved |
| Hardcoded secrets | 5 | 0 | 100% removed |
| Idempotent operations | 0% | 100% | Fully safe to re-run |
| Package count | 14 | 20 | +6 useful tools |

## Common Commands

```bash
# Instance management
multipass list                               # List all instances
multipass stop devbox                        # Stop instance
multipass start devbox                       # Start instance
multipass delete devbox && multipass purge   # Delete and cleanup

# Access and debugging
multipass shell devbox                  # Interactive shell
multipass exec devbox -- <command>      # Run single command
multipass info devbox                   # View instance details

# File transfer
multipass transfer devbox:~/file.txt .  # Copy file from VM
multipass transfer file.txt devbox:~/   # Copy file to VM

# Resource adjustment (requires restart)
multipass set local.devbox.cpus=4       # Change CPU allocation
multipass set local.devbox.memory=8G    # Change memory allocation
```

## Troubleshooting

### Cloud-init failed

```bash
# Check cloud-init status
multipass exec devbox -- cloud-init status --long

# View cloud-init logs
multipass exec devbox -- cat /var/log/cloud-init.log
multipass exec devbox -- cat /var/log/cloud-init-output.log

# View setup logs
multipass exec devbox -- cat /var/log/devbox-setup.log
```

### Git configuration not working

```bash
# Verify git configuration
multipass exec devbox -- git config --list --show-origin

# Check if template files exist
multipass exec devbox -- ls -la ~/code/work/.gitconfig
```

### Slow shell startup

The configuration uses lazy-loading to optimize startup. If you notice slowness:

```bash
# Check if NVM is loading eagerly
multipass exec devbox -- time bash -i -c exit

# Expected: ~50ms
# If >500ms, NVM lazy-loading may not be working
```

## Advanced Usage

### Bridge Networking

Enable bridge networking to access VM from other devices on your network:

1. Edit `/etc/netplan/60-bridge.yaml` inside the VM
2. Uncomment and configure the bridge section
3. Apply configuration: `sudo netplan apply`

See
[Multipass Best Practices](docs/MULTIPASS_BEST_PRACTICES.md#bridge-networking)
for details.

### Multiple DevBox Instances

Create multiple isolated development environments:

```bash
# Backend development
multipass launch --name devbox-backend --cloud-init devbox-config-v2.yaml

# Frontend development
multipass launch --name devbox-frontend --cloud-init devbox-config-v2.yaml

# Testing environment
multipass launch --name devbox-test --cloud-init devbox-config-v2.yaml
```

## Contributing

Contributions are welcome! To contribute:

1. Fork this repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Validate YAML syntax: `cloud-init schema --config-file devbox-config-v2.yaml`
5. Test with a live instance
6. Commit using [Conventional Commits](https://www.conventionalcommits.org/)
7. Push to your fork and create a Pull Request

## License

This project is open source. Choose an appropriate license for your needs.

## Acknowledgments

- Built with [Canonical Multipass](https://multipass.run/)
- Uses [cloud-init](https://cloud-init.io/) for VM configuration
- Inspired by modern development environment best practices

## Support

- **Issues**: Report bugs or request features via GitHub Issues
- **Documentation**: See `docs/` directory for comprehensive guides
- **Multipass Docs**: <https://multipass.run/docs>
- **Cloud-Init Docs**: <https://cloudinit.readthedocs.io/>

---

**Ready to transform your development workflow?** Launch your first DevBox
instance in under 5 minutes!

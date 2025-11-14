# Multipass cloudops Configuration

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
- **Auto-user switching** - Automatically logs in as cloudops user (not ubuntu)
- **Comprehensive logging** - Full setup logs at `/var/log/cloudops-setup.log`
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
- **Development Environments**: Nix, Jetify Devbox

### Devbox Integration

Create isolated, reproducible development environments with **Jetify Devbox**:

- **Nix-powered**: Reproducible package management via Determinate Systems Nix
- **Fast caching**: 25-35% Nix store size reduction with auto-optimization
- **Global tools**: Pre-installed jq, yq, gh accessible in all shells
- **Templates included**: 5 ready-to-use devbox.json templates for common stacks
- **Zero configuration**: devbox global shellenv auto-activated in .bashrc

**Available Templates:**

- `nodejs-webapp.json` - Node.js 22 + pnpm + TypeScript
- `python-api.json` - Python 3.12 + Poetry for FastAPI/Flask
- `go-service.json` - Go 1.23 + air for hot reload
- `rust-cli.json` - Rust 1.85 + cargo + rust-analyzer
- `fullstack.json` - Multi-language with PostgreSQL + Redis

**Quick Start with Devbox:**

```bash
# Access the VM
multipass shell cloudops

# Create a new Node.js project from template
mkdir my-app && cd my-app
cp ~/.devbox-templates/nodejs-webapp.json devbox.json
devbox shell  # Enter isolated environment with Node.js 22

# Or initialize from scratch
devbox init
devbox add nodejs@22.14.0 pnpm@10.11.0
devbox shell

# Read the quickstart guide in the VM
cat ~/.devbox-quickstart.md
```

**Key Benefits:**

- **Project isolation**: Each project has its own package environment
- **Team reproducibility**: Share devbox.json, everyone gets identical setup
- **Fast installations**: Nix caching makes repeated installs 10-30 seconds
- **No conflicts**: Multiple Node/Python/Go versions on same machine
- **Minimal disk usage**: ~3.6GB total (Nix + Devbox + global tools)

**Learn More:**

- **[Complete Devbox Guide](docs/DEVBOX_GUIDE.md)** - Comprehensive tutorial
  with examples, workflows, and troubleshooting

## Quick Start

```bash
# 1. Customize git configuration (Option A: Environment variables)
multipass launch ubuntu:25.10 --name cloudops \
  --cloud-init cloudops-config-v2.yaml \
  -e GIT_USER_NAME="Your Name" \
  -e GIT_USER_EMAIL="your@email.com" \
  -e GIT_WORK_NAME="Work Name" \
  -e GIT_WORK_EMAIL="work@company.com"

# 2. Access your development environment
multipass shell cloudops

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
multipass launch ubuntu:25.10 --name cloudops \
  --cloud-init cloudops-config-v2.yaml \
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
2. Edit `cloudops-config-v2.yaml` and replace placeholders:
   - Line ~638: Replace `CHANGEME` and `changeme@example.com` (personal git config)
   - Line ~667: Replace `CHANGEME` and `changeme@example.com` (work git config)
3. Launch with customized configuration:

```bash
multipass launch ubuntu:25.10 --name cloudops \
  --cloud-init cloudops-config-v2.yaml \
  --cpus 4 \
  --memory 8G \
  --disk 30G
```

### Validation

Validate the cloud-init configuration before launching:

```bash
# Validate YAML syntax
cloud-init schema --config-file cloudops-config-v2.yaml --annotate
```

### Verification

After launch, verify the setup completed successfully:

```bash
# Wait for cloud-init to complete
multipass exec cloudops -- cloud-init status --wait

# Check setup logs
multipass exec cloudops -- cat /var/log/cloudops-setup.log

# Verify git configuration
multipass exec cloudops -- git config --list
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
├── cloudops-config-v2.yaml           # Main cloud-init configuration
├── docs/
│   ├── DEVBOX_GUIDE.md               # Complete Devbox tutorial and reference
│   ├── MULTIPASS_BEST_PRACTICES.md   # Comprehensive Multipass guide
│   ├── OPTIMIZATION_SUMMARY.md       # Optimization details and metrics
│   └── VSCODE_SETUP.md               # VS Code Remote SSH setup
├── .gitignore                        # Excludes local test files
└── README.md                         # This file
```

## Documentation

- **[Devbox Guide](docs/DEVBOX_GUIDE.md)** - Comprehensive tutorial for isolated
  development environments with templates, workflows, and troubleshooting
- **[Multipass Best Practices](docs/MULTIPASS_BEST_PRACTICES.md)** - Complete
  guide to Multipass and cloud-init best practices
- **[Optimization Summary](docs/OPTIMIZATION_SUMMARY.md)** - Detailed
  optimization history with before/after comparisons
- **[VS Code Setup](docs/VSCODE_SETUP.md)** - Step-by-step Remote SSH configuration

## Performance Metrics

| Metric                | Before | After | Improvement          |
| --------------------- | ------ | ----- | -------------------- |
| Shell startup time    | ~500ms | ~50ms | 90% faster           |
| Security issues       | 10+    | 0     | 100% resolved        |
| Hardcoded secrets     | 5      | 0     | 100% removed         |
| Idempotent operations | 0%     | 100%  | Fully safe to re-run |
| Package count         | 14     | 20    | +6 useful tools      |

## Common Commands

```bash
# Instance management
multipass list                               # List all instances
multipass stop cloudops                        # Stop instance
multipass start cloudops                       # Start instance
multipass delete cloudops && multipass purge   # Delete and cleanup

# Access and debugging
multipass shell cloudops                  # Interactive shell
multipass exec cloudops -- <command>      # Run single command
multipass info cloudops                   # View instance details

# File transfer
multipass transfer cloudops:~/file.txt .  # Copy file from VM
multipass transfer file.txt cloudops:~/   # Copy file to VM

# Resource adjustment (requires restart)
multipass set local.cloudops.cpus=4       # Change CPU allocation
multipass set local.cloudops.memory=8G    # Change memory allocation
```

## Troubleshooting

### Cloud-init failed

```bash
# Check cloud-init status
multipass exec cloudops -- cloud-init status --long

# View cloud-init logs
multipass exec cloudops -- cat /var/log/cloud-init.log
multipass exec cloudops -- cat /var/log/cloud-init-output.log

# View setup logs
multipass exec cloudops -- cat /var/log/cloudops-setup.log
```

### Schema validation warnings about permissions

If you see cloud-init schema errors like
`write_files.*.permissions: 420 is not of type 'string'`, this is a
**known issue** with Multipass YAML processing.

**Root cause**: Multipass strips quotes from YAML values before passing to
cloud-init, causing permissions fields to be interpreted as integers instead
of strings.

**Resolution**: This project uses explicit `chmod` commands in `runcmd` instead
of the `permissions:` field to avoid this issue. The configuration will work
correctly despite the warning.

**Verification**:

```bash
# Verify schema validation passes with current configuration
multipass exec cloudops -- sudo cloud-init schema --system

# Check file permissions are correct
multipass exec cloudops -- ls -la /home/cloudops/.bashrc
# Should show: -rw-r--r-- (644)
```

**For details**, see [CLAUDE.md Known Issues section](CLAUDE.md#known-issues).

### Git configuration not working

```bash
# Verify git configuration
multipass exec cloudops -- git config --list --show-origin

# Check if template files exist
multipass exec cloudops -- ls -la ~/code/work/.gitconfig
```

### Slow shell startup

The configuration uses lazy-loading to optimize startup. If you notice slowness:

```bash
# Check if NVM is loading eagerly
multipass exec cloudops -- time bash -i -c exit

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

### Multiple cloudops Instances

Create multiple isolated development environments:

```bash
# Backend development
multipass launch --name cloudops-backend --cloud-init cloudops-config-v2.yaml

# Frontend development
multipass launch --name cloudops-frontend --cloud-init cloudops-config-v2.yaml

# Testing environment
multipass launch --name cloudops-test --cloud-init cloudops-config-v2.yaml
```

## Contributing

Contributions are welcome! To contribute:

1. Fork this repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Validate YAML syntax: `cloud-init schema --config-file cloudops-config-v2.yaml`
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

**Ready to transform your development workflow?** Launch your first cloudops
instance in under 5 minutes!

# Multipass DevBox Configuration

A minimal, optimized Ubuntu 25.10 development environment using Multipass and
cloud-init, designed for consistent, reproducible development workflows with
per-project tool isolation via Devbox.

## Philosophy

This configuration embraces **true minimalism**: the VM provides only essential
system utilities and Devbox. Each project brings its own tools via
`devbox.json`, eliminating version conflicts and global runtime pollution.

## Key Features

### Minimal Footprint

- Snapd removed: ~200MB RAM saved
- Aggressive cleanup commands
- Alpine-inspired minimalism for VMs
- Startup optimization with lazy-loading completions

### System Optimizations

Kernel tuning for development workloads:

- `vm.swappiness=10`: Minimize swap usage
- `vm.vfs_cache_pressure=50`: Improve filesystem cache
- `fs.inotify.max_user_watches=524288`: Support large projects with file
  watchers

### Devbox Integration

[Devbox](https://www.jetpack.io/devbox) provides per-project development
environments without global runtimes:

- **Project isolation**: Each project defines its own toolchain
- **Reproducibility**: Same versions across team members and CI/CD
- **Zero conflicts**: No global Node.js, Python, Go, etc.
- **Fast switching**: Instant environment activation with `devbox shell`

### Dual SSH Identity

Pre-generated SSH keys for work and personal use:

- **Work**: RSA 4096-bit (`s.tapia@globant.com`)
- **Personal**: ed25519 (`github.com.valium091@passmail.com`)

### Git Dual-Identity

Automatic Git configuration switching based on directory:

- **Default**: Personal identity (`github.com.valium091@passmail.com`)
- **~/code/work/\*\***: Work identity (`s.tapia@globant.com`)

Configuration uses `includeIf` directive for seamless identity management.

### Extended Directory Structure

```
~/
├── code/
│   ├── work/        # Work projects (Git uses s.tapia@globant.com)
│   └── personal/    # Personal projects (Git uses personal email)
├── .kube/           # Kubernetes configurations
├── .local/bin/      # User binaries (Devbox, custom tools)
└── bin/             # Additional user scripts
```

### Custom Bash Configuration

- **Aliases**: 100+ productivity shortcuts for Git, Podman, Docker, Kubernetes,
  Azure, Terraform, pnpm, .NET
- **Completions**: Lazy-loaded kubectl and helm completions (improve startup
  time)
- **Colored prompt**: User-friendly shell experience
- **Tool initialization**: NVM, SDKMAN, Bun, Cargo environment setup

### Schema Validation

All cloud-init validation errors resolved, including workaround for YAML 1.1
octal parsing bug in older cloud-init versions.

## Prerequisites

### Install Multipass

**macOS:**

```bash
brew install multipass
```

**Windows:**

```powershell
# Download from: https://multipass.run/install
# Or use Chocolatey:
choco install multipass
```

**Linux:**

```bash
snap install multipass
```

### System Requirements

- **Memory**: 2GB minimum (tested and verified)
- **Disk**: 20GB
- **CPUs**: 2

## Quick Start

### 1. Launch VM

```bash
multipass launch \
  --name devbox \
  --memory 2G \
  --disk 20G \
  --cpus 2 \
  --cloud-init devbox-config-v2.yaml \
  25.10
```

**Note**: Replace `25.10` with your desired Ubuntu version if needed.

### 2. Access VM

```bash
multipass shell devbox
```

The VM automatically switches from the default `ubuntu` user to the `devbox`
user upon first login.

### 3. Retrieve SSH Keys

```bash
cat ~/.setup-complete
```

This file contains your generated SSH public keys:

- Work: RSA 4096-bit
- Personal: ed25519

Add these keys to your GitHub, GitLab, or other Git hosting services.

### 4. Start Development

#### Initialize a New Project

```bash
# Create project directory
mkdir -p ~/code/work/my-project
cd ~/code/work/my-project

# Initialize Devbox
devbox init

# Add project tools (examples)
devbox add nodejs@20 pnpm@latest rust@latest

# Enter isolated environment
devbox shell

# Verify tools are available
node --version
pnpm --version
cargo --version
```

#### Clone Existing Project with Devbox

```bash
# Clone repository
cd ~/code/personal
git clone https://github.com/user/project.git
cd project

# If project has devbox.json, simply run:
devbox shell

# Devbox automatically installs declared tools
```

## Configuration Details

### User Configuration

- **Username**: `devbox`
- **Shell**: `/bin/bash`
- **Sudo**: Passwordless sudo access
- **Groups**: `adm`, `cdrom`, `dip`, `plugdev`, `sudo`

### Installed Packages

Minimal system utilities only:

- `build-essential`: C/C++ compiler toolchain
- `ca-certificates`: SSL/TLS certificates
- `curl`, `wget`: HTTP clients
- `gh`: GitHub CLI
- `git`: Version control
- `gnupg`: GPG encryption
- `language-pack-es`, `locales`: Spanish language support
- `lsb-release`: Linux Standard Base info
- `nano`: Text editor
- `openssh-client`, `openssh-server`: SSH support
- `software-properties-common`: PPA management
- `unzip`: Archive extraction

**Note**: No global runtimes (Node.js, Python, Go, etc.) are installed.
Projects provide their own via Devbox.

### System Configuration Files

#### /etc/sysctl.d/99-devbox.conf

Kernel optimization for development workloads:

```ini
vm.swappiness=10
vm.vfs_cache_pressure=50
fs.inotify.max_user_watches=524288
```

Apply changes: `sudo sysctl --system`

#### /etc/netplan/60-bridge.yaml

Commented template for optional bridge networking configuration. Useful for
exposing VM services to your local network.

### Git Configuration

#### Global (~/.gitconfig)

```ini
[user]
    name = Securexai
    email = github.com.valium091@passmail.com

[includeIf "gitdir/i:~/code/work/**"]
    path = ~/code/work/.gitconfig

[core]
    editor = code --wait
    autocrlf = input

[init]
    defaultBranch = main

[pull]
    rebase = true

[push]
    default = current
    autoSetupRemote = true
```

#### Work Override (~/code/work/.gitconfig)

```ini
[user]
    name = Sergio Tapia
    email = s.tapia@globant.com
```

Any Git repository under `~/code/work/` automatically uses the work identity.

### SSH Key Details

#### Work Key (RSA 4096-bit)

- **Path**: `~/.ssh/id_rsa` (private), `~/.ssh/id_rsa.pub` (public)
- **Comment**: `s.tapia@globant.com`
- **Use case**: Corporate Git repositories, work servers

#### Personal Key (ed25519)

- **Path**: `~/.ssh/id_ed25519_personal` (private),
  `~/.ssh/id_ed25519_personal.pub` (public)
- **Comment**: `github.com.valium091@passmail.com`
- **Use case**: Personal GitHub, GitLab, or other services

#### SSH Config Example

To use different keys for different hosts, create `~/.ssh/config`:

```ssh-config
# Work GitHub
Host github.com-work
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_rsa

# Personal GitHub
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519_personal
```

Clone work repositories with:

```bash
git clone git@github.com-work:company/repo.git
```

### Bash Aliases

The configuration includes 100+ productivity aliases. Key categories:

#### Navigation & Safety

```bash
..          # cd ..
...         # cd ../..
rm='rm -i'  # Interactive deletion
```

#### Git Shortcuts

```bash
gs          # git status
gaa         # git add --all
gcm         # git commit -m
gp          # git push
glog        # git log --oneline --graph --decorate
```

#### Container Tools

```bash
# Docker
dps         # docker ps
dimg        # docker images
dexec       # docker exec -it

# Podman
pps         # podman ps
pimg        # podman images
pexec       # podman exec -it
```

#### Kubernetes

```bash
k           # kubectl
kgp         # kubectl get pods
klog        # kubectl logs
kexec       # kubectl exec -it
```

#### Terraform

```bash
tf          # terraform
tfinit      # terraform init
tfplan      # terraform plan
tfapply     # terraform apply
```

View full list: `cat ~/.bash_aliases`

## Devbox Usage Guide

### Core Commands

```bash
# Initialize Devbox in current directory
devbox init

# Add packages
devbox add nodejs@20 python@3.12 rust@latest

# Remove packages
devbox remove nodejs

# List installed packages
devbox info

# Update packages
devbox update

# Enter isolated shell with all tools
devbox shell

# Run command in Devbox environment
devbox run npm install
devbox run cargo build
```

### Example: Node.js Project

```bash
cd ~/code/work/my-app
devbox init
devbox add nodejs@20 pnpm@latest

# Create devbox.json
cat > devbox.json <<EOF
{
  "packages": ["nodejs@20", "pnpm@latest"],
  "shell": {
    "init_hook": ["echo 'Node.js $(node --version) ready!'"]
  }
}
EOF

# Enter environment
devbox shell

# Install dependencies
pnpm install

# Run development server
pnpm dev
```

### Example: Python Project

```bash
cd ~/code/personal/ml-project
devbox init
devbox add python@3.12

# Create devbox.json
cat > devbox.json <<EOF
{
  "packages": ["python@3.12"],
  "shell": {
    "init_hook": [
      "python -m venv .venv",
      "source .venv/bin/activate"
    ]
  }
}
EOF

devbox shell
pip install -r requirements.txt
python main.py
```

### Example: Multi-Language Project

```bash
cd ~/code/work/fullstack-app
devbox init
devbox add nodejs@20 go@1.22 postgresql@16

devbox shell

# Now you have Node.js, Go, and PostgreSQL available
node --version
go version
psql --version
```

### devbox.json Configuration

Projects commit `devbox.json` to version control for team consistency:

```json
{
  "packages": [
    "nodejs@20",
    "pnpm@latest",
    "rust@latest"
  ],
  "shell": {
    "init_hook": [
      "echo 'Development environment loaded!'",
      "pnpm install"
    ],
    "scripts": {
      "dev": "pnpm dev",
      "build": "pnpm build",
      "test": "pnpm test"
    }
  }
}
```

Team members run `devbox shell` and get identical environments.

## Customization

### Modify Cloud-Init Configuration

Edit `devbox-config-v2.yaml` to customize:

- **Hostname**: Change `hostname: devbox` (line 4)
- **Timezone**: Change `timezone: America/Bogota` (line 5)
- **Locale**: Change `locale: es_CO.UTF-8` (line 6)
- **Packages**: Add/remove from `packages` section (lines 18-33)
- **Git identity**: Update user name and email (lines 592-594, 619-621)
- **SSH key comments**: Update email addresses (lines 675-677)
- **Bash aliases**: Modify `~/.bash_aliases` section (lines 266-586)

After making changes, destroy and recreate the VM:

```bash
multipass delete devbox
multipass purge
multipass launch --name devbox --memory 2G --disk 20G --cpus 2 \
  --cloud-init devbox-config-v2.yaml 25.10
```

### Add Custom Packages

To install additional system packages after VM creation:

```bash
multipass shell devbox
sudo apt update
sudo apt install <package-name>
```

**Note**: For development tools, prefer adding via Devbox instead of
system-wide installation.

### Increase VM Resources

```bash
# Stop VM
multipass stop devbox

# Increase memory to 4GB
multipass set local.devbox.memory=4G

# Increase CPUs to 4
multipass set local.devbox.cpus=4

# Restart VM
multipass start devbox
```

**Note**: Disk size cannot be changed after creation.

### Enable Bridge Networking

To expose VM services to your local network:

1. SSH into VM: `multipass shell devbox`
2. Edit netplan: `sudo nano /etc/netplan/60-bridge.yaml`
3. Uncomment and configure bridge section:

```yaml
network:
  version: 2
  ethernets:
    eth0:
      dhcp4: false
      dhcp6: false
  bridges:
    br0:
      interfaces: [eth0]
      dhcp4: true
      # Or use static IP:
      # addresses: [192.168.1.100/24]
      # routes:
      #   - to: default
      #     via: 192.168.1.1
      # nameservers:
      #   addresses: [8.8.8.8, 8.8.4.4]
```

4. Apply configuration: `sudo netplan apply`

## Troubleshooting

### VM Fails to Start

Check Multipass status:

```bash
multipass list
multipass info devbox
```

View cloud-init logs:

```bash
multipass shell devbox
cat /var/log/cloud-init-output.log
```

### SSH Keys Not Generated

Verify setup completion:

```bash
multipass shell devbox
cat ~/.setup-complete
ls -la ~/.ssh/
```

If missing, manually generate:

```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -C "s.tapia@globant.com"
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_personal \
  -C "github.com.valium091@passmail.com"
```

### Devbox Not Found

Verify installation:

```bash
which devbox
devbox version
```

If missing, reinstall:

```bash
curl -fsSL https://get.jetify.com/devbox | bash -s -- -f
```

Add to PATH in `~/.bashrc`:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

Reload shell: `source ~/.bashrc`

### Git Identity Not Switching

Verify Git configuration:

```bash
# In ~/code/work/
git config user.name
git config user.email
# Should show: Sergio Tapia / s.tapia@globant.com

# In ~/code/personal/
git config user.name
git config user.email
# Should show: Securexai / github.com.valium091@passmail.com
```

Check includeIf path:

```bash
cat ~/.gitconfig | grep includeIf
cat ~/code/work/.gitconfig
```

### Low Memory Issues

Increase VM memory:

```bash
multipass stop devbox
multipass set local.devbox.memory=4G
multipass start devbox
```

Check memory usage inside VM:

```bash
multipass shell devbox
free -h
```

### Slow VM Performance

1. **Allocate more resources**:

```bash
multipass stop devbox
multipass set local.devbox.memory=4G
multipass set local.devbox.cpus=4
multipass start devbox
```

2. **Check host system resources**: Ensure your host machine has sufficient
   resources available.

3. **Verify kernel optimizations**:

```bash
multipass shell devbox
sysctl vm.swappiness
sysctl vm.vfs_cache_pressure
```

## Multipass Commands Reference

### VM Management

```bash
# List all VMs
multipass list

# Get VM details
multipass info devbox

# Start VM
multipass start devbox

# Stop VM
multipass stop devbox

# Restart VM
multipass restart devbox

# Delete VM
multipass delete devbox

# Permanently remove deleted VMs
multipass purge
```

### File Transfer

```bash
# Copy file to VM
multipass transfer /path/to/local/file devbox:/home/devbox/

# Copy file from VM
multipass transfer devbox:/home/devbox/file /path/to/local/
```

### Execute Commands

```bash
# Run command in VM
multipass exec devbox -- ls -la

# Run command as specific user
multipass exec devbox -- sudo -u devbox whoami
```

### VM Configuration

```bash
# Set memory (VM must be stopped)
multipass set local.devbox.memory=4G

# Set CPUs (VM must be stopped)
multipass set local.devbox.cpus=4

# View configuration
multipass get local.devbox.memory
multipass get local.devbox.cpus
```

## Best Practices

### 1. Use Devbox for All Project Tools

**Do:**

```bash
cd my-project
devbox add nodejs@20
devbox shell
```

**Don't:**

```bash
sudo apt install nodejs  # Pollutes global environment
```

### 2. Commit devbox.json to Version Control

Share exact tool versions with your team:

```bash
git add devbox.json
git commit -m "feat: add Devbox configuration"
```

### 3. Use Work Directory for Corporate Projects

This ensures correct Git identity:

```bash
mkdir -p ~/code/work/company-project
cd ~/code/work/company-project
git init
git config user.email  # Automatically s.tapia@globant.com
```

### 4. Organize Projects by Context

```
~/code/
├── work/
│   ├── project-a/
│   └── project-b/
└── personal/
    ├── hobby-project/
    └── open-source-contribution/
```

### 5. Keep VM Minimal

Let Devbox manage tools. Only install system utilities globally:

```bash
# Good: System utility
sudo apt install jq

# Bad: Development runtime (use Devbox instead)
sudo apt install python3-pip
```

### 6. Regular Snapshots (Optional)

Before major changes, create VM snapshots:

```bash
# Multipass doesn't have native snapshots, but you can:
# 1. Use your hypervisor's snapshot feature (VirtualBox, Hyper-V)
# 2. Export VM configuration and recreate from cloud-init
```

### 7. Resource Management

Monitor and adjust resources as needed:

```bash
multipass shell devbox
htop  # Install if needed: sudo apt install htop
```

## Project Structure Example

```
~/
├── code/
│   ├── work/
│   │   ├── backend-api/
│   │   │   ├── devbox.json        # Go, PostgreSQL, Redis
│   │   │   └── src/
│   │   └── frontend-app/
│   │       ├── devbox.json        # Node.js, pnpm
│   │       └── src/
│   └── personal/
│       ├── rust-cli/
│       │   ├── devbox.json        # Rust
│       │   └── src/
│       └── python-ml/
│           ├── devbox.json        # Python, Jupyter
│           └── notebooks/
├── .kube/
│   └── config                     # Kubernetes clusters
├── .local/
│   └── bin/
│       └── devbox                 # Devbox binary
└── bin/
    └── custom-script.sh           # User scripts
```

## Git Workflow with Dual Identity

### Work Project Example

```bash
cd ~/code/work/company-api
git init
git config user.name   # Output: Sergio Tapia
git config user.email  # Output: s.tapia@globant.com

git add .
git commit -m "feat: implement user authentication"
# Commit author: Sergio Tapia <s.tapia@globant.com>
```

### Personal Project Example

```bash
cd ~/code/personal/my-app
git init
git config user.name   # Output: Securexai
git config user.email  # Output: github.com.valium091@passmail.com

git add .
git commit -m "docs: update README"
# Commit author: Securexai <github.com.valium091@passmail.com>
```

## Version Control Conventions

This project follows Git Flow and Conventional Commits:

### Branch Strategy

- `main`: Production-ready code
- `develop`: Integration branch for features
- `feature/*`: New features
- `fix/*`: Bug fixes
- `hotfix/*`: Production hotfixes

### Commit Message Format

```
<type>(<scope>): <description>

[optional body]

[optional footer(s)]
```

**Types:**

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation only
- `style`: Code style (formatting)
- `refactor`: Code change that neither fixes bug nor adds feature
- `perf`: Performance improvement
- `test`: Adding or updating tests
- `build`: Build system or dependencies
- `ci`: CI configuration changes
- `chore`: Other changes

**Examples:**

```bash
git commit -m "feat(cloud-init): add Devbox integration"
git commit -m "fix(git): resolve dual identity switching"
git commit -m "docs(readme): add troubleshooting section"
```

## Security Considerations

### SSH Key Management

- Private keys (`id_rsa`, `id_ed25519_personal`) never leave the VM
- Only public keys are shared
- Keys use strong algorithms (RSA 4096-bit, ed25519)

### Sudo Access

- `devbox` user has passwordless sudo
- Suitable for development, **not for production**
- For production, require password: Edit cloud-init, change
  `sudo: ['ALL=(ALL) NOPASSWD:ALL']`

### Container Security

- No Docker/Podman installed by default (minimal footprint)
- Install via Devbox if needed: `devbox add docker podman`

### Network Security

- SSH server enabled by default
- Firewall not configured (development VM)
- For production: Enable UFW, configure firewall rules

## Performance Tuning

### Kernel Parameters

Applied via `/etc/sysctl.d/99-devbox.conf`:

- **vm.swappiness=10**: Reduces swap usage, keeps more in RAM
- **vm.vfs_cache_pressure=50**: Balances inode/dentry cache vs page cache
- **fs.inotify.max_user_watches=524288**: Supports large projects with file
  watchers (Webpack, Vite, etc.)

### Bash Optimizations

- Lazy-loaded completions (kubectl, helm)
- Conditional tool initialization (only load if installed)
- History settings optimized (10k commands, 20k filesize)

### Minimal Footprint

- Snapd removed: ~200MB RAM saved
- Aggressive apt cleanup: Reduced disk usage
- Only essential packages installed

## Additional Resources

- **Devbox Documentation**: <https://www.jetpack.io/devbox/docs/>
- **Multipass Documentation**: <https://multipass.run/docs>
- **Cloud-Init Documentation**: <https://cloudinit.readthedocs.io/>
- **Git Conditional Includes**:
  <https://git-scm.com/docs/git-config#_conditional_includes>
- **Conventional Commits**: <https://www.conventionalcommits.org/>
- **Git Flow**: <https://nvie.com/posts/a-successful-git-branching-model/>

## Contributing

This project follows Git Flow and Conventional Commits.

### Development Workflow

1. Fork or clone repository
2. Create feature branch: `git checkout -b feature/my-feature`
3. Make changes, test in Multipass VM
4. Commit with conventional format:
   `git commit -m "feat: add new feature"`
5. Push and create pull request

### Testing Changes

```bash
# Delete existing VM
multipass delete devbox
multipass purge

# Launch with modified configuration
multipass launch --name devbox --memory 2G --disk 20G --cpus 2 \
  --cloud-init devbox-config-v2.yaml 25.10

# Verify changes
multipass shell devbox
# Test specific features...
```

## License

This configuration is provided as-is for personal and professional use.

## Author

**Sergio Tapia** (s.tapia@globant.com)

## Acknowledgments

- **Devbox**: [jetpack.io](https://www.jetpack.io/) for excellent development
  environment management
- **Multipass**: Canonical for lightweight VM orchestration
- **Ubuntu**: For providing minimal, reliable base images

---

Generated with Claude Code.

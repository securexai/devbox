# Changelog

All notable changes to the CloudOps Multipass Development Environment project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [2.3.0] - 2025-11-15

### Changed
- **Architecture Simplification**: Removed global pnpm installation while maintaining per-project availability via Devbox
  - Removed `pnpm@10.20.0` from `devbox global add` command in cloudops-config-v2.yaml
  - Removed PNPM_HOME environment variable configuration from .bashrc
  - Removed pnpm setup block from runcmd cloud-init phase
  - Updated health check script to report pnpm as intentionally not globally installed
  - Updated maintenance scripts to remove pnpm version output from global tools
  - **Rationale**: Global pnpm installation was redundant with per-project Devbox configuration, added deployment time (30-60s), and introduced unnecessary failure points
  - **Impact**: pnpm remains fully available per-project by adding to devbox.json; existing projects with pnpm in devbox.json continue working unchanged

### Performance
- Faster VM deployment: 30-60 seconds saved during cloud-init provisioning
- Reduced Nix store size: No global pnpm packages to store
- Fewer failure points: Eliminated global pnpm installation step that could timeout or fail

### Documentation
- Updated DEVBOX_GUIDE.md to clarify pnpm availability model (per-project only)
- Updated README.md component table to show pnpm as "Per-Project via Devbox"
- Fixed TROUBLESHOOTING.md to accurately describe pnpm availability
- Updated MIGRATION.md with upgrade path from 2.2.0 to 2.3.0

### Testing
- Full deployment test: ✅ Completed successfully (2025-11-15 15:02:00 -05)
- Global packages verified: ✅ NO pnpm in global packages (as intended)
- Node.js: ✅ 24.11.0 working
- Claude CLI: ✅ 2.0.42 working
- Nix store size: ✅ 905M (similar to v2.2.0, no bloat)
- Health check: ✅ Correctly reports "pnpm is NOT globally installed (by design)"

### Technical Details
- **Alignment with Devbox Philosophy**: Devbox is designed for per-project dependency isolation; global pnpm conflicted with this model
- **Per-Project Usage**: Add pnpm to any project with `devbox add pnpm` in project directory
- **No Breaking Changes**: Existing projects with pnpm in devbox.json work identically
- **Backward Compatibility**: Users who need global pnpm can manually install with `devbox global add pnpm`

## [2.2.0] - 2025-11-15

### Added
- **Claude CLI Integration**: Global installation of Claude CLI (@anthropic-ai/claude-code v2.0.42) via npm
  - Installed globally via npm with custom prefix at `/home/cloudops/.local/share/npm`
  - Available everywhere without activation (added to PATH in .bashrc)
  - Maintenance scripts updated to support Claude CLI updates and health checks
  - Documentation and MOTD updated with Claude CLI usage instructions

### Changed
- **Installation Method**: Switched from pnpm to npm for Claude CLI installation
  - **Technical Context**: After 9 debugging iterations, resolved installation issues caused by pnpm's strict PATH validation in devbox environment
  - **Root Cause**: pnpm validates that global-bin-dir is in PATH before allowing `pnpm add -g`, which fails in devbox shell as environment doesn't inherit PNPM_HOME from .bashrc
  - **Solution**: Use npm with configured prefix instead, providing reliable automated installation
  - npm remains the only package manager for Claude CLI; pnpm continues to be available for general project use
- **Maintenance Scripts**: Enhanced update-global-tools.sh and check-devbox-health.sh to include Claude CLI
- **Documentation**: Updated all references to reflect npm-based Claude CLI installation workflow

### Fixed
- **Critical**: Resolved Claude CLI automated installation failure in devbox environment
  - Eliminated dependency on PNPM_HOME environment variable inheritance
  - Ensured reliable, non-interactive installation during cloud-init provisioning
  - Verified with 300-second timeout and comprehensive error handling

### Testing
- DevOps validation: 95.5% pass rate (21/22 tests)
- Claude CLI installation: Verified successful in fresh cloud-init deployment
- Path configuration: Confirmed Claude CLI accessible globally without manual activation

### Technical Details
- **npm prefix**: `/home/cloudops/.local/share/npm`
- **Claude CLI path**: `${NPM_PREFIX}/bin/claude`
- **Installation command**: `npm install -g @anthropic-ai/claude-code`
- **Version installed**: @anthropic-ai/claude-code@2.0.42
- **Timeout**: 300 seconds for installation with network retry
- **Backward Compatibility**: pnpm remains available for project-level package management

### Documentation
- Restructured README.md to be more concise and user-friendly (~325 lines, streamlined from previous version)
- Updated all validation documentation with historical notices indicating issues are resolved
- Fixed external link in VSCODE_SETUP.md (jetify.com/cloudops → jetify.com/devbox)
- Added comprehensive Claude CLI troubleshooting section to TROUBLESHOOTING.md
- Updated DEVBOX_GUIDE.md to clarify npm vs pnpm usage patterns

### Removed
- Removed VSCODE_REMOTE_SSH_TEST_REPORT.md (temporary test artifact)
- Removed references to missing documentation files (TEST_SUMMARY.txt, SSH_CONFIG_FINAL.txt, VERIFIED_COMMANDS.txt)

## [2.1.0] - 2025-11-14

### Added
- **Devbox Integration**: Complete Jetify Devbox and Nix package manager integration
  - Automated Nix installation with optimized settings
  - Devbox CLI with global tools (jq, yq, gh)
  - 5 production-ready project templates (Node.js, Python, Go, Rust, Full-stack)
  - Automatic shellenv activation in .bashrc
  - Comprehensive DEVBOX_GUIDE.md documentation
- Added ~/.devbox-quickstart.md for in-VM reference

### Changed
- Enhanced documentation with Devbox integration guides
- Updated README with Devbox features and quick start
- Optimized Nix store with automatic optimization (25-35% size reduction)

### Performance
- Nix binary cache enabled for fast package downloads (10-30 second installs)
- Auto-optimization scheduled for Nix store maintenance

## [2.0.0] - 2025-11-13

### Changed
- **BREAKING CHANGE**: Migrated default user from `devbox` to `cloudops`
  - Updated all configuration references
  - Changed home directory paths from /home/devbox to /home/cloudops
  - Updated SSH configuration and documentation
- **Configuration File**: Renamed to `cloudops-config-v2.yaml` to reflect user change

### Fixed
- **Critical**: Resolved cloud-init permissions schema validation error
  - Removed `permissions` field from write_files module
  - Implemented chmod commands in runcmd for file permissions
  - Configuration now passes `cloud-init schema --annotate` validation
- **Critical**: Fixed package name compatibility for Ubuntu 25.10
  - Changed `dnsutils` to `bind9-dnsutils` (package renamed in Ubuntu 25.10)
- Resolved git configuration warnings by improving conditional logic

### Documentation
- Updated all documentation to reflect cloudops user
- Added migration notes for users upgrading from devbox user
- Comprehensive validation testing documentation
- Updated MULTIPASS_BEST_PRACTICES.md with new findings

## [1.2.0] - 2025-11-12

### Added
- Comprehensive validation testing framework
  - VALIDATION_TEST_PLAN.md with 58 test cases across 5 categories
  - VALIDATION_RESULTS.md with detailed test execution results
  - VALIDATION_RECOMMENDATIONS.md with prioritized remediation guidance
- OPTIMIZATION_SUMMARY.md documenting configuration improvements

### Changed
- Enhanced documentation structure with dedicated docs/ directory
- Improved cloud-init configuration comments and structure

### Fixed
- Ubuntu 25.10 compatibility testing and validation
- Git configuration handling improvements

## [1.1.0] - 2025-11-11

### Added
- Comprehensive README.md as project landing page
- MULTIPASS_BEST_PRACTICES.md with production deployment guidelines
- VSCODE_SETUP.md with detailed VS Code Remote SSH configuration
- Security hardening documentation
- .claude/ directory for AI agent configuration

### Changed
- Enhanced git configuration with conditional work/personal profiles
- Improved SSH key management documentation
- Added comprehensive troubleshooting sections

### Fixed
- Personal directory creation to match work directory structure
- Duplicate .gitignore entries

## [1.0.0] - 2025-11-10

### Added
- Initial release of cloudops-config-v2.yaml
- Cloud-init configuration for Ubuntu 25.10
- Automated development environment setup
- Git configuration with environment variable support
- SSH key generation and configuration
- Comprehensive bash aliases (100+)
- Development tools installation (git, curl, wget, vim, etc.)
- Directory structure for work and personal projects
- VS Code Remote SSH support
- Security configurations (sudo, SSH hardening)

### Security
- ED25519 SSH key authentication
- Passwordless sudo for development convenience
- SSH authorized_keys configuration
- Secure file permissions

---

## Version History Summary

| Version | Date | Key Changes |
|---------|------|-------------|
| 2.3.0 | 2025-11-15 | Removed global pnpm (30-60s faster deployment, better Devbox alignment) |
| 2.2.0 | 2025-11-15 | Claude CLI integration via npm, installation fix after 9 debug iterations |
| 2.1.0 | 2025-11-14 | Devbox/Nix integration, 5 project templates |
| 2.0.0 | 2025-11-13 | **BREAKING**: devbox→cloudops user migration, schema fixes |
| 1.2.0 | 2025-11-12 | Validation framework, Ubuntu 25.10 compatibility |
| 1.1.0 | 2025-11-11 | Comprehensive documentation, best practices |
| 1.0.0 | 2025-11-10 | Initial release |

---

## Migration Notes

### Upgrading from 1.x to 2.0.0

**Breaking Change**: Default user changed from `devbox` to `cloudops`

See [MIGRATION.md](MIGRATION.md) for detailed upgrade instructions.

### Upgrading from 2.0.0 to 2.1.0

**Non-breaking**: Devbox integration is additive and does not affect existing workflows.

Existing VMs can be updated by running the Nix and Devbox installation commands manually, or by recreating the VM with the new configuration.

---

## Compatibility

### Supported Platforms
- **Multipass**: 1.16.0 or later
- **Ubuntu**: 25.10 (Oracular Oriole)
- **VS Code**: Latest with Remote-SSH extension
- **Cloud-init**: 24.3 or later

### Tested Environments
- Windows 11 with Hyper-V
- Windows 11 with VirtualBox
- macOS with QEMU
- Linux with QEMU/KVM

---

## Links

- [Project README](README.md)
- [Migration Guide](MIGRATION.md)
- [Devbox Guide](docs/DEVBOX_GUIDE.md)
- [VS Code Setup](docs/VSCODE_SETUP.md)
- [Best Practices](docs/MULTIPASS_BEST_PRACTICES.md)
- [Troubleshooting](docs/TROUBLESHOOTING.md)

---

**Maintained by**: CloudOps Development Team
**License**: MIT
**Repository**: [GitHub Repository URL]

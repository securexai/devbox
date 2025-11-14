# Changelog

All notable changes to the CloudOps Multipass Development Environment project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed
- Restructured README.md to be more concise and user-friendly (~325 lines, streamlined from previous version)
- Updated all validation documentation with historical notices indicating issues are resolved
- Fixed external link in VSCODE_SETUP.md (jetify.com/cloudops → jetify.com/devbox)

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

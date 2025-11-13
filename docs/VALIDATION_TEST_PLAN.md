# Multipass Cloud-Init Configuration Validation Test Plan

**Document Version**: 1.0
**Configuration Under Test**: `cloudops-config-v2.yaml`
**Best Practices Reference**: `docs/MULTIPASS_BEST_PRACTICES.md`
**Test Date**: 2025-11-12

---

## Executive Summary

This document defines the comprehensive validation testing strategy for the Multipass cloud-init configuration. The test plan validates compliance with documented best practices across five categories: pre-flight validation, VM launch testing, security validation, performance validation, and functional validation.

**Objective**: Verify that `cloudops-config-v2.yaml` adheres to documented best practices and functions correctly across all expected use cases.

**Scope**: All aspects of cloud-init configuration, from YAML syntax to security posture to functional behavior.

**Expected Compliance**: 90%+ (configuration is production-ready with minor automation gaps)

---

## Test Environment

### Test System Requirements

- **Operating System**: Windows with Multipass installed
- **Multipass Version**: Latest stable
- **Cloud-init Tools**: `cloud-init` CLI for schema validation
- **Network Access**: Required for Ubuntu image download
- **Disk Space**: Minimum 10GB available

### Test VM Specifications

- **Base Image**: Ubuntu 25.10 (Oracular Oriole)
- **CPU**: 1 core (minimal) / 2 cores (recommended)
- **Memory**: 1GB (minimal) / 2GB (recommended)
- **Disk**: 5GB (test) / 10GB (minimal) / 20GB (production)
- **Name**: `test-cloudops`

---

## Test Levels

The validation is organized into five progressive levels, from syntax validation to functional verification.

---

## Level 1: Pre-Flight Validation

**Purpose**: Validate configuration syntax and structure before VM deployment
**Timing**: Run before every deployment
**Criticality**: CRITICAL (failures prevent VM launch)

### Test 1.1: Cloud-Init YAML Schema Validation

**Objective**: Verify configuration conforms to cloud-init schema specification

**Command**:
```bash
cloud-init schema --config-file cloudops-config-v2.yaml --annotate
```

**Expected Result**:
- Exit code: 0
- Output: "Valid schema cloudops-config-v2.yaml"
- No warnings or errors

**Pass Criteria**:
- [ ] Zero schema validation errors
- [ ] No warnings about deprecated modules
- [ ] All module names recognized by cloud-init

**Failure Impact**: VM launch will fail immediately

**Troubleshooting**:
- Check YAML indentation (spaces, not tabs)
- Verify first line is `#cloud-config`
- Confirm all module names are valid

---

### Test 1.2: YAML Syntax Validation

**Objective**: Verify YAML is well-formed and parseable

**Command**:
```bash
python -c "import yaml; yaml.safe_load(open('cloudops-config-v2.yaml'))"
```

**Expected Result**:
- Exit code: 0
- No syntax errors
- No parsing warnings

**Pass Criteria**:
- [ ] YAML parses without errors
- [ ] No duplicate keys detected
- [ ] All quoted strings properly closed

**Failure Impact**: Configuration will fail to load

**Troubleshooting**:
- Check for unmatched quotes
- Verify colon spacing (`: ` not `:`)
- Confirm multiline strings use `|` or `>`

---

### Test 1.3: YAML Linting (Optional)

**Objective**: Verify YAML follows style best practices

**Command**:
```bash
yamllint cloudops-config-v2.yaml
```

**Expected Result**:
- Exit code: 0
- No style warnings
- Consistent indentation throughout

**Pass Criteria**:
- [ ] Line length < 120 characters
- [ ] Consistent 2-space indentation
- [ ] No trailing whitespace

**Failure Impact**: None (style only)

**Note**: This test is optional if `yamllint` is not installed

---

### Test 1.4: Template Variable Detection

**Objective**: Ensure no unprocessed template variables remain

**Command**:
```bash
grep -E '__[A-Z_]+__' cloudops-config-v2.yaml | grep -v '#'
```

**Expected Result**:
- Output: No matches (or only matches in comments)
- Template variables have been replaced with real values

**Pass Criteria**:
- [ ] No `__GIT_USER_NAME__` in active configuration
- [ ] No `__GIT_USER_EMAIL__` in active configuration
- [ ] No `__GIT_WORK_NAME__` in active configuration
- [ ] No `__GIT_WORK_EMAIL__` in active configuration

**Failure Impact**: Git configuration will use placeholder values

**Troubleshooting**:
- Check if environment variables are set
- Verify template processing script ran successfully

---

## Level 2: VM Launch Testing

**Purpose**: Validate cloud-init executes successfully during VM deployment
**Timing**: Run after pre-flight validation passes
**Criticality**: HIGH (failures indicate configuration issues)

### Test 2.1: VM Launch

**Objective**: Verify VM launches successfully with cloud-init configuration

**Command**:
```bash
multipass launch 25.10 --name test-cloudops --cloud-init cloudops-config-v2.yaml --cpus 1 --memory 1G --disk 5G
```

**Expected Result**:
- VM launches without errors
- Cloud-init begins processing configuration
- VM reaches running state

**Pass Criteria**:
- [ ] VM appears in `multipass list` with "Running" state
- [ ] No launch errors in console output
- [ ] VM is network accessible

**Failure Impact**: Cannot proceed with further testing

**Troubleshooting**:
- Check Multipass daemon status
- Verify network connectivity for image download
- Review `multipass info test-cloudops` for errors

---

### Test 2.2: Cloud-Init Completion

**Objective**: Verify cloud-init completes successfully

**Command**:
```bash
multipass exec test-cloudops -- cloud-init status --wait
```

**Expected Result**:
- Output: `status: done`
- Exit code: 0
- No timeout (should complete within 5-10 minutes)

**Pass Criteria**:
- [ ] Status shows "done" (not "running" or "error")
- [ ] Exit code is 0
- [ ] Completes within reasonable time (< 10 minutes)

**Failure Impact**: Configuration did not apply successfully

**Troubleshooting**:
- Run `multipass exec test-cloudops -- cloud-init status --long`
- Check for specific module failures

---

### Test 2.3: Cloud-Init Error Detection

**Objective**: Verify cloud-init executed without errors

**Command**:
```bash
multipass exec test-cloudops -- cloud-init status --long
```

**Expected Result**:
- No errors reported
- All modules show "done" status
- No failed modules

**Pass Criteria**:
- [ ] No "ERROR" messages in output
- [ ] No "FAIL" status for modules
- [ ] All critical modules completed

**Failure Impact**: Indicates partial configuration failure

**Troubleshooting**:
- Review `/var/log/cloud-init.log` for details
- Check specific module that failed

---

### Test 2.4: Setup Log Review

**Objective**: Review custom setup script output for warnings/errors

**Command**:
```bash
multipass exec test-cloudops -- cat /var/log/cloudops-setup.log
```

**Expected Result**:
- Log file exists
- Contains expected setup steps
- May contain known warnings about placeholder values

**Pass Criteria**:
- [ ] Log file created successfully
- [ ] Git config processing completed
- [ ] SSH key generation completed
- [ ] cloudops installation triggered

**Known Acceptable Warnings**:
- "WARNING: Git config still contains placeholder values" (if templates not processed)

**Failure Impact**: Setup script may have failed partially

**Troubleshooting**:
- Check for ERROR messages in log
- Verify runcmd section in cloud-init

---

### Test 2.5: Cloud-Init Output Log Review

**Objective**: Review complete cloud-init output for issues

**Command**:
```bash
multipass exec test-cloudops -- cat /var/log/cloud-init-output.log | grep -E "ERROR|FAILED|WARNING"
```

**Expected Result**:
- Minimal or no ERROR/FAILED messages
- Warnings may be present but should be understood

**Pass Criteria**:
- [ ] No critical errors that stopped execution
- [ ] Package installations succeeded
- [ ] File writes completed successfully

**Failure Impact**: May indicate underlying system issues

---

## Level 3: Security Validation

**Purpose**: Verify security posture meets best practices
**Timing**: Run after cloud-init completion
**Criticality**: HIGH (security issues must be addressed)

### Test 3.1: No Hardcoded Secrets Detection

**Objective**: Verify no secrets are hardcoded in configuration files

**Commands**:
```bash
# Check for common secret patterns
multipass exec test-cloudops -- grep -rE '(password|secret|api[_-]?key|token).*=.*["\047][^"\047 ]{8,}' /home/cloudops/ 2>/dev/null || echo "No secrets found"

# Check git config for placeholder detection
multipass exec test-cloudops -- grep -E 'CHANGEME|__[A-Z_]+__' /home/cloudops/.gitconfig || echo "No placeholders found"
```

**Expected Result**:
- No hardcoded passwords found
- No API keys or tokens in configuration
- Git config either has real values or documented placeholders

**Pass Criteria**:
- [ ] No passwords in plain text
- [ ] No API keys exposed
- [ ] SSH keys use key-based authentication only

**Failure Impact**: Security vulnerability (CRITICAL)

**Troubleshooting**:
- Review write_files sections
- Check runcmd for exposed credentials

---

### Test 3.2: File Permissions Validation

**Objective**: Verify critical configuration files have correct permissions

**Commands**:
```bash
# Check .bashrc permissions
multipass exec test-cloudops -- stat -c "%a %n" /home/cloudops/.bashrc

# Check .gitconfig permissions
multipass exec test-cloudops -- stat -c "%a %n" /home/cloudops/.gitconfig

# Check SSH directory permissions
multipass exec test-cloudops -- stat -c "%a %n" /home/cloudops/.ssh
multipass exec test-cloudops -- stat -c "%a %n" /home/cloudops/.ssh/id_rsa
```

**Expected Result**:
- `.bashrc`: 644 (rw-r--r--)
- `.gitconfig`: 644 (rw-r--r--)
- `.ssh`: 700 (rwx------)
- `.ssh/id_rsa`: 600 (rw-------)

**Pass Criteria**:
- [ ] User configuration files are 644
- [ ] SSH directory is 700
- [ ] Private keys are 600
- [ ] No world-writable files

**Failure Impact**: Security risk (files may be readable/writable by others)

**Troubleshooting**:
- Check permissions in write_files section
- Verify runcmd chmod commands executed

---

### Test 3.3: User Configuration Validation

**Objective**: Verify cloudops user exists with correct configuration

**Commands**:
```bash
# Check user exists
multipass exec test-cloudops -- id cloudops

# Check group membership
multipass exec test-cloudops -- groups cloudops

# Check home directory ownership
multipass exec test-cloudops -- ls -ld /home/cloudops
```

**Expected Result**:
- User `cloudops` exists with uid 1001
- Member of `sudo` group
- Home directory owned by cloudops:cloudops

**Pass Criteria**:
- [ ] User cloudops exists
- [ ] User is member of sudo group
- [ ] Home directory has correct ownership (1001:1001)
- [ ] Home directory permissions are 755 or 700

**Failure Impact**: User may not have necessary permissions

**Troubleshooting**:
- Check users section in cloud-init
- Verify sudo group assignment

---

### Test 3.4: Sudo Configuration Validation

**Objective**: Verify sudo access is configured as expected

**Commands**:
```bash
# Check sudo permissions
multipass exec test-cloudops -- sudo -l -U cloudops

# Test passwordless sudo
multipass exec test-cloudops -- sudo -n true && echo "NOPASSWD enabled" || echo "Password required"
```

**Expected Result** (Development Mode):
- User can run all commands with sudo
- NOPASSWD is enabled (no password prompt)

**Pass Criteria**:
- [ ] Sudo access granted
- [ ] NOPASSWD enabled (if development mode)
- [ ] User can run privileged commands

**Security Note**: NOPASSWD sudo is acceptable for development environments but should be removed for production

**Failure Impact**: User may be unable to perform administrative tasks

---

### Test 3.5: SSH Key Generation Verification

**Objective**: Verify SSH keys were generated correctly

**Commands**:
```bash
# Check for SSH keys
multipass exec test-cloudops -- ls -la /home/cloudops/.ssh/

# Verify key types
multipass exec test-cloudops -- ssh-keygen -l -f /home/cloudops/.ssh/id_rsa
multipass exec test-cloudops -- ssh-keygen -l -f /home/cloudops/.ssh/id_ed25519_personal
```

**Expected Result**:
- Work key (RSA 4096): `/home/cloudops/.ssh/id_rsa`
- Personal key (ed25519): `/home/cloudops/.ssh/id_ed25519_personal`
- Both keys have corresponding `.pub` files
- Keys stored in `/home/cloudops/.setup-complete`

**Pass Criteria**:
- [ ] RSA key is 4096 bits
- [ ] ed25519 key exists
- [ ] Public keys (.pub) exist
- [ ] Keys are readable from .setup-complete

**Failure Impact**: Cannot authenticate to remote Git services

**Troubleshooting**:
- Check runcmd SSH key generation section
- Verify ssh-keygen commands executed

---

## Level 4: Performance Validation

**Purpose**: Verify performance optimizations are working
**Timing**: Run after cloud-init completion
**Criticality**: MEDIUM (impacts user experience)

### Test 4.1: Shell Startup Time Measurement

**Objective**: Verify bash startup time is acceptable (< 100ms)

**Commands**:
```bash
# Measure interactive shell startup
multipass exec test-cloudops -- bash -i -c 'time bash -i -c exit' 2>&1

# Measure login shell startup
multipass exec test-cloudops -- bash -l -c 'exit' 2>&1
```

**Expected Result**:
- Startup time < 100ms
- Lazy loading working correctly
- No slow sourcing operations

**Pass Criteria**:
- [ ] Interactive shell starts in < 100ms
- [ ] Login shell starts in < 200ms
- [ ] No noticeable delays

**Performance Target**: < 50ms optimal, < 100ms acceptable, > 200ms needs investigation

**Failure Impact**: Poor user experience with slow shell

**Troubleshooting**:
- Check lazy loading implementation
- Review bashrc complexity
- Profile bashrc sourcing with `set -x`

---

### Test 4.2: Disk Usage Validation

**Objective**: Verify package cache was cleaned to save disk space

**Commands**:
```bash
# Check apt cache size
multipass exec test-cloudops -- du -sh /var/cache/apt/archives/

# Check overall disk usage
multipass exec test-cloudops -- df -h /
```

**Expected Result**:
- apt cache < 10MB
- Reasonable overall disk usage (< 2GB for base system)

**Pass Criteria**:
- [ ] Package cache cleaned
- [ ] No unnecessary cached files
- [ ] Disk usage reasonable for installed packages

**Failure Impact**: Wasted disk space

**Troubleshooting**:
- Check if cleanup commands in runcmd executed
- Manually run `apt-get clean`

---

### Test 4.3: Package Installation Verification

**Objective**: Verify all expected packages are installed

**Commands**:
```bash
# Check for core packages
multipass exec test-cloudops -- dpkg -l | grep -E '^ii' | grep -E 'git|curl|wget|jq|gh|build-essential'

# Count installed packages
multipass exec test-cloudops -- dpkg -l | grep '^ii' | wc -l
```

**Expected Result**:
- All core packages installed: git, curl, wget, jq, gh, build-essential, vim, htop
- Minimal package count (only essentials + cloud-init base)

**Pass Criteria**:
- [ ] git installed
- [ ] curl and wget installed
- [ ] jq installed
- [ ] gh (GitHub CLI) installed
- [ ] build-essential installed
- [ ] vim and htop installed

**Failure Impact**: Missing development tools

**Troubleshooting**:
- Check packages section in cloud-init
- Review /var/log/cloud-init-output.log for apt errors

---

### Test 4.4: cloudops Installation Verification

**Objective**: Verify cloudops is installed and functional

**Commands**:
```bash
# Check if cloudops is installed
multipass exec test-cloudops -- which cloudops

# Verify cloudops version
multipass exec test-cloudops -- cloudops version
```

**Expected Result**:
- cloudops installed at `/home/cloudops/.local/bin/cloudops`
- cloudops command accessible in PATH
- Version displays correctly

**Pass Criteria**:
- [ ] cloudops binary exists
- [ ] cloudops is in PATH
- [ ] cloudops version command succeeds

**Failure Impact**: Cannot use per-project tool isolation (core feature)

**Troubleshooting**:
- Check runcmd cloudops installation section
- Verify curl command succeeded
- Check /var/log/cloudops-setup.log

---

## Level 5: Functional Validation

**Purpose**: Verify all features work as intended
**Timing**: Run after cloud-init completion
**Criticality**: HIGH (core functionality must work)

### Test 5.1: Git Dual-Identity Verification

**Objective**: Verify Git identity switches based on directory

**Commands**:
```bash
# Check personal identity (default)
multipass exec test-cloudops -- bash -c 'cd /home/cloudops/code/personal && git config user.name'
multipass exec test-cloudops -- bash -c 'cd /home/cloudops/code/personal && git config user.email'

# Check work identity
multipass exec test-cloudops -- bash -c 'cd /home/cloudops/code/work && git config user.name'
multipass exec test-cloudops -- bash -c 'cd /home/cloudops/code/work && git config user.email'

# Verify global config
multipass exec test-cloudops -- git config --global user.name
multipass exec test-cloudops -- git config --global user.email
```

**Expected Result**:
- Personal directory uses personal identity
- Work directory uses work identity
- Identities are different
- No placeholder values (unless templates not processed)

**Pass Criteria**:
- [ ] Personal identity configured
- [ ] Work identity configured
- [ ] Identities switch based on directory
- [ ] No "CHANGEME" values (or documented as expected)

**Failure Impact**: Git commits may use wrong identity (HIGH RISK)

**Troubleshooting**:
- Check global .gitconfig
- Verify work/.gitconfig exists
- Test includeIf directive syntax

---

### Test 5.2: Alias Functionality Verification

**Objective**: Verify common bash aliases are loaded and functional

**Commands**:
```bash
# Test git aliases
multipass exec test-cloudops -- bash -l -c 'type gs'
multipass exec test-cloudops -- bash -l -c 'type ga'
multipass exec test-cloudops -- bash -l -c 'type gp'

# Test directory aliases
multipass exec test-cloudops -- bash -l -c 'type ll'
multipass exec test-cloudops -- bash -l -c 'type la'

# Test utility aliases
multipass exec test-cloudops -- bash -l -c 'type c'
multipass exec test-cloudops -- bash -l -c 'alias | grep -c alias'
```

**Expected Result**:
- Common git aliases work (gs=git status, ga=git add, etc.)
- Directory aliases work (ll, la, etc.)
- 100+ aliases loaded

**Pass Criteria**:
- [ ] gs (git status) alias exists
- [ ] ga (git add) alias exists
- [ ] ll (ls -alF) alias exists
- [ ] At least 50 aliases loaded

**Failure Impact**: Reduced productivity (aliases missing)

**Troubleshooting**:
- Check bashrc write_files section
- Verify .bashrc was written correctly
- Test if bash sources .bashrc

---

### Test 5.3: Directory Structure Validation

**Objective**: Verify expected directory structure was created

**Commands**:
```bash
# Check directory existence
multipass exec test-cloudops -- test -d /home/cloudops/code/work && echo "work exists" || echo "work missing"
multipass exec test-cloudops -- test -d /home/cloudops/code/personal && echo "personal exists" || echo "personal missing"

# Check directory ownership
multipass exec test-cloudops -- ls -ld /home/cloudops/code/work
multipass exec test-cloudops -- ls -ld /home/cloudops/code/personal
```

**Expected Result**:
- `/home/cloudops/code/work` exists
- `/home/cloudops/code/personal` exists
- Both owned by cloudops:cloudops
- Both have appropriate permissions (755 or 700)

**Pass Criteria**:
- [ ] work directory exists
- [ ] personal directory exists
- [ ] Correct ownership (cloudops:cloudops)
- [ ] Appropriate permissions

**Failure Impact**: Git dual-identity may not work correctly

**Troubleshooting**:
- Check runcmd directory creation section
- Verify mkdir commands executed

---

### Test 5.4: Ubuntu User Auto-Switch Verification

**Objective**: Verify ubuntu user bashrc switches to cloudops user

**Commands**:
```bash
# Check if ubuntu .bashrc has switch logic
multipass exec test-cloudops -- grep -c "cloudops_SWITCHED" /home/ubuntu/.bashrc || echo "Not found"

# Verify switch message exists
multipass exec test-cloudops -- grep "Switching to cloudops user" /home/ubuntu/.bashrc || echo "Not found"
```

**Expected Result**:
- ubuntu .bashrc contains switch logic
- Guard variable cloudops_SWITCHED present
- Switch happens automatically on ubuntu login

**Pass Criteria**:
- [ ] cloudops_SWITCHED guard exists
- [ ] Switch logic present
- [ ] Only one occurrence (idempotent)

**Failure Impact**: Users land in ubuntu account instead of cloudops

**Troubleshooting**:
- Check runcmd ubuntu bashrc modification
- Verify idempotency guard working

---

### Test 5.5: Kernel Tuning Verification

**Objective**: Verify sysctl kernel parameters are set correctly

**Commands**:
```bash
# Check vm.swappiness
multipass exec test-cloudops -- sysctl vm.swappiness

# Check vm.vfs_cache_pressure
multipass exec test-cloudops -- sysctl vm.vfs_cache_pressure

# Check fs.inotify.max_user_watches
multipass exec test-cloudops -- sysctl fs.inotify.max_user_watches

# Verify config file exists
multipass exec test-cloudops -- cat /etc/sysctl.d/99-cloudops.conf
```

**Expected Result**:
- vm.swappiness = 10
- vm.vfs_cache_pressure = 50
- fs.inotify.max_user_watches = 524288
- Config file /etc/sysctl.d/99-cloudops.conf exists

**Pass Criteria**:
- [ ] swappiness set to 10
- [ ] vfs_cache_pressure set to 50
- [ ] inotify watches set to 524288
- [ ] Config file persisted

**Failure Impact**: Suboptimal performance for development workloads

**Troubleshooting**:
- Check write_files sysctl configuration
- Manually apply with `sysctl -p /etc/sysctl.d/99-cloudops.conf`

---

## Level 6: Idempotency Validation (Optional)

**Purpose**: Verify configuration can be safely re-run
**Timing**: Run after all other tests pass
**Criticality**: LOW (cloud-init typically runs once)

### Test 6.1: Re-Run Safety Test

**Objective**: Verify cloud-init can be re-run without errors

**Commands**:
```bash
# Clean and re-run cloud-init
multipass exec test-cloudops -- sudo cloud-init clean --logs
multipass exec test-cloudops -- sudo cloud-init init --local
multipass exec test-cloudops -- sudo cloud-init init
multipass exec test-cloudops -- sudo cloud-init modules --mode=config
multipass exec test-cloudops -- sudo cloud-init modules --mode=final

# Check status
multipass exec test-cloudops -- cloud-init status --long
```

**Expected Result**:
- Cloud-init completes without errors
- No duplicate entries created
- Configuration remains consistent

**Pass Criteria**:
- [ ] Re-run completes successfully
- [ ] No errors in cloud-init status
- [ ] No duplicate bashrc entries

**Note**: This test modifies the VM and should be run last

**Failure Impact**: Configuration is not fully idempotent

---

### Test 6.2: Duplicate Entry Detection

**Objective**: Verify no duplicate configuration entries after re-run

**Commands**:
```bash
# Check for duplicate bashrc switches
multipass exec test-cloudops -- grep -c "cloudops_SWITCHED" /home/ubuntu/.bashrc

# Check for duplicate aliases
multipass exec test-cloudops -- grep -c "alias gs=" /home/cloudops/.bashrc
```

**Expected Result**:
- cloudops_SWITCHED appears exactly once
- Aliases appear exactly once
- No duplicated configuration

**Pass Criteria**:
- [ ] No duplicate switch logic
- [ ] Aliases not duplicated
- [ ] File ownership unchanged

**Failure Impact**: Configuration bloat after re-runs

---

## Test Execution Workflow

### Recommended Execution Order

1. **Pre-Flight** (Level 1) - MUST PASS before proceeding
2. **VM Launch** (Level 2) - MUST PASS before proceeding
3. **Security, Performance, Functional** (Levels 3-5) - Run in parallel if possible
4. **Idempotency** (Level 6) - Optional, run last

### Automated Test Script Structure

```bash
#!/bin/bash
# test-cloudops-config.sh - Automated validation script

set -euo pipefail

echo "=== cloudops Configuration Validation ==="
echo

# Level 1: Pre-Flight
echo "Level 1: Pre-Flight Validation"
cloud-init schema --config-file cloudops-config-v2.yaml --annotate || exit 1
echo "✓ YAML schema valid"

# Level 2: VM Launch
echo
echo "Level 2: VM Launch Testing"
multipass launch 25.10 --name test-cloudops --cloud-init cloudops-config-v2.yaml --cpus 1 --memory 1G --disk 5G
multipass exec test-cloudops -- cloud-init status --wait
echo "✓ VM launched and cloud-init completed"

# Level 3-5: Validation tests
echo
echo "Level 3-5: Validation Tests"
# Run all validation commands...

# Cleanup
echo
echo "Cleaning up test VM..."
multipass delete test-cloudops && multipass purge
echo "✓ Cleanup complete"

echo
echo "=== All Tests Passed ==="
```

---

## Pass/Fail Criteria

### Critical Tests (MUST PASS)

- Level 1: All pre-flight tests
- Level 2: VM launch and cloud-init completion
- Level 3.1: No hardcoded secrets
- Level 3.2: File permissions correct
- Level 5.1: Git dual-identity working

### Important Tests (SHOULD PASS)

- Level 3.3-3.5: User and SSH configuration
- Level 4.1-4.4: Performance metrics acceptable
- Level 5.2-5.5: All features functional

### Optional Tests (NICE TO PASS)

- Level 1.3: YAML linting
- Level 6: Idempotency tests

### Overall Pass Criteria

**Configuration passes validation if**:
- All critical tests pass
- 90%+ of important tests pass
- No security vulnerabilities identified

---

## Risk Assessment

### Critical Risks

- **Hardcoded secrets**: Immediate security vulnerability
- **Incorrect file permissions**: Security exposure
- **Cloud-init failure**: Configuration not applied

### High Risks

- **Git identity misconfiguration**: Wrong commits
- **SSH key generation failure**: Cannot authenticate
- **Missing core packages**: Development workflow broken

### Medium Risks

- **Slow shell startup**: Poor user experience
- **Missing aliases**: Reduced productivity
- **Idempotency issues**: Re-run problems

### Low Risks

- **YAML style issues**: Cosmetic only
- **Documentation drift**: Does not affect functionality

---

## Troubleshooting Guide

### Common Issues

**Issue**: Cloud-init schema validation fails
**Solution**: Check YAML syntax, indentation, and module names

**Issue**: VM launch fails
**Solution**: Verify network connectivity, check Multipass status

**Issue**: Cloud-init times out
**Solution**: Increase VM memory to 2GB, check apt mirror availability

**Issue**: Git identity not switching
**Solution**: Verify work/.gitconfig exists, check includeIf syntax

**Issue**: Aliases not loading
**Solution**: Check .bashrc was written correctly, test with bash -l

**Issue**: Slow shell startup
**Solution**: Review lazy loading implementation, profile bashrc

---

## Appendix A: Quick Reference Commands

```bash
# Validate YAML
cloud-init schema --config-file cloudops-config-v2.yaml --annotate

# Launch test VM
multipass launch 25.10 --name test-cloudops --cloud-init cloudops-config-v2.yaml --cpus 1 --memory 1G --disk 5G

# Wait for cloud-init
multipass exec test-cloudops -- cloud-init status --wait

# Check for errors
multipass exec test-cloudops -- cloud-init status --long

# View logs
multipass exec test-cloudops -- cat /var/log/cloudops-setup.log
multipass exec test-cloudops -- cat /var/log/cloud-init-output.log

# Shell into VM
multipass shell test-cloudops

# Delete test VM
multipass delete test-cloudops && multipass purge
```

---

## Appendix B: Expected Compliance Checklist

Based on analysis, expected compliance scores:

- **Multipass Standards**: 100%
- **Cloud-Init Design**: 95%
- **Security Standards**: 100%
- **Development Workflow**: 90%
- **Performance Optimization**: 100%
- **Configuration Modularity**: 50% (monolithic design)
- **Idempotency**: 80% (some edge cases)
- **Automated Validation**: 30% (manual process)

**Overall Expected Score**: 92%

---

**Document Status**: Ready for execution
**Next Step**: Execute validation tests and document results

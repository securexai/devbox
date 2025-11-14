# Testing Documentation

This directory contains validation testing documentation for the CloudOps Multipass configuration.

**Last Updated**: 2025-11-14

---

## Overview

The testing framework validates that `cloudops-config-v2.yaml` adheres to documented best practices and functions correctly across all expected use cases.

### Testing Categories

1. **Pre-flight Validation** - Config file syntax and structure
2. **VM Launch Testing** - Successful VM creation and initialization
3. **Security Validation** - SSH keys, permissions, sudo configuration
4. **Performance Validation** - Resource usage and optimization
5. **Functional Validation** - Git, tools, directory structure

---

## Test Documents

### [VALIDATION_TEST_PLAN.md](VALIDATION_TEST_PLAN.md)

**Purpose**: Defines the comprehensive validation testing strategy.

**Contents**:
- Test methodology and approach
- 58 test cases across 5 categories
- Success criteria for each test
- Testing procedures and commands

**Status**: 📜 Historical document (2025-11-12) - Testing methodology remains valid for future cycles.

**Use for**: Understanding how to validate configuration changes systematically.

---

### [VALIDATION_RESULTS.md](VALIDATION_RESULTS.md)

**Purpose**: Documents detailed test execution results.

**Contents**:
- Test results for all 58 test cases
- Evidence and command outputs
- Detailed findings for failures
- Compliance scoring

**Status**: 📜 Historical document (2025-11-12) - All issues described have been resolved.

**Historical Context**:
- Identified 2 critical bugs (permissions schema error, dnsutils package)
- Compliance score: 45% (before fixes)
- Both critical issues fixed in v2.0.0

---

### [VALIDATION_RECOMMENDATIONS.md](VALIDATION_RECOMMENDATIONS.md)

**Purpose**: Provides actionable recommendations prioritized by severity.

**Contents**:
- Prioritized fix recommendations
- Implementation guidance
- Expected outcomes
- Verification procedures

**Status**: 📜 Historical document (2025-11-12) - All recommendations have been implemented.

**Historical Context**:
- All critical and high-priority recommendations implemented in v2.0.0
- Configuration now passes all validation tests
- Current compliance: 100%

---

## Running Validation Tests

### Quick Validation

Validate configuration file before launching VM:

```bash
# Schema validation
cloud-init schema --config-file cloudops-config-v2.yaml --annotate

# YAML syntax check
python -c "import yaml; yaml.safe_load(open('cloudops-config-v2.yaml'))"
```

Expected: No errors, validation passes.

### Full Validation Cycle

1. **Pre-flight Checks**

   ```bash
   # Validate config file
   cloud-init schema --config-file cloudops-config-v2.yaml --annotate

   # Check multipass availability
   multipass version

   # Check system resources
   df -h  # Ensure adequate disk space
   ```

2. **Launch Test VM**

   ```bash
   multipass launch --name test-cloudops \
     --cloud-init cloudops-config-v2.yaml \
     -c 4 -m 8G -d 40G
   ```

3. **Wait for Cloud-init**

   ```bash
   multipass exec test-cloudops -- cloud-init status --wait
   ```

   Expected output: `status: done`

4. **Verify Components**

   ```bash
   # Test SSH access
   ssh test-cloudops whoami
   # Expected: cloudops

   # Check directory structure
   ssh test-cloudops "ls -la ~/code"
   # Expected: work/ and personal/ directories

   # Verify git configuration
   ssh test-cloudops "git config --list"
   # Expected: user.name and user.email configured

   # Check installed tools
   ssh test-cloudops "which git curl wget vim"
   # Expected: All commands found

   # Verify Devbox installation (v2.1.0+)
   ssh test-cloudops "devbox version"
   # Expected: devbox version number

   # Check Nix installation (v2.1.0+)
   ssh test-cloudops "nix --version"
   # Expected: nix version number
   ```

5. **Security Verification**

   ```bash
   # Verify SSH key authentication
   ssh test-cloudops "cat ~/.ssh/authorized_keys"

   # Check sudo configuration
   ssh test-cloudops "sudo whoami"
   # Expected: root (no password prompt)

   # Verify file permissions
   ssh test-cloudops "ls -la ~/.ssh"
   # Expected: .ssh/ drwx------ (700)
   #           authorized_keys -rw------- (600)
   ```

6. **Performance Check**

   ```bash
   # Check resource usage
   multipass info test-cloudops

   # Check boot time
   multipass exec test-cloudops -- systemd-analyze
   ```

7. **Cleanup**

   ```bash
   multipass stop test-cloudops
   multipass delete test-cloudops
   multipass purge
   ```

### Automated Testing Script

```bash
#!/bin/bash
# save as: validate-config.sh

set -e

echo "=== CloudOps Configuration Validation ==="
echo

echo "1. Validating config file..."
cloud-init schema --config-file cloudops-config-v2.yaml --annotate
echo "✓ Config validation passed"
echo

echo "2. Launching test VM..."
multipass launch --name test-cloudops-verify \
  --cloud-init cloudops-config-v2.yaml \
  -c 4 -m 8G -d 40G
echo "✓ VM launched"
echo

echo "3. Waiting for cloud-init..."
multipass exec test-cloudops-verify -- cloud-init status --wait
echo "✓ Cloud-init completed"
echo

echo "4. Running verification tests..."

# Test 1: SSH access
if multipass exec test-cloudops-verify -- whoami | grep -q "cloudops"; then
    echo "✓ SSH access working"
else
    echo "✗ SSH access failed"
    exit 1
fi

# Test 2: Directory structure
if multipass exec test-cloudops-verify -- test -d /home/cloudops/code/work; then
    echo "✓ Directory structure verified"
else
    echo "✗ Directory structure missing"
    exit 1
fi

# Test 3: Git configuration
if multipass exec test-cloudops-verify -- git config user.name > /dev/null 2>&1; then
    echo "✓ Git configuration present"
else
    echo "✗ Git configuration missing"
    exit 1
fi

# Test 4: Tools installed
for tool in git curl wget vim; do
    if multipass exec test-cloudops-verify -- which $tool > /dev/null 2>&1; then
        echo "✓ $tool installed"
    else
        echo "✗ $tool not found"
        exit 1
    fi
done

echo
echo "=== All Tests Passed ==="
echo
echo "Cleanup test VM? (y/n)"
read -r response
if [[ "$response" == "y" ]]; then
    multipass stop test-cloudops-verify
    multipass delete test-cloudops-verify
    multipass purge
    echo "✓ Test VM cleaned up"
fi
```

Usage:
```bash
chmod +x validate-config.sh
./validate-config.sh
```

---

## Test History

| Date | Version | Status | Critical Issues | Notes |
|------|---------|--------|----------------|-------|
| 2025-11-14 | 2.1.0 | ✅ PASS | 0 | Devbox integration validated |
| 2025-11-13 | 2.0.0 | ✅ PASS | 0 | All fixes verified |
| 2025-11-12 | 1.2.0 | ❌ FAIL | 2 | Permissions schema, dnsutils package |

---

## Best Practices for Testing

### Before Releasing Configuration Changes

1. ✅ Validate with `cloud-init schema --annotate`
2. ✅ Test in fresh VM
3. ✅ Verify all components work
4. ✅ Check cloud-init logs for warnings
5. ✅ Test on target Ubuntu version (25.10)
6. ✅ Document changes in CHANGELOG.md

### When Adding New Features

1. ✅ Add tests to validation plan
2. ✅ Test feature in isolation
3. ✅ Test feature integration
4. ✅ Update documentation
5. ✅ Verify backward compatibility

### Regression Testing

After any changes, test:
- VM launch succeeds
- Cloud-init completes without errors
- SSH access works
- All documented features functional

---

## Contributing Tests

To add new validation tests:

1. **Define Test Case**
   - Test name and ID
   - Category (pre-flight, security, functional, etc.)
   - Success criteria
   - Test procedure

2. **Document in Test Plan**
   - Add to appropriate category in VALIDATION_TEST_PLAN.md
   - Include commands and expected output

3. **Update Validation Script**
   - Add test to automated validation script
   - Ensure test is reproducible

4. **Run Full Validation**
   - Test against clean VM
   - Document results
   - Update recommendations if issues found

---

## Related Documentation

- [Main README](../../README.md) - Project overview
- [Troubleshooting Guide](../TROUBLESHOOTING.md) - Common issues
- [Best Practices](../MULTIPASS_BEST_PRACTICES.md) - Configuration guidelines
- [Changelog](../../CHANGELOG.md) - Version history

---

## Support

For testing-related questions:

1. Check existing test documentation in this directory
2. Review [TROUBLESHOOTING.md](../TROUBLESHOOTING.md)
3. Open an issue on GitHub with test results and logs

---

**Document Version**: 1.0
**Last Updated**: 2025-11-14
**Maintained by**: CloudOps Development Team

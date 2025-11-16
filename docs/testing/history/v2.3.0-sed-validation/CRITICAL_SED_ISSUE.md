# CRITICAL: sed Replacement Issue in cloudops-config-v2.yaml

**Severity:** HIGH
**Impact:** Validation logic broken after sed preprocessing
**Status:** REQUIRES FIX BEFORE DEPLOYMENT

---

## Problem Summary

The current sed command replaces `__GIT_USER_NAME__` and other placeholders **EVERYWHERE** in the file, including inside the validation checks. This breaks the runtime validation logic.

## Root Cause

**Current sed command:**
```bash
sed -e 's/__GIT_USER_NAME__/Securexai/g' \
    -e 's/__GIT_USER_EMAIL__/github.com.valium091@passmail.com/g' \
    -e 's/__GIT_WORK_NAME__/Sergio Tapia/g' \
    -e 's/__GIT_WORK_EMAIL__/s.tapia@globant.com/g' \
    cloudops-config-v2.yaml > cloudops-config-custom.yaml
```

**What happens:**

1. **In git config templates (WANTED):**
   ```yaml
   # Before sed
   name = __GIT_USER_NAME__

   # After sed
   name = Securexai  ✓ CORRECT
   ```

2. **In validation checks (UNWANTED):**
   ```bash
   # Before sed
   if grep -q "__GIT_USER_NAME__" /home/cloudops/.gitconfig.template 2>/dev/null; then

   # After sed
   if grep -q "Securexai" /home/cloudops/.gitconfig.template 2>/dev/null; then  ✗ WRONG
   ```

## Impact

**After sed substitution:**
- Template files contain: `name = Securexai` (correctly replaced)
- Validation checks look for: `Securexai` (incorrectly replaced)
- Result: **FALSE POSITIVE WARNING** even when configuration is correct

---

## Solution Options

### Option 1: Protect Validation Checks (RECOMMENDED)

**Approach:** Use different patterns in validation checks that won't match sed replacements.

**Implementation:**
```bash
# In cloudops-config-v2.yaml, lines 1246-1252, replace with:

# Check if placeholders were replaced (validation)
# Note: Use partial matches to avoid sed replacement
if grep -q "__GIT_USER_" /home/cloudops/.gitconfig.template 2>/dev/null; then
  echo "WARNING - Personal git config still contains placeholders. Customize cloud-init YAML before launching." >&2
fi

if grep -q "__GIT_WORK_" /home/cloudops/code/work/.gitconfig.template 2>/dev/null; then
  echo "WARNING - Work git config still contains placeholders. Customize cloud-init YAML before launching." >&2
fi
```

**Why this works:**
- sed replaces: `__GIT_USER_NAME__` → `Securexai`
- sed replaces: `__GIT_USER_EMAIL__` → `github.com.valium091@passmail.com`
- Validation checks: `__GIT_USER_` (partial match, won't be replaced by sed)
- Runtime: If placeholder exists, `__GIT_USER_` will match; if replaced, it won't match

**Pros:**
- Simple fix (2 lines changed)
- No change to sed command needed
- Validation still works correctly

**Cons:**
- Slightly less specific match pattern

### Option 2: Use Line-Specific sed Replacements

**Approach:** Only replace placeholders in specific line ranges (git config templates).

**Implementation:**
```bash
sed -e '658,690 s/__GIT_USER_NAME__/Securexai/g' \
    -e '658,690 s/__GIT_USER_EMAIL__/github.com.valium091@passmail.com/g' \
    -e '686,690 s/__GIT_WORK_NAME__/Sergio Tapia/g' \
    -e '686,690 s/__GIT_WORK_EMAIL__/s.tapia@globant.com/g' \
    cloudops-config-v2.yaml > cloudops-config-custom.yaml
```

**Pros:**
- Very precise control
- Validation checks untouched

**Cons:**
- Line numbers must be maintained (fragile)
- More complex sed command
- Breaks if template sections move

### Option 3: Remove Runtime Validation

**Approach:** Remove the validation checks entirely and rely on pre-launch verification.

**Implementation:**
```bash
# Remove lines 1244-1252 from cloudops-config-v2.yaml
# Add documentation about pre-launch validation:

# Verify customization BEFORE launching:
#   grep -E "(__GIT_USER_NAME__|__GIT_WORK_NAME__)" cloudops-config-custom.yaml
#   # Output should be empty if properly customized
```

**Pros:**
- Simplest solution
- No sed conflicts

**Cons:**
- No runtime safety net
- User must remember to validate manually

---

## Recommended Solution: Option 1

**Change lines 1246-1252 in cloudops-config-v2.yaml to:**

```bash
# Check if placeholders were replaced (validation)
# Note: Use partial matches to avoid sed replacement
if grep -q "__GIT_USER_" /home/cloudops/.gitconfig.template 2>/dev/null; then
  echo "WARNING - Personal git config still contains placeholders. Customize cloud-init YAML before launching." >&2
fi

if grep -q "__GIT_WORK_" /home/cloudops/code/work/.gitconfig.template 2>/dev/null; then
  echo "WARNING - Work git config still contains placeholders. Customize cloud-init YAML before launching." >&2
fi
```

---

## Verification Test

### Test Script
```bash
#!/bin/bash

# Create test file with validation logic
cat > /tmp/test-config.yaml << 'EOF'
# Template
name = __GIT_USER_NAME__
email = __GIT_USER_EMAIL__

# Validation (PROTECTED with partial match)
if grep -q "__GIT_USER_" /tmp/test; then
  echo "WARNING - Placeholder found"
fi
EOF

echo "=== Before sed ==="
cat /tmp/test-config.yaml

echo ""
echo "=== After sed ==="
sed -e 's/__GIT_USER_NAME__/Securexai/g' \
    -e 's/__GIT_USER_EMAIL__/github.com.valium091@passmail.com/g' \
    /tmp/test-config.yaml

rm -f /tmp/test-config.yaml
```

### Expected Output
```
=== Before sed ===
# Template
name = __GIT_USER_NAME__
email = __GIT_USER_EMAIL__

# Validation (PROTECTED with partial match)
if grep -q "__GIT_USER_" /tmp/test; then
  echo "WARNING - Placeholder found"
fi

=== After sed ===
# Template
name = Securexai
email = github.com.valium091@passmail.com

# Validation (PROTECTED with partial match)
if grep -q "__GIT_USER_" /tmp/test; then  ← UNCHANGED! ✓
  echo "WARNING - Placeholder found"
fi
```

---

## Action Items

1. **Update cloudops-config-v2.yaml** (lines 1246-1252)
   - Change `"__GIT_USER_NAME__"` to `"__GIT_USER_"`
   - Change `"__GIT_WORK_NAME__"` to `"__GIT_WORK_"`

2. **Test the fix**
   ```bash
   # Generate customized config
   sed -e 's/__GIT_USER_NAME__/Securexai/g' \
       -e 's/__GIT_USER_EMAIL__/github.com.valium091@passmail.com/g' \
       -e 's/__GIT_WORK_NAME__/Sergio Tapia/g' \
       -e 's/__GIT_WORK_EMAIL__/s.tapia@globant.com/g' \
       cloudops-config-v2.yaml > cloudops-config-custom.yaml

   # Verify validation logic is intact
   grep -A 2 "Check if placeholders" cloudops-config-custom.yaml
   # Should show: if grep -q "__GIT_USER_" ...
   ```

3. **Deploy to production**

---

## Timeline

- **Discovery:** 2025-11-16
- **Severity:** HIGH (breaks validation, causes false positives)
- **Fix Complexity:** LOW (2 lines changed)
- **Testing Time:** 5 minutes
- **Deployment Risk:** LOW (simple pattern change)

**Status:** BLOCKING ISSUE - Must fix before deployment

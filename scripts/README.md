# Scripts

This directory contains utility scripts for maintaining the CloudOps Multipass project.

## Documentation Validation

### validate-docs.ps1 (PowerShell - Windows)

PowerShell script for validating documentation files.

**Usage:**

```powershell
.\scripts\validate-docs.ps1
```

**Requirements:**
- PowerShell 5.1 or later
- Optional: `markdownlint-cli2` for markdown linting

**Install markdownlint-cli2:**

```powershell
npm install -g markdownlint-cli2
```

### validate-docs.sh (Bash - Linux/macOS)

Bash script for validating documentation files.

**Usage:**

```bash
./scripts/validate-docs.sh
```

**Requirements:**
- Bash 4.0 or later
- Optional: `markdownlint-cli2` for markdown linting

**Install markdownlint-cli2:**

```bash
npm install -g markdownlint-cli2
```

## What the Validation Scripts Check

Both scripts perform the same validation checks:

1. **Broken Internal Links**
   - Verifies all markdown links `[text](path)` point to existing files
   - Skips external URLs and anchor-only links
   - Reports missing files with line numbers

2. **Date Format Consistency**
   - Ensures all dates use ISO 8601 format (YYYY-MM-DD)
   - Detects non-standard formats like "November 14, 2025" or "11/14/2025"
   - Skips historical test results (VALIDATION_RESULTS.md)

3. **Common Issues**
   - Terminology consistency (cloudops vs Devbox)
   - Unresolved TODO/FIXME markers
   - HTTP URLs (suggests HTTPS)
   - Capitalization of product names

4. **Markdown Linting**
   - Runs `markdownlint-cli2` if available
   - Checks CommonMark compliance
   - Validates markdown syntax and formatting

## Exit Codes

- `0` - All checks passed
- `1` - Validation failed (errors found)

## Running Before Commits

**Recommended workflow:**

```bash
# Make changes to documentation
vim README.md

# Validate changes
./scripts/validate-docs.sh  # or .ps1 on Windows

# Fix any errors
# ...

# Commit when validation passes
git add .
git commit -m "docs: update README"
```

## Integration with CI/CD

You can add these scripts to your CI/CD pipeline:

**GitHub Actions example:**

```yaml
name: Validate Documentation

on: [push, pull_request]

jobs:
  validate-docs:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Install Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '20'
      - name: Install markdownlint-cli2
        run: npm install -g markdownlint-cli2
      - name: Validate documentation
        run: ./scripts/validate-docs.sh
```

## Troubleshooting

### "command not found: markdownlint-cli2"

Install it globally:

```bash
npm install -g markdownlint-cli2
```

Or run the script anyway - it will skip markdown linting but still perform other checks.

### "Permission denied" (Linux/macOS)

Make the script executable:

```bash
chmod +x scripts/validate-docs.sh
```

### PowerShell execution policy error

Set execution policy to allow running scripts:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

---

**Last Updated**: 2025-11-14
**Maintained by**: CloudOps Development Team

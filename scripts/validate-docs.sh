#!/usr/bin/env bash
#
# Documentation Validator for CloudOps Multipass
#
# This script performs comprehensive validation of markdown documentation:
# - Checks for broken internal links
# - Verifies date format consistency (ISO 8601)
# - Detects common typos and issues
# - Validates markdown syntax (if markdownlint-cli2 is available)
#
# Usage: ./validate-docs.sh
#
# Last Updated: 2025-11-14

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
EXIT_CODE=0

echo -e "${CYAN}=====================================${NC}"
echo -e "${CYAN}CloudOps Documentation Validator${NC}"
echo -e "${CYAN}=====================================${NC}"
echo ""

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to find all markdown files
find_markdown_files() {
    find "$PROJECT_ROOT" -type f -name "*.md" \
        ! -path "*/node_modules/*" \
        ! -path "*/.git/*"
}

# Test 1: Check for broken internal links
echo -e "${YELLOW}[1/4] Checking for broken internal links...${NC}"

BROKEN_LINKS=0

while IFS= read -r file; do
    # Extract markdown links [text](path)
    while IFS= read -r link; do
        # Skip empty lines
        [[ -z "$link" ]] && continue

        # Skip external URLs
        [[ "$link" =~ ^https?:// ]] && continue

        # Skip anchor-only links
        [[ "$link" =~ ^# ]] && continue

        # Remove anchor from path
        clean_path="${link%%#*}"
        [[ -z "$clean_path" ]] && continue

        # Resolve relative path
        file_dir="$(dirname "$file")"
        target_path="$file_dir/$clean_path"

        if [[ ! -e "$target_path" ]]; then
            echo -e "  ${RED}❌ $(basename "$file"): $link${NC}"
            ((BROKEN_LINKS++))
        fi
    done < <(grep -oP '\[([^\]]+)\]\(\K[^)]+' "$file" 2>/dev/null || true)
done < <(find_markdown_files)

if [[ $BROKEN_LINKS -eq 0 ]]; then
    echo -e "  ${GREEN}✓ All internal links are valid${NC}"
else
    echo -e "  ${RED}❌ Found $BROKEN_LINKS broken link(s)${NC}"
    EXIT_CODE=1
fi

echo ""

# Test 2: Verify date format consistency (ISO 8601)
echo -e "${YELLOW}[2/4] Checking date format consistency...${NC}"

INCONSISTENT_DATES=0

while IFS= read -r file; do
    # Skip historical validation results (contains log timestamps)
    [[ "$(basename "$file")" == "VALIDATION_RESULTS.md" ]] && continue

    # Check for full month names
    if grep -nE '(January|February|March|April|May|June|July|August|September|October|November|December)\s+[0-9]{1,2},?\s+[0-9]{4}' "$file" >/dev/null 2>&1; then
        matches=$(grep -nE '(January|February|March|April|May|June|July|August|September|October|November|December)\s+[0-9]{1,2},?\s+[0-9]{4}' "$file")
        echo -e "  ${YELLOW}⚠ $(basename "$file"): Full month name format${NC}"
        echo "$matches" | while read -r match; do
            echo -e "    ${YELLOW}Line $match${NC}"
        done
        ((INCONSISTENT_DATES++))
    fi

    # Check for abbreviated months
    if grep -nE '(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\s+[0-9]{1,2}' "$file" >/dev/null 2>&1; then
        matches=$(grep -nE '(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\s+[0-9]{1,2}' "$file")
        echo -e "  ${YELLOW}⚠ $(basename "$file"): Abbreviated month format${NC}"
        echo "$matches" | while read -r match; do
            echo -e "    ${YELLOW}Line $match${NC}"
        done
        ((INCONSISTENT_DATES++))
    fi

    # Check for slash format
    if grep -nE '[0-9]{1,2}/[0-9]{1,2}/[0-9]{4}' "$file" >/dev/null 2>&1; then
        matches=$(grep -nE '[0-9]{1,2}/[0-9]{1,2}/[0-9]{4}' "$file")
        echo -e "  ${YELLOW}⚠ $(basename "$file"): Slash format${NC}"
        echo "$matches" | while read -r match; do
            echo -e "    ${YELLOW}Line $match${NC}"
        done
        ((INCONSISTENT_DATES++))
    fi
done < <(find_markdown_files)

if [[ $INCONSISTENT_DATES -eq 0 ]]; then
    echo -e "  ${GREEN}✓ All dates use ISO 8601 format${NC}"
else
    echo -e "  ${YELLOW}⚠ Found inconsistent date format(s)${NC}"
    echo -e "  ${CYAN}ℹ Expected format: YYYY-MM-DD (e.g., 2025-11-14)${NC}"
fi

echo ""

# Test 3: Check for common typos and issues
echo -e "${YELLOW}[3/4] Checking for common issues...${NC}"

ERROR_COUNT=0
WARNING_COUNT=0
INFO_COUNT=0

while IFS= read -r file; do
    # Check for "devbox tool" (should be "Devbox" capitalized)
    if grep -nE '\bdevbox tool\b|\bdevbox CLI\b' "$file" >/dev/null 2>&1; then
        echo -e "  ${YELLOW}⚠ $(basename "$file"): Use 'Devbox' (capitalized) for product name${NC}"
        ((WARNING_COUNT++))
    fi

    # Check for "Devbox user" (should be "cloudops user")
    if grep -nE '\bDevbox user\b|\bDevbox account\b' "$file" >/dev/null 2>&1; then
        echo -e "  ${RED}❌ $(basename "$file"): User account is 'cloudops', not Devbox${NC}"
        ((ERROR_COUNT++))
        EXIT_CODE=1
    fi

    # Check for TODO/FIXME markers
    if grep -nE '\[TODO\]|\[FIXME\]|\[XXX\]' "$file" >/dev/null 2>&1; then
        echo -e "  ${YELLOW}⚠ $(basename "$file"): Unresolved TODO/FIXME marker${NC}"
        ((WARNING_COUNT++))
    fi

    # Check for HTTP URLs (should use HTTPS)
    if grep -nE 'http://(?!localhost)' "$file" >/dev/null 2>&1; then
        echo -e "  ${CYAN}ℹ $(basename "$file"): HTTP URL (consider HTTPS if external)${NC}"
        ((INFO_COUNT++))
    fi
done < <(find_markdown_files)

if [[ $ERROR_COUNT -eq 0 && $WARNING_COUNT -eq 0 && $INFO_COUNT -eq 0 ]]; then
    echo -e "  ${GREEN}✓ No common issues found${NC}"
else
    [[ $ERROR_COUNT -gt 0 ]] && echo -e "  ${RED}❌ Found $ERROR_COUNT error(s)${NC}"
    [[ $WARNING_COUNT -gt 0 ]] && echo -e "  ${YELLOW}⚠ Found $WARNING_COUNT warning(s)${NC}"
    [[ $INFO_COUNT -gt 0 ]] && echo -e "  ${CYAN}ℹ Found $INFO_COUNT info item(s)${NC}"
fi

echo ""

# Test 4: Run markdownlint if available
echo -e "${YELLOW}[4/4] Running markdown linter...${NC}"

if command_exists markdownlint-cli2; then
    if markdownlint-cli2 "**/*.md" "#node_modules" 2>&1; then
        echo -e "  ${GREEN}✓ All markdown files pass linting${NC}"
    else
        echo -e "  ${RED}❌ Markdown linting errors found${NC}"
        EXIT_CODE=1
    fi
else
    echo -e "  ${YELLOW}⚠ markdownlint-cli2 not installed (skipping)${NC}"
    echo -e "    ${CYAN}Install with: npm install -g markdownlint-cli2${NC}"
fi

echo ""
echo -e "${CYAN}=====================================${NC}"

if [[ $EXIT_CODE -eq 0 ]]; then
    echo -e "${GREEN}✓ Documentation validation passed!${NC}"
else
    echo -e "${RED}❌ Documentation validation failed${NC}"
    echo -e "${YELLOW}Please fix the errors above before committing.${NC}"
fi

echo -e "${CYAN}=====================================${NC}"

exit $EXIT_CODE

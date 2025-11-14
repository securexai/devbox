#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Validates documentation files for the CloudOps Multipass project.

.DESCRIPTION
    This script performs comprehensive validation of markdown documentation:
    - Checks for broken internal links
    - Verifies date format consistency (ISO 8601)
    - Detects common typos and issues
    - Validates markdown syntax (if markdownlint-cli2 is available)

.EXAMPLE
    .\validate-docs.ps1
    Runs all validation checks on documentation files.

.NOTES
    Last Updated: 2025-11-14
    Requires: PowerShell 5.1 or later
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$ProjectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$ExitCode = 0

Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "CloudOps Documentation Validator" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

# Function to check if a command exists
function Test-Command {
    param([string]$Command)
    $null -ne (Get-Command $Command -ErrorAction SilentlyContinue)
}

# Function to find all markdown files
function Get-MarkdownFiles {
    Get-ChildItem -Path $ProjectRoot -Recurse -Filter "*.md" |
        Where-Object { $_.FullName -notmatch '\\node_modules\\|\\\.git\\' }
}

# Test 1: Check for broken internal links
Write-Host "[1/4] Checking for broken internal links..." -ForegroundColor Yellow

$MarkdownFiles = Get-MarkdownFiles
$BrokenLinks = @()

foreach ($File in $MarkdownFiles) {
    $Content = Get-Content $File.FullName -Raw

    # Find markdown links [text](path)
    $Links = [regex]::Matches($Content, '\[([^\]]+)\]\(([^)]+)\)')

    foreach ($Link in $Links) {
        $LinkPath = $Link.Groups[2].Value

        # Skip external URLs
        if ($LinkPath -match '^https?://') { continue }

        # Skip anchors only
        if ($LinkPath -match '^#') { continue }

        # Remove anchor from path
        $CleanPath = $LinkPath -replace '#.*$', ''
        if ([string]::IsNullOrWhiteSpace($CleanPath)) { continue }

        # Resolve relative path
        $TargetPath = Join-Path (Split-Path $File.FullName) $CleanPath
        $TargetPath = [System.IO.Path]::GetFullPath($TargetPath)

        if (-not (Test-Path $TargetPath)) {
            $BrokenLinks += [PSCustomObject]@{
                File = $File.Name
                Link = $LinkPath
                Target = $TargetPath
            }
        }
    }
}

if ($BrokenLinks.Count -gt 0) {
    Write-Host "  ❌ Found $($BrokenLinks.Count) broken link(s):" -ForegroundColor Red
    $BrokenLinks | ForEach-Object {
        Write-Host "     - $($_.File): $($_.Link)" -ForegroundColor Red
    }
    $ExitCode = 1
} else {
    Write-Host "  ✓ All internal links are valid" -ForegroundColor Green
}

Write-Host ""

# Test 2: Verify date format consistency (ISO 8601)
Write-Host "[2/4] Checking date format consistency..." -ForegroundColor Yellow

$InconsistentDates = @()
$DatePatterns = @(
    @{ Pattern = '(January|February|March|April|May|June|July|August|September|October|November|December)\s+\d{1,2},?\s+\d{4}'; Type = 'Full month name' }
    @{ Pattern = '(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\s+\d{1,2}(?:,\s+\d{4})?'; Type = 'Abbreviated month' }
    @{ Pattern = '\d{1,2}/\d{1,2}/\d{4}'; Type = 'Slash format' }
)

foreach ($File in $MarkdownFiles) {
    # Skip historical validation results (contains log timestamps)
    if ($File.Name -eq 'VALIDATION_RESULTS.md') { continue }

    $Content = Get-Content $File.FullName -Raw
    $LineNumber = 1

    foreach ($Line in (Get-Content $File.FullName)) {
        foreach ($DatePattern in $DatePatterns) {
            if ($Line -match $DatePattern.Pattern) {
                $InconsistentDates += [PSCustomObject]@{
                    File = $File.Name
                    Line = $LineNumber
                    Type = $DatePattern.Type
                    Text = $Matches[0]
                }
            }
        }
        $LineNumber++
    }
}

if ($InconsistentDates.Count -gt 0) {
    Write-Host "  ⚠ Found $($InconsistentDates.Count) non-ISO 8601 date(s):" -ForegroundColor Yellow
    $InconsistentDates | ForEach-Object {
        Write-Host "     - $($_.File):$($_.Line) ($($_.Type)): $($_.Text)" -ForegroundColor Yellow
    }
    Write-Host "  ℹ Expected format: YYYY-MM-DD (e.g., 2025-11-14)" -ForegroundColor Cyan
} else {
    Write-Host "  ✓ All dates use ISO 8601 format" -ForegroundColor Green
}

Write-Host ""

# Test 3: Check for common typos and issues
Write-Host "[3/4] Checking for common issues..." -ForegroundColor Yellow

$CommonIssues = @()
$IssuePatterns = @(
    @{ Pattern = 'devbox tool|devbox CLI'; Description = 'Should be "Devbox" (capitalized) for the product name'; Severity = 'Warning' }
    @{ Pattern = 'Devbox user|Devbox account'; Description = 'User account is "cloudops", not Devbox'; Severity = 'Error' }
    @{ Pattern = '\[TODO\]|\[FIXME\]|\[XXX\]'; Description = 'Unresolved TODO/FIXME marker'; Severity = 'Warning' }
    @{ Pattern = 'http://(?!localhost)'; Description = 'HTTP URL (should use HTTPS if external)'; Severity = 'Info' }
)

foreach ($File in $MarkdownFiles) {
    $Content = Get-Content $File.FullName -Raw
    $LineNumber = 1

    foreach ($Line in (Get-Content $File.FullName)) {
        foreach ($Issue in $IssuePatterns) {
            if ($Line -match $Issue.Pattern) {
                $CommonIssues += [PSCustomObject]@{
                    File = $File.Name
                    Line = $LineNumber
                    Severity = $Issue.Severity
                    Description = $Issue.Description
                    Text = $Matches[0]
                }
            }
        }
        $LineNumber++
    }
}

if ($CommonIssues.Count -gt 0) {
    $ErrorIssues = $CommonIssues | Where-Object { $_.Severity -eq 'Error' }
    $WarningIssues = $CommonIssues | Where-Object { $_.Severity -eq 'Warning' }
    $InfoIssues = $CommonIssues | Where-Object { $_.Severity -eq 'Info' }

    if ($ErrorIssues.Count -gt 0) {
        Write-Host "  ❌ Found $($ErrorIssues.Count) error(s):" -ForegroundColor Red
        $ErrorIssues | ForEach-Object {
            Write-Host "     - $($_.File):$($_.Line): $($_.Description)" -ForegroundColor Red
        }
        $ExitCode = 1
    }

    if ($WarningIssues.Count -gt 0) {
        Write-Host "  ⚠ Found $($WarningIssues.Count) warning(s):" -ForegroundColor Yellow
        $WarningIssues | ForEach-Object {
            Write-Host "     - $($_.File):$($_.Line): $($_.Description)" -ForegroundColor Yellow
        }
    }

    if ($InfoIssues.Count -gt 0) {
        Write-Host "  ℹ Found $($InfoIssues.Count) info item(s):" -ForegroundColor Cyan
        $InfoIssues | ForEach-Object {
            Write-Host "     - $($_.File):$($_.Line): $($_.Description)" -ForegroundColor Cyan
        }
    }
} else {
    Write-Host "  ✓ No common issues found" -ForegroundColor Green
}

Write-Host ""

# Test 4: Run markdownlint if available
Write-Host "[4/4] Running markdown linter..." -ForegroundColor Yellow

if (Test-Command 'markdownlint-cli2') {
    $LintOutput = & markdownlint-cli2 "**/*.md" "#node_modules" 2>&1

    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✓ All markdown files pass linting" -ForegroundColor Green
    } else {
        Write-Host "  ❌ Markdown linting errors found:" -ForegroundColor Red
        Write-Host $LintOutput -ForegroundColor Red
        $ExitCode = 1
    }
} else {
    Write-Host "  ⚠ markdownlint-cli2 not installed (skipping)" -ForegroundColor Yellow
    Write-Host "    Install with: npm install -g markdownlint-cli2" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "=====================================" -ForegroundColor Cyan

if ($ExitCode -eq 0) {
    Write-Host "✓ Documentation validation passed!" -ForegroundColor Green
} else {
    Write-Host "❌ Documentation validation failed" -ForegroundColor Red
    Write-Host "Please fix the errors above before committing." -ForegroundColor Yellow
}

Write-Host "=====================================" -ForegroundColor Cyan

exit $ExitCode

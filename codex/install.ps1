# =============================================================================
# VibeFlow Installer for Codex (Windows PowerShell, local checkout)
# =============================================================================
#
# Usage from a cloned checkout:
#   cd E:\github\vibeflow
#   .\codex\install.ps1
#
# Optional source root override:
#   $env:VIBEFLOW_SOURCE_ROOT="E:\github\vibeflow"; .\codex\install.ps1
#
# After installation, restart Codex to pick up the new skills.
#

param(
    [string]$SourceRoot = $env:VIBEFLOW_SOURCE_ROOT
)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $PSCommandPath
$DefaultSourceRoot = (Resolve-Path (Join-Path $ScriptDir "..")).Path
if ([string]::IsNullOrWhiteSpace($SourceRoot)) {
    $SourceRoot = $DefaultSourceRoot
} else {
    $SourceRoot = (Resolve-Path -LiteralPath $SourceRoot).Path
}

$CodexHome = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $env:USERPROFILE ".codex" }
$InstallDir = Join-Path $CodexHome "vibeflow"
$SkillsDir = Join-Path $CodexHome "skills"

function Write-Info { param($Message) Write-Host "INFO: $Message" }
function Write-Success { param($Message) Write-Host "SUCCESS: $Message" }
function Write-Err { param($Message) Write-Host "ERROR: $Message" -ForegroundColor Red }

function Get-SourceVersion {
    param([string]$Root)

    $PluginJson = Join-Path $Root ".claude-plugin\plugin.json"
    if (Test-Path $PluginJson) {
        try {
            $pluginContent = Get-Content $PluginJson -Raw | ConvertFrom-Json
            if ($pluginContent.version) {
                return [string]$pluginContent.version
            }
        } catch {
        }
    }

    $MarketplaceJson = Join-Path $Root ".claude-plugin\marketplace.json"
    if (Test-Path $MarketplaceJson) {
        try {
            $marketplaceContent = Get-Content $MarketplaceJson -Raw | ConvertFrom-Json
            if ($marketplaceContent.plugins -and $marketplaceContent.plugins.Count -gt 0 -and $marketplaceContent.plugins[0].version) {
                return [string]$marketplaceContent.plugins[0].version
            }
        } catch {
        }
    }

    return "unknown"
}

function Copy-LocalTree {
    param(
        [string]$Source,
        [string]$Destination
    )

    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        throw "git is not installed"
    }

    $files = & git -C $Source ls-files -co --exclude-standard
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to enumerate files from $Source"
    }

    foreach ($relativePath in $files | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }) {
        $sourcePath = Join-Path $Source $relativePath
        if (-not (Test-Path -LiteralPath $sourcePath)) {
            continue
        }

        $targetPath = Join-Path $Destination $relativePath
        $targetParent = Split-Path -Parent $targetPath
        if (-not (Test-Path -LiteralPath $targetParent)) {
            New-Item -ItemType Directory -Force -Path $targetParent | Out-Null
        }

        Copy-Item -LiteralPath $sourcePath -Destination $targetPath -Force
    }
}

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Err "git is not installed"
    exit 1
}

if (-not (Test-Path $SourceRoot)) {
    Write-Err "source root not found: $SourceRoot"
    exit 1
}

Write-Info "Installing vibeflow for Codex from local checkout..."
Write-Info "Source root: $SourceRoot"

if (-not (Test-Path $CodexHome)) {
    New-Item -ItemType Directory -Force -Path $CodexHome | Out-Null
}
if (-not (Test-Path $SkillsDir)) {
    New-Item -ItemType Directory -Force -Path $SkillsDir | Out-Null
}

if (Test-Path $InstallDir) {
    Write-Info "Removing existing installation at $InstallDir..."
    Remove-Item $InstallDir -Recurse -Force
}

New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
Copy-LocalTree -Source $SourceRoot -Destination $InstallDir

$SourceSkillsDir = Join-Path $InstallDir "skills"
if (-not (Test-Path $SourceSkillsDir)) {
    Write-Err "skills directory not found in local checkout"
    exit 1
}

Get-ChildItem $SourceSkillsDir -Directory | ForEach-Object {
    $SkillName = $_.Name
    $TargetPath = Join-Path $SkillsDir $SkillName
    if (Test-Path $TargetPath) {
        Remove-Item $TargetPath -Recurse -Force
    }
    New-Item -ItemType Junction -Path $TargetPath -Target $_.FullName | Out-Null
}

$InstalledVersion = Get-SourceVersion -Root $InstallDir

Write-Host ""
Write-Success "VibeFlow installed for Codex."
Write-Host ""
Write-Host "  Source:   $SourceRoot"
Write-Host "  Repo:     $InstallDir"
Write-Host "  Skills:   $SkillsDir"
Write-Host "  Version:  $InstalledVersion"
Write-Host ""
Write-Host "Restart Codex to pick up the new skills."

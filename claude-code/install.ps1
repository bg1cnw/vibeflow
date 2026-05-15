# =============================================================================
# Claude Code Marketplace Installer (Windows PowerShell, local checkout)
# =============================================================================
#
# Usage from a cloned checkout:
#   cd E:\github\vibeflow
#   .\claude-code\install.ps1
#
# Optional source root override:
#   $env:VIBEFLOW_SOURCE_ROOT="E:\github\vibeflow"; .\claude-code\install.ps1
#
# After installation, use Claude Code to install the plugin:
#   /plugin install vibeflow@vibeflow
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

$MarketplaceName = "vibeflow"
$ClaudePluginsDir = Join-Path $env:USERPROFILE ".claude\plugins"
$MarketplacesDir = Join-Path $ClaudePluginsDir "marketplaces"
$TargetDir = Join-Path $MarketplacesDir $MarketplaceName
$KnownMarketplacesFile = Join-Path $ClaudePluginsDir "known_marketplaces.json"

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

Write-Info "Installing vibeflow marketplace from local checkout..."
Write-Info "Source root: $SourceRoot"

if (-not (Test-Path $MarketplacesDir)) {
    New-Item -ItemType Directory -Force -Path $MarketplacesDir | Out-Null
}

if (Test-Path $TargetDir) {
    Write-Info "Removing existing installation at $TargetDir..."
    Remove-Item $TargetDir -Recurse -Force
}

New-Item -ItemType Directory -Force -Path $TargetDir | Out-Null
Copy-LocalTree -Source $SourceRoot -Destination $TargetDir

$MarketplaceJson = Join-Path $TargetDir ".claude-plugin\marketplace.json"
if (-not (Test-Path $MarketplaceJson)) {
    Write-Err "marketplace.json not found in local checkout"
    exit 1
}

$CleanVersion = Get-SourceVersion -Root $TargetDir

Write-Info "Updating registration metadata..."

if (-not (Test-Path $ClaudePluginsDir)) {
    New-Item -ItemType Directory -Force -Path $ClaudePluginsDir | Out-Null
}

if (-not (Test-Path $KnownMarketplacesFile)) {
    [System.IO.File]::WriteAllText($KnownMarketplacesFile, '{}', (New-Object System.Text.UTF8Encoding($false)))
}

$jsonContent = Get-Content $KnownMarketplacesFile -Raw
$json = $jsonContent | ConvertFrom-Json

$timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.000Z")

$marketplaceEntry = @{
    source = @{
        source = "local"
        path = $SourceRoot
    }
    installLocation = $TargetDir
    lastUpdated = $timestamp
}
$json | Add-Member -MemberType NoteProperty -Name $MarketplaceName -Value $marketplaceEntry -Force

$compact = $json | ConvertTo-Json -Depth 10 -Compress
[System.IO.File]::WriteAllText($KnownMarketplacesFile, $compact, (New-Object System.Text.UTF8Encoding($false)))

$verifyContent = Get-Content $KnownMarketplacesFile -Raw | ConvertFrom-Json
if (-not $verifyContent.PSObject.Properties.Name.Contains($MarketplaceName)) {
    Write-Err "Marketplace registration failed"
    exit 1
}

Write-Host ""
Write-Success "VibeFlow marketplace installed successfully!"
Write-Host ""
Write-Host "  Marketplace key: $MarketplaceName"
Write-Host "  Source:          $SourceRoot"
Write-Host "  Install path:    $TargetDir"
Write-Host "  Version:         $CleanVersion"
Write-Host ""
Write-Host "To activate the plugin, run in Claude Code:"
Write-Host "  /plugin install vibeflow@vibeflow"

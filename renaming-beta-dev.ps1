<#
.SYNOPSIS
    Updates or adds entries in a .env file based on discovered .pem files.

.PARAMETER DryRun
    Optional switch to simulate changes without modifying the file.
#>

param (
    [switch]$DryRun
)

# Inform about dry run mode
if ($DryRun) {
    Write-Host "🧪 Running in Dry Run mode. No changes will be made." -ForegroundColor Cyan
}

# Get script directory
$scriptDir = $PSScriptRoot
if (-not $scriptDir) { $scriptDir = Get-Location }

# Path to .env
$envPath = Join-Path $scriptDir ".env"

if (-not (Test-Path $envPath)) {
    Write-Error "❌ .env file not found in $scriptDir!"
    exit 1
}

# Find .pem files
$pemFiles = Get-ChildItem -Path $scriptDir -Filter "*.pem"

if ($pemFiles.Count -eq 0) {
    Write-Warning "No .pem files found in $scriptDir."
    exit
}

# Ask user which .env keys to update
$updates = @()
foreach ($pem in $pemFiles) {
    Write-Host "`nFound: $($pem.Name)"
    $key = Read-Host "Enter the .env key you want to update for '$($pem.Name)' (or press Enter to skip)"
    if ($key) {
        $updates += [PSCustomObject]@{
            EnvKey  = $key
            NewPath = $pem.Name
        }
    } else {
        Write-Host "⏭ Skipping $($pem.Name)"
    }
}

if ($updates.Count -eq 0) {
    Write-Host "❌ No updates to apply. Exiting."
    exit
}

# Read .env file content
$envLines = Get-Content $envPath
$updatedLines = @()

foreach ($line in $envLines) {
    $matched = $false

    foreach ($update in $updates) {
        if ($line -match "^\s*${($update.EnvKey -replace '\$', '\$')}\s*=") {
            $updatedLines += "$($update.EnvKey)=$($update.NewPath)"
            Write-Host "✅ Updated: $($update.EnvKey) => $($update.NewPath)"
            $matched = $true
            break
        }
    }

    if (-not $matched) {
        $updatedLines += $line
    }
}

# Add any missing keys
foreach ($update in $updates) {
    if (-not ($envLines -match "^\s*${($update.EnvKey -replace '\$', '\$')}\s*=")) {
        $updatedLines += "$($update.EnvKey)=$($update.NewPath)"
        Write-Host "🆕 Added new key: $($update.EnvKey)"
    }
}

# Write changes or simulate
if ($DryRun) {
    Write-Host "`n📄 Proposed .env content:" -ForegroundColor Yellow
    $updatedLines | ForEach-Object { Write-Host $_ }
} else {
    try {
        Copy-Item -Path $envPath -Destination "${envPath}.bak" -Force
        $updatedLines | Set-Content -Path $envPath -Encoding UTF8
        Write-Host "`n✅ .env updated successfully." -ForegroundColor Green
    } catch {
        Write-Error "❌ Failed to write updated .env file: $_"
    }
}

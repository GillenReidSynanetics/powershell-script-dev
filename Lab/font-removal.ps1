<#
.SYNOPSIS
    Script to remove all fonts from the system fonts folder and specifically target a font for removal.

.DESCRIPTION
    This script removes all fonts from the system fonts folder and deletes their corresponding registry keys.
    Additionally, it targets a specific font for removal by its base name.

.PARAMETER fontToRemove
    The base name of the specific font to remove.

.FUNCTIONS
    Remove-Font
        Removes a font by its name and deletes its corresponding registry key.

.NOTES
    - The script removes all fonts with .ttf and .otf extensions from the system fonts folder.
    - It specifically targets a font defined by the $fontToRemove variable for removal.
    - The script uses the -Force and -ErrorAction SilentlyContinue parameters to handle errors silently.

.EXAMPLE
    # Define the specific font to remove
    $fontToRemove = "Neusa Next Std Medium"

    # Run the script to remove all fonts and specifically target the defined font for removal
    .\font-removal.ps1
#>
# Define the specific font to remove in addition to other fonts
$fontToRemove = "FONTNAMEGOESHERE"

# Function to remove a font by name
function Remove-Font {
    param (
        [string]$fontbasename,
        [string]$fontname,
        [string]$fontvalue
    )

    $regpath = "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Fonts"
    Write-Host "Removing $fontname..."
    Remove-Item "C:\Windows\Fonts\$fontname" -Force -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path $regpath -Name $fontvalue -Force -ErrorAction SilentlyContinue
    Write-Host "$fontname has been removed or was not found."
}

# Function to process font removal
function Remove-FontRemoval {
    param (
        [array]$fonts
    )

    foreach ($Font in $fonts) {
        $fontbasename = $Font.basename
        $fontname = $Font.name

        if ($Font.Extension -eq ".ttf") {
            $fontvalue = $Font.Basename + " (TrueType)"
        } elseif ($Font.Extension -eq ".otf") {
            $fontvalue = $Font.Basename + " (OpenType)"
        } else {
            Write-Host "Font extension not supported" -ForegroundColor Blue -BackgroundColor White
            continue
        }

        Remove-Font -fontbasename $fontbasename -fontname $fontname -fontvalue $fontvalue
    }
}

# Get all fonts from Fonts Folder
$allFonts = Get-ChildItem "C:\Windows\Fonts"
Remove-FontRemoval -fonts $allFonts

# Specifically target the font to remove
$fontToRemoveFiles = Get-ChildItem -Path "C:\Windows\Fonts" | Where-Object { $_.BaseName -eq $fontToRemove }
Remove-FontRemoval -fonts $fontToRemoveFiles

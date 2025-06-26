# =====================
# Setup
Add-Type -AssemblyName System.Windows.Forms
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

# Create a topmost window to parent the dialogs
$null = [System.Windows.Forms.Application]::EnableVisualStyles()
$form = New-Object System.Windows.Forms.Form
$form.TopMost = $true
$form.WindowState = 'Minimized'
$form.ShowInTaskbar = $false
$form.Show()

try {
    $scriptPath = Split-Path -Path $MyInvocation.MyCommand.Path -Parent
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupFolder = Join-Path -Path $scriptPath -ChildPath "BackupFolder $timestamp"
    New-Item -ItemType Directory -Path $backupFolder -Force | Out-Null

    # =====================
    # Multi-File Picker
    $fileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $fileDialog.InitialDirectory = [Environment]::GetFolderPath("Desktop")
    $fileDialog.Filter = "All files (*.*)|*.*"
    $fileDialog.Multiselect = $true
    $fileDialog.Title = "Select files to back up" # Select multiple files using CTRL

    if ($fileDialog.ShowDialog($form) -eq [System.Windows.Forms.DialogResult]::OK) {
        foreach ($file in $fileDialog.FileNames) {
            $destPath = Join-Path -Path $backupFolder -ChildPath (Split-Path -Path $file -Leaf)
            Copy-Item -Path $file -Destination $destPath -Force
            Write-Host "📄 Backed up file: $destPath"
        }
    } else {
        Write-Host "ℹ️ No files selected."
    }

    # =====================
    # Multi-Folder Picker (loop until cancel)
    $selectedFolders = @()
    do {
        $folderDialog = New-Object System.Windows.Forms.FolderBrowserDialog
        $folderDialog.Description = "Select a folder to back up (Cancel to finish)"
        $folderDialog.ShowNewFolderButton = $false

        if ($folderDialog.ShowDialog($form) -eq [System.Windows.Forms.DialogResult]::OK) {
            $selectedFolders += $folderDialog.SelectedPath
        } else {
            break
        }
    } while ($true)

    foreach ($folder in $selectedFolders) {
        $folderName = Split-Path $folder -Leaf
        $destinationFolder = Join-Path -Path $backupFolder -ChildPath $folderName
        Copy-Item -Path $folder -Destination $destinationFolder -Recurse -Force
        Write-Host "📁 Backed up folder: $destinationFolder"
    }
}
catch {
    Write-Error "❌ An error occurred: $_"
}
finally {
    # Dispose the topmost form
    $form.Dispose()

    # =====================
    # Zip + Cleanup
    if (Test-Path $backupFolder) {
        Write-Host "`n🎯 Backup complete. Folder: $backupFolder"
        $zipPath = "$backupFolder.zip"

        try {
            Compress-Archive -Path $backupFolder -DestinationPath $zipPath -Force
            Write-Host "📦 Backup folder compressed to: $zipPath"
            Remove-Item -Path $backupFolder -Recurse -Force
            Write-Host "🧹 Original backup folder removed."
        }
        catch {
            Write-Warning "❌ Failed to zip or clean up backup folder: $($_.Exception.Message)"
        }
    }

    Read-Host "Press Enter to exit"
}
# End of script
# =====================
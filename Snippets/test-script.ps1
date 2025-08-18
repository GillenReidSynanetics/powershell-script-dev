$folderPath = "C:\Path\To\Your\Folder"
$outputFolder = "C:\Path\To\Output\Folder"
$targetPattern = "*.txt"

$files = Get-ChildItem -Path $folderPath -Filter $targetPattern

foreach ($file in $files) {
    $fileName = $file.Name
    $newFileName = "Processed_" + $fileName
    $newFilePath = Join-Path -Path $outputFolder -ChildPath $newFileName

    # Simulate processing the file (e.g., copying it to the output folder)
    Copy-Item -Path $file.FullName -Destination $newFilePath

    Write-Host "Processed file: $fileName -> $newFileName"
}
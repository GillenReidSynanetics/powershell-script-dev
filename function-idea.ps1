$cpu = (Get-Counter '\Processor(_Total)\% Processor Time').CounterSamples.CookedValue
$mem = get-ciminstance win32_operatingsystem | Select-Object -ExpandProperty TotalVisibleMemorySize
$usedMem = $mem.TotalVisibleMemorySize - $mem.FreePhysicalMemory
$disk = Get-PSDrive C


$doc = @{
    timestamp = (Get-Date).ToString("o")
    machine = $env:COMPUTERNAME
    cpu_percent = [math]::Round($cpu, 2)
    memory_used_mb = [math]::Round($usedMem / 1024, 2)
    disk_used_gb = [math]::Round($disk.Used / 1GB, 2)
    disk_free_gb = [math]::Round($disk.Free / 1GB, 2)
}


$json = $doc | ConvertTo-Json -Depth 3


$esUri = "https://2065da5d511746f1a5b5798cc3ccae3b.europe-west2.gcp.elastic-cloud.com:443"

Invoke-RestMethod -Uri $esUri -Method Post -Body $json -Headers @{
    "Content-Type" = "application/json"
}

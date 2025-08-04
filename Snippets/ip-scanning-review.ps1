# Full script with corrected parallel processing using Start-Job

# Step 1: Get the local IP address and subnet mask
$ipConfig = Get-NetIPAddress | Where-Object { $_.AddressFamily -eq 'IPv4' }# -and $_.InterfaceAlias -like 'Ethernet*' }
if (-not $ipConfig) {
    Write-Host "Could not find a valid IPv4 address for an Ethernet adapter."
    exit
}
$ipAddress = $ipConfig.IPAddress
$prefixLength = $ipConfig.PrefixLength
Write-Host "Local IP Address: $ipAddress"
Write-Host "Subnet Prefix Length: $prefixLength"

# Step 2: Generate the IP address list
$ipParts = $ipAddress.Split('.')
$networkBase = "$($ipParts[0]).$($ipParts[1]).$($ipParts[2])."
$ipAddressesToScan = @()
for ($i = 1; $i -le 254; $i++) {
    $ipAddressesToScan += "$networkBase$i"
}
Write-Host "Generated $($ipAddressesToScan.Count) IP addresses to scan."

# Step 3: Start a separate background job for each IP address
Write-Host "Starting parallel scan for active hosts. This will be much faster!"

# Create an array to hold all the job objects
$jobs = @()

# Loop through each IP and start a new job
foreach ($ip in $ipAddressesToScan) {
    # The command we want to run in the background
    # We pass the IP address to the job using the -ArgumentList parameter
    $jobs += Start-Job -ScriptBlock {
        param($ipToTest)
        # We need to return an object so we can get the IP and the status later
        $isOnline = Test-Connection -ComputerName $ipToTest -Quiet -Count 1 -ErrorAction SilentlyContinue
        
        # Return a custom object with the IP and status
        [PSCustomObject]@{
            IP = $ipToTest
            Online = $isOnline
        }
    } -ArgumentList $ip
}

# Step 4: Wait for all the jobs to finish
Write-Host "Waiting for $($jobs.Count) jobs to complete..."
# The -Wait parameter tells the script to pause here until all jobs in the array are done
Wait-Job -Job $jobs | Out-Null # We use Out-Null to suppress the default output of Wait-Job

# Step 5: Gather and display the results
Write-Host "Scan complete."
Write-Host "--------------------"

# Receive-Job retrieves the output from all the jobs
# We can then filter the custom objects to only show the online hosts
$onlineHosts = Receive-Job -Job $jobs -Keep | Where-Object { $_.Online -eq $true }

# Clean up the jobs after we are done
Remove-Job -Job $jobs | Out-Null

Write-Host "The following hosts are online:"
$onlineHosts | Select-Object -ExpandProperty IP

# ... (all the code from Step 1 and 2) ...

# Step 3: Start a separate background job for each IP address
Write-Host "Starting parallel scan for active hosts..."

$jobs = @()
$totalIps = $ipAddressesToScan.Count

# Loop through each IP and start a new job with a progress bar
for ($i = 0; $i -lt $totalIps; $i++) {
    $ip = $ipAddressesToScan[$i]
    
    # Display the progress bar
    Write-Progress -Activity "Network Scan" -Status "Starting job for IP: $ip" -PercentComplete (($i / $totalIps) * 100)
    
    $jobs += Start-Job -ScriptBlock {
        # ... (the script block from the previous code) ...
    } -ArgumentList $ip
}

# The rest of the script to wait for jobs, receive output, and clean up.
# When the loop is done, you can hide the progress bar by calling Write-Progress with no parameters.
Write-Progress -Activity "Network Scan" -Completed
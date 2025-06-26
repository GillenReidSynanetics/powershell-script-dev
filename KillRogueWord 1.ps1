param (
    [switch]$killprocess = $true
 )



[Ref]$kcount = 0 
[Ref]$wcount = 0 


Get-WmiObject Win32_Process | ForEach-Object {
 $CreationDate =  (Get-Date).ToString("yyyyMMddHHmmss")
 if ($_.Name -eq "WINWORD.EXE") {

    
    $wcount.Value++
    $DateTimeEarly = (Get-Date).AddMinutes(-10).ToString("yyyyMMddHHmmss")
    $CreationDate = $_.CreationDate.Split(".")[0]


    $_.Name + " " + $CreationDate + " " + $DateTimeEarly + " " +$_.ProcessId


    if  ($CreationDate -lt $DateTimeEarly) {
        if ($killprocess) {
            $kcount.Value++
            "Stopping "  + $_.Name + " " + $CreationDate + " " +$_.ProcessId
        
            Stop-Process -Id $_.ProcessId 
        }
     
    }

 }

}

""+ $wcount.Value + " Word processes found"
""+ $kcount.Value + " word processed killed"




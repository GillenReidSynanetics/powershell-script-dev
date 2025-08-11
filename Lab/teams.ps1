# Load Win32 mouse_event function
Add-Type @"
using System;
using System.Runtime.InteropServices;
public static class InputSimulator {
    [DllImport("user32.dll", CharSet=CharSet.Auto, CallingConvention=CallingConvention.StdCall)]
    public static extern void mouse_event(int dwFlags, int dx, int dy, int dwData, UIntPtr dwExtraInfo);
}
"@

# Constants for mouse movement
$MOUSEEVENTF_MOVE = 0x0001

function Start-TeamsActive {
    [CmdletBinding()]
    param(
        [int]$IntervalSeconds = 300  # how often to nudge (default: every 5 min)
    )
    Write-Host "Press Ctrl+C to stop..."
    while ($true) {
        # Move mouse 1px right then back
        [InputSimulator]::mouse_event($MOUSEEVENTF_MOVE, 1, 0, 0, [UIntPtr]::Zero)
        [InputSimulator]::mouse_event($MOUSEEVENTF_MOVE, -1, 0, 0, [UIntPtr]::Zero)
        Start-Sleep -Seconds $IntervalSeconds
    }
}

# Run it:
Start-TeamsActive -IntervalSeconds 300

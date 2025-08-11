# Common PowerShell Commands

Here are some common PowerShell commands that can be useful for various tasks:

## File and Directory Operations

- **List files and directories:**
    ```powershell
    Get-ChildItem
    ```

- **Create a new directory:**
    ```powershell
    New-Item -ItemType Directory -Path "C:\Path\To\New\Directory"
    ```

- **Copy a file:**
    ```powershell
    Copy-Item -Path "C:\Path\To\Source\File.txt" -Destination "C:\Path\To\Destination\"
    ```

- **Move a file:**
    ```powershell
    Move-Item -Path "C:\Path\To\Source\File.txt" -Destination "C:\Path\To\Destination\"
    ```

- **Delete a file:**
    ```powershell
    Remove-Item -Path "C:\Path\To\File.txt"
    ```

## System Information

- **Get system information:**
    ```powershell
    Get-ComputerInfo
    ```

- **Get process information:**
    ```powershell
    Get-Process
    ```

- **Get service information:**
    ```powershell
    Get-Service
    ```

## Network Operations

- **Test network connection:**
    ```powershell
    Test-Connection -ComputerName "hostname"
    ```

- **Get IP configuration:**
    ```powershell
    Get-NetIPAddress
    ```

## User and Permissions

- **Get current user:**
    ```powershell
    whoami
    ```

- **Get list of users:**
    ```powershell
    Get-LocalUser
    ```

- **Add a new user:**
    ```powershell
    New-LocalUser -Name "username" -Password (ConvertTo-SecureString "password" -AsPlainText -Force) -FullName "User Full Name"
    ```

## Scripting and Automation

- **Run a script:**
    ```powershell
    .\script.ps1
    ```

- **Schedule a task:**
    ```powershell
    New-ScheduledTaskTrigger -At 3am -Daily
    ```

- **Create a function:**
    ```powershell
    function Get-Greeting {
            param (
                    [string]$Name
            )
            "Hello, $Name!"
    }
    ```

These commands should help you get started with PowerShell for various tasks and automation.
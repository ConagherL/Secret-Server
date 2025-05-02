<#
.SYNOPSIS
Encrypts a specific section of a remote web.config file using aspnet_regiis.exe via PowerShell remoting.

.DESCRIPTION
This script connects to a remote server using the credentials provided and encrypts the specified section
of a web.config file using the .NET aspnet_regiis.exe utility. It supports optional logging and is designed
for integration with Secret Server dependencies or launchers.

.EXPECTED ARGUMENTS
$[1]$USERNAME $[1]$DOMAIN $[1]$PASSWORD $MACHINE "NAME OF SECTION IN WEB CONFIG" "LOCATION OF CONFIG FILE"

.PARAMETER args[0]
The username used to connect to the remote server

.PARAMETER args[1]
The domain prefix used in conjunction with the username.

.PARAMETER args[2]
The password associated with the username.

.PARAMETER args[3]
The name of the target computer where the web.config file resides (e.g., 'webserver01'). Populate the machine field on the dependancy

.PARAMETER args[4]
The name of the web.config section to encrypt (e.g., "connectionStrings").

.PARAMETER args[5]
The full folder path on the remote machine where the web.config file is located
(e.g., "C:\inetpub\wwwroot\MyApp").

.EXAMPLE
powershell.exe -ExecutionPolicy Bypass -File Encrypt-WebConfig.ps1 `
  "svc_app_user" "corp" 'P@ssword!"2024' "web01" "connectionStrings" "C:\inetpub\wwwroot\App"

.NOTES
- Logging output is saved to C:\Temp\WebConfigEncryptLogs\<machine>_<timestamp>.log if enabled.
- The target folder must contain a valid web.config and should be part of an IIS application for aspnet_regiis.exe to function.
- Wrap the password in single quotes in the dependancy to avoid breaking parsing if it contains double quotes or special characters.
- This script is intended to be triggered via Secret Server RPC or dependency changer.

#>


# Expected arguments: $USERNAME $DOMAIN $PASSWORD $MACHINE "NAME OF SECTION IN WEB CONFIG" "LOCATION OF CONFIG FILE"

$privUserName = $args[0]
$prefix       = $args[1]
$privUserName = "$prefix\$privUserName"
$privPassword = ConvertTo-SecureString -AsPlainText $args[2] -Force
$creds        = New-Object System.Management.Automation.PSCredential -ArgumentList $privUserName, $privPassword
$comp         = $args[3]
$sec          = $args[4]
$loc          = $args[5]

# --- FILE PATH FOR ASP.NET TOOL ---
$filePath = Join-Path $env:windir "Microsoft.NET\Framework64\v4.0.30319\aspnet_regiis.exe"
$params   = @("-pef", $sec, $loc)

# --- REMOTE EXECUTION BLOCK ---
Invoke-Command -ComputerName $comp -Credential $creds -ScriptBlock {
    param (
        $filePath,
        $params,
        $loc,
        $sec,
        $remoteComp,
        $origArgs
    )

    $timestamp = (Get-Date).ToString("yyyyMMdd_HHmmss")
    $logDir    = "C:\Temp\WebConfigEncryptLogs"
    $logFile   = Join-Path $logDir "Encrypt_${remoteComp}_$timestamp.log"

    # Ensure log directory exists
    if (-not (Test-Path $logDir)) {
        try {
            New-Item -Path $logDir -ItemType Directory -Force | Out-Null
        } catch {
            Write-Host "Failed to create log directory: $_"
            return
        }
    }

    function Write-RemoteLog {
        param ([string]$msg)
        $ts   = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        $line = "$ts`t$msg"
        Write-Host $line
        try {
            Add-Content -Path $logFile -Value $line
        } catch {
            Write-Host "Failed to write to log file: $_"
        }
    }

    # --- Logging block ---
    Write-RemoteLog "===== REMOTE ENCRYPTION START ====="
    Write-RemoteLog "Running as user: $([Environment]::UserName)"
    Write-RemoteLog "Remote host: $remoteComp"
    Write-RemoteLog "Target section: $sec"
    Write-RemoteLog "Target path: $loc"
    Write-RemoteLog "Log file path: $logFile"
    Write-RemoteLog "Raw arguments: $($origArgs -join ', ')"

    # --- Path validation ---
    if (-not (Test-Path $loc)) {
        Write-RemoteLog "ERROR: Directory does NOT exist: $loc"
        return
    }

    $configPath = Join-Path $loc "web.config"
    if (-not (Test-Path $configPath)) {
        Write-RemoteLog "ERROR: web.config not found at: $configPath"
        return
    }

    # --- Run encryption command ---
    try {
        Write-RemoteLog "Executing: $filePath -pef $sec $loc"
        & $filePath @params 2>&1 | ForEach-Object { Write-RemoteLog $_ }
        Write-RemoteLog "Encryption complete"
    } catch {
        Write-RemoteLog "ERROR during encryption: $_"
    }

    Write-RemoteLog "===== REMOTE ENCRYPTION END ====="

} -ArgumentList $filePath, $params, $loc, $sec, $comp, @($args)
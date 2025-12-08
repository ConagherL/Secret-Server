<#
.SYNOPSIS
    Delinea RPC: Change ESXi Local Account Password via vCenter - version 2

.DESCRIPTION
    Remote Password Change (RPC) script that:
        • Connects to vCenter
        • Finds ESXi host
        • Updates local ESXi account password via vCenter
        • Logs all actions to both console + log file
        • Uses THROW so Secret Server treats failures correctly
        
ARGUMENTS: $MACHINE $USERNAME $NEWPASSWORD $VCENTER $[1]$DOMAIN $[1]$USERNAME $[1]$PASSWORD

    1. MACHINE        - ESXi Hostname or IP
    2. USERNAME       - ESXi Local Account Username
    3. NEWPASSWORD    - New Password for ESXi Local Account
    4. VCENTER        - vCenter Server Hostname or IP
    5. PRIV_DOMAIN    - vCenter Domain (optional)
    6. PRIV_USERNAME  - vCenter Username
    7. PRIV_PASSWORD  - vCenter Password
#>

# =====================================================================
# ARGUMENTS
# =====================================================================

$Machine        = $args[0]
$Username       = $args[1]
$NewPassword    = $args[2]
$VCENTER        = $args[3]
$PRIV_DOMAIN    = $args[4]
$PRIV_USERNAME  = $args[5]
$PRIV_PASSWORD  = $args[6]
$LOG_ENABLED    = 'true'
$LOG_PATH       = "C:\Logs\vcenter_${Machine}rpc_v2.log"

# Normalize logging flag
$LOG_ENABLED = [string]$LOG_ENABLED
$LOG_ENABLED = $LOG_ENABLED.Trim().ToLower()

if ($LOG_ENABLED -eq "true") {

    if (-not $LOG_PATH) {
        throw "LOG_ENABLED is TRUE but LOG_PATH is missing."
    }

    $LOG_PATH = $LOG_PATH.Trim()

    $logDir = Split-Path $LOG_PATH -Parent
    if (-not (Test-Path $logDir)) {
        New-Item -Path $logDir -ItemType Directory -Force | Out-Null
    }

    if (-not (Test-Path $LOG_PATH)) {
        New-Item -Path $LOG_PATH -ItemType File -Force | Out-Null
    }
}

# =====================================================================
# LOGGING FUNCTION
# =====================================================================

function Log {
    param([string]$msg)

    if ($LOG_ENABLED -ne "true") { return }

    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $line = "$timestamp [RPC] $msg"

    Write-Output $line
    Add-Content -Path $LOG_PATH -Value $line
}

# =====================================================================
# GLOBAL SETTINGS / PRE-CHECKS
# =====================================================================

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

Log "=== RPC START ==="
Log "Target host: $Machine | Account: $Username | vCenter: $VCENTER"

# PowerCLI module check (VMware.VimAutomation.Core)
try {
    $coreModule = Get-Module -ListAvailable -Name VMware.VimAutomation.Core
    if (-not $coreModule) {
        Log "[ERROR] VMware.VimAutomation.Core module not found."
        throw "Required module 'VMware.VimAutomation.Core' is not installed on this host."
    }

    if (-not (Get-Module -Name VMware.VimAutomation.Core -ErrorAction SilentlyContinue)) {
        Import-Module VMware.VimAutomation.Core -ErrorAction Stop
        Log "Imported VMware.VimAutomation.Core module."
    }
}
catch {
    Log "[ERROR] PowerCLI module load failed: $($_.Exception.Message)"
    $fullErr = ($_ | Out-String)
    Log "[ERROR] Full module error:`n$fullErr"
    throw "Unable to load VMware.VimAutomation.Core: $($_.Exception.Message)"
}

# =====================================================================
# BUILD CREDENTIAL
# =====================================================================

if ($PRIV_DOMAIN) {
    $vcLoginUser = "$PRIV_DOMAIN\$PRIV_USERNAME"
} else {
    $vcLoginUser = $PRIV_USERNAME
}

$securePass = ConvertTo-SecureString $PRIV_PASSWORD -AsPlainText -Force
$vcCred     = New-Object System.Management.Automation.PSCredential($vcLoginUser, $securePass)

Log "Using vCenter credential: $vcLoginUser"

# =====================================================================
# CONNECTION HANDLE
# =====================================================================

$vcConn = $null

try {
    # ================================================================
    # CONNECT TO VCENTER
    # ================================================================
    try {
        Log "Connecting to vCenter: $VCENTER ..."
        $vcConn = Connect-VIServer -Server $VCENTER -Credential $vcCred -Force -ErrorAction Stop
        Log "Connected to vCenter."
    }
    catch {
        Log "Failed to connect to vCenter."
        Log "[ERROR] vCenter connection exception: $($_.Exception.Message)"
        $fullErr = ($_ | Out-String)
        Log "[ERROR] Full vCenter error:`n$fullErr"
        throw "vCenter login failed ($VCENTER): $($_.Exception.Message)"
    }

    # ================================================================
    # LOCATE HOST IN VCENTER
    # ================================================================
    try {
        Log "Locating ESXi host '$Machine' in vCenter..."
        $vmhost = Get-VMHost -Name $Machine -Server $vcConn -ErrorAction Stop
        Log "Found ESXi host '$Machine' in vCenter."
    }
    catch {
        Log "Host not found in vCenter."
        Log "[ERROR] Host lookup exception: $($_.Exception.Message)"
        $fullErr = ($_ | Out-String)
        Log "[ERROR] Full host error:`n$fullErr"
        throw "Host '$Machine' not found in vCenter: $($_.Exception.Message)"
    }

    # ================================================================
    # UPDATE LOCAL ACCOUNT PASSWORD (VIA VCENTER)
    # ================================================================
    try {
        Log "Retrieving local ESXi account '$Username' on host '$Machine' via vCenter..."

        # Correct syntax:
        #   Get-VMHostAccount -VMHost $vmhost -Id $Username -User
        $account = Get-VMHostAccount -VMHost $vmhost -Id $Username -User -ErrorAction SilentlyContinue

        if (-not $account) {
            Log "ESXi account '$Username' not found on host '$Machine'."
            throw "Local account '$Username' does not exist on host '$Machine'."
        }

        Log "Updating password for '$Username' on host '$Machine' via vCenter..."

        # Set-VMHostAccount syntax:
        #   Set-VMHostAccount -UserAccount $account -Password $NewPassword
        Set-VMHostAccount -UserAccount $account -Password $NewPassword -Confirm:$false -ErrorAction Stop | Out-Null

        Log "Password update SUCCESSFUL for account '$Username' on host '$Machine'."
    }
    catch {
        Log "Password change failed."
        Log "[ERROR] Exception: $($_.Exception.Message)"

        if ($_.CategoryInfo) {
            Log "[ERROR] Category : $($_.CategoryInfo.Category)"
            Log "[ERROR] Target   : $($_.CategoryInfo.TargetName)"
        }

        $fullErr = ($_ | Out-String)
        Log "[ERROR] Full error record:`n$fullErr"

        throw "Password update failed on host '$Machine': $($_.Exception.Message)"
    }
}
finally {
    if ($vcConn) {
        try {
            Log "Disconnecting from vCenter..."
            Disconnect-VIServer -Server $vcConn -Confirm:$false -ErrorAction SilentlyContinue
            Log "Disconnected from vCenter."
        }
        catch {
            Log "[WARN] Failed to disconnect vCenter session cleanly: $($_.Exception.Message)"
        }
    }

    Log "=== RPC END ==="
}

exit 0
<#
.SYNOPSIS
    Delinea Heartbeat: Test ESXi root via vCenter (Lockdown temporarily disabled)
.DESCRIPTION
    Heartbeat script that:
        • Connects to vCenter
        • Locates the ESXi host
        • Disables Lockdown Mode (only if currently enabled)
        • Attempts direct login to the ESXi host using the current root password
        • Restores Lockdown Mode only if it was enabled when script started
ARGUMENTS (in order):
    0 = $MACHINE
    1 = $USERNAME
    2 = $PASSWORD
    3 = $VCENTER
    4 = $PRIV_DOMAIN
    5 = $PRIV_USERNAME
    6 = $PRIV_PASSWORD
    7 = $LOG_ENABLED
    8 = $LOG_PATH
#>

# =====================================================================
# ARGUMENTS
# =====================================================================
$Machine       = $args[0]
$Username      = $args[1]
$Password      = $args[2]
$VCENTER       = $args[3]
$PRIV_DOMAIN   = $args[4]
$PRIV_USERNAME = $args[5]
$PRIV_PASSWORD = $args[6]
$LOG_ENABLED   = 'true'
$LOG_PATH      = "C:\Logs\vcenter_${Machine}hb_v1.log"

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
    param([string]$Message)
    if ($LOG_ENABLED -ne "true") { return }
    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $line = "$timestamp [HB] $Message"
    Write-Output $line
    Add-Content -Path $LOG_PATH -Value $line
}

# =====================================================================
# PRE-CHECKS
# =====================================================================
[Net.ServicePointManager]::SecurityProtocol =
    [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
Log "=== HEARTBEAT START ==="

# =====================================================================
$esxiHost = $Machine
$esxiUser = $Username
$esxiPass = $Password

# =====================================================================
# BUILD CREDENTIALS
# =====================================================================
if ($PRIV_DOMAIN) {
    $vcLoginUser = "$PRIV_DOMAIN\$PRIV_USERNAME"
} else {
    $vcLoginUser = $PRIV_USERNAME
}
$secureVcPass = ConvertTo-SecureString $PRIV_PASSWORD -AsPlainText -Force
$vcCred = New-Object System.Management.Automation.PSCredential($vcLoginUser, $secureVcPass)
Log "Using vCenter credential: $vcLoginUser"
$secureEsxiPass = ConvertTo-SecureString $esxiPass -AsPlainText -Force
$esxiCred = New-Object System.Management.Automation.PSCredential($esxiUser, $secureEsxiPass)

# =====================================================================
# MAIN FLOW
# =====================================================================
$vcConn           = $null
$vmhostView       = $null
$heartbeatPassed  = $false
$lockdownDisabled = $false
$originalLockdown = $null

try {
    try {
        Log "Connecting to vCenter: $VCENTER ..."
        $vcConn = Connect-VIServer -Server $VCENTER -Credential $vcCred -Force -ErrorAction Stop
        Log "Connected to vCenter."
    } catch {
        Log "Failed to connect to vCenter."
        throw "vCenter login failed ($VCENTER): $($_.Exception.Message)"
    }

    try {
        Log "Locating ESXi host '$esxiHost' in vCenter..."
        $vmhost = Get-VMHost -Name $esxiHost -Server $vcConn -ErrorAction Stop
        Log "Found ESXi host '$esxiHost'."
    } catch {
        Log "Host not found in vCenter."
        throw "Host '$esxiHost' not found in vCenter."
    }

    $vmhostView = $vmhost | Get-View

    try {
        $originalLockdown = $vmhostView.Config.LockdownMode
        Log "Current LockdownMode on '$esxiHost' is '$originalLockdown'."
    } catch {
        Log "WARNING: Unable to read current LockdownMode from host view."
        $originalLockdown = $null
    }

    try {
        if ($originalLockdown -and $originalLockdown -ne "lockdownDisabled") {
            Log "Lockdown is enabled (mode: '$originalLockdown'). Disabling Lockdown Mode on '$esxiHost'..."
            $vmhostView.ExitLockdownMode()
            $lockdownDisabled = $true
            Log "Lockdown Mode disabled on '$esxiHost'."
        } else {
            Log "Lockdown is already disabled on '$esxiHost'. No change will be made."
            $lockdownDisabled = $false
        }
    } catch {
        Log "Failed to disable Lockdown Mode."
        throw "Failed to disable Lockdown Mode on host '$esxiHost': $($_.Exception.Message)"
    }

    try {
        Log "Attempting direct login to ESXi host '$esxiHost' as '$esxiUser'..."
        $hostConn = Connect-VIServer -Server $esxiHost -Credential $esxiCred -Force -ErrorAction Stop -WarningAction SilentlyContinue
        if ($hostConn -and $hostConn.IsConnected) {
            Log "Direct login succeeded on '$esxiHost'."
            $heartbeatPassed = $true
            Disconnect-VIServer -Server $hostConn -Confirm:$false -ErrorAction SilentlyContinue | Out-Null
            Log "Disconnected ESXi host session."
        } else {
            Log "Direct login did not return a valid connection object."
            throw "Direct login did not establish a connection to '$esxiHost'."
        }
    } catch {
        Log "Direct login failed."
        throw "Direct login failed on host '$esxiHost': $($_.Exception.Message)"
    } finally {
        if ($vmhostView -and $lockdownDisabled) {
            try {
                Log "Restoring Lockdown Mode on '$esxiHost' to original state ('$originalLockdown')..."
                $vmhostView.EnterLockdownMode()
                Log "Lockdown Mode restored (re-enabled) on '$esxiHost'."
            } catch {
                Log "WARNING: Failed to restore Lockdown Mode. Manual intervention required."
            }
        } else {
            Log "No Lockdown enable needed (either it was already disabled or host view unavailable)."
        }
    }
} finally {
    if ($vcConn) {
        Log "Disconnecting from vCenter..."
        Disconnect-VIServer -Server $vcConn -Confirm:$false -ErrorAction SilentlyContinue | Out-Null
        Log "Disconnected from vCenter."
    }
}

# =====================================================================
# FINAL RESULT
# =====================================================================
if (-not $heartbeatPassed) {
    Log "HEARTBEAT FAILURE."
    throw "Heartbeat test did not complete successfully for host '$esxiHost'."
}
Log "HEARTBEAT SUCCESS for host '$esxiHost'."
Log "=== HEARTBEAT END ==="
exit 0
<#
.SYNOPSIS
    Delinea RPC: Change ESXi Local Account Password via vCenter

.DESCRIPTION
    Remote Password Change (RPC) script that:
        • Connects to vCenter
        • Finds ESXi host
        • Updates local ESXi account password
        • Logs all actions to both console + log file
        • Uses THROW for SS best-practice error reporting
        
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
$LOG_PATH       = "C:\Logs\vcenter_${Machine}rpc_v1.log"

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
# PRE-CHECKS
# =====================================================================
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

Log "=== RPC START ==="

try {
    Import-Module VMware.PowerCLI -ErrorAction Stop
    Log "PowerCLI module loaded."
}
catch {
    Log "PowerCLI module missing."
    throw "VMware.PowerCLI is not installed."
}

# =====================================================================
# VCENTER CRED
# =====================================================================

if ($PRIV_DOMAIN) {
    $vcLoginUser = "$PRIV_DOMAIN\$PRIV_USERNAME"
}
else {
    $vcLoginUser = $PRIV_USERNAME
}

$secureVcPass = ConvertTo-SecureString $PRIV_PASSWORD -AsPlainText -Force
$vcCred       = New-Object System.Management.Automation.PSCredential($vcLoginUser, $secureVcPass)

Log "Using vCenter credential: $vcLoginUser"

# =====================================================================
# CONNECT TO VCENTER
# =====================================================================

$vcConn = $null

try {
    Log "Connecting to vCenter: $VCENTER ..."
    $vcConn = Connect-VIServer -Server $VCENTER -Credential $vcCred -Force -ErrorAction Stop
    Log "Connected to vCenter."
}
catch {
    Log "Failed to connect to vCenter."
    throw "vCenter login failed ($VCENTER): $($_.Exception.Message)"
}

# =====================================================================
# LOCATE HOST
# =====================================================================

try {
    Log "Locating ESXi host '$Machine'..."
    $vmhost = Get-VMHost -Name $Machine -Server $vcConn -ErrorAction Stop
    Log "Found ESXi host '$Machine'."
}
catch {
    Log "Host not found in vCenter."
    throw "Host '$Machine' not found in vCenter."
}

# =====================================================================
# UPDATE LOCAL ACCOUNT PASSWORD
# =====================================================================

try {
    Log "Retrieving local ESXi account '$Username'..."
    $account = Get-VMHostAccount -Host $vmhost -User $Username -ErrorAction SilentlyContinue

    if (-not $account) {
        Log "ESXi account not found."
        throw "Local account '$Username' does not exist on host '$Machine'."
    }

    Log "Updating password for '$Username'..."
    Set-VMHostAccount -UserAccount $account -Password $NewPassword -Confirm:$false -ErrorAction Stop | Out-Null

    Log "Password update successful on '$Machine'."
}
catch {
    Log "Password change failed."
    throw "Password update failed on host '$Machine': $($_.Exception.Message)"
}
finally {
    if ($vcConn) {
        Log "Disconnecting from vCenter..."
        Disconnect-VIServer -Server $vcConn -Confirm:$false -ErrorAction SilentlyContinue
        Log "Disconnected."
    }
}

Log "RPC SUCCESS"
Log "=== RPC END ==="

exit 0
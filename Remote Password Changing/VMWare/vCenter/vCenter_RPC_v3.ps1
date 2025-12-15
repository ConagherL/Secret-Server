<#
.SYNOPSIS
    Delinea Heartbeat: Set ESXi root password via vCenter (Lockdown temporarily disabled)
.DESCRIPTION
    Heartbeat script that:
        • Connects to vCenter
        • Locates the ESXi host
        • Disables Lockdown Mode
        • Attempts direct login to the ESXi host using the current root password
        • Re-enables Lockdown Mode
ARGUMENTS (in order):
    0 = $MACHINE
    1 = $USERNAME
    2 = $NEWPASSWORD
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
$NEWPASSWORD   = $args[2]
$VCENTER       = $args[3]
$PRIV_DOMAIN   = $args[4]
$PRIV_USERNAME = $args[5]
$PRIV_PASSWORD = $args[6]
$LOG_ENABLED   = 'true'
$LOG_PATH      = "C:\Logs\vcenter_${Machine}rpc_v1.log"

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
# BUILD CREDENTIALS
# =====================================================================
$secureVcPass = ConvertTo-SecureString $PRIV_PASSWORD -AsPlainText -Force
if ($PRIV_DOMAIN) {
    $vcLoginUser = "$PRIV_DOMAIN\$PRIV_USERNAME"
} else {
    $vcLoginUser = $PRIV_USERNAME
}

# =====================================================================
# Start log and import VimAutomation.Core
# =====================================================================
Log "=== Delinea RPC Start ==="
try {
    Import-Module VMware.VimAutomation.Core
    Log "VimAutomation.Core module loaded."
} catch {
    Log "VimAutomation.Core module missing."
    throw "VimAutomation.Core is not installed."
}

# Connect to vCenter
$vcCred = New-Object System.Management.Automation.PSCredential($vcLoginUser, $secureVcPass)
$vc = Connect-VIServer -Server $VCENTER -Credential $vcCred -Force -ErrorAction Stop
Log "Using vCenter credential: $vcLoginUser"

# Get host object from vCenter
$vmhost = Get-VMHost -Name $Machine -Server $vc

# ESXCLI context via vCenter
$esxcli = Get-EsxCli -VMHost $vmhost -V2 -Server $vc

<# Commented out of production - you may uncomment to see object return results
$accounts = $esxcli.system.account.list.Invoke()
$accounts | Where-Object { $_.id -eq $Username }
#>

# Create new password
$setArgs = $esxcli.system.account.set.CreateArgs()
$setArgs.id                   = $Username
$setArgs.password             = $NEWPASSWORD
$setArgs.passwordconfirmation = $NEWPASSWORD

# Set new password on host (with confirmation)
$result = $esxcli.system.account.set.Invoke($setArgs)
Write-Host "ESXCLI returned: $result"
Log "ESXCLI returned: $result"

# Validate result
if ($result -ne $true) {
    Write-Host "Password change did NOT return 'True'"
    Log "Password change did NOT return 'True'"
}

# Disconnect from vCenter
Disconnect-VIServer -Server $vc -Confirm:$false
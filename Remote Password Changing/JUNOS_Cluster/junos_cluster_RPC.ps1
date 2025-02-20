# Import the Posh-SSH module
Import-Module Posh-SSH

################################################################################
# JUNOS Password Changer Script - PowerShell Version
#
# This script connects to a JUNOS device via SSH using the Posh-SSH module,
# determines whether the device is on a primary or secondary node, switches
# to the primary node if needed, and changes the password for the specified user.
#
# It supports both non-interactive (parameters passed via command-line) and
# interactive mode (prompts the user for input).
#
# Usage (non-interactive):
#   .\JunosPasswordChanger.ps1 <targetHost> <username> <current_password> <new_password>
#
# Usage (interactive):
#   .\JunosPasswordChanger.ps1
#   (You will be prompted for target host, username, current password, and new password.)
################################################################################

# Handle input parameters
if ($args.Count -eq 4) {
    $targetHost = $args[0]
    $username = $args[1]
    $current_pw = $args[2]
    $new_pw = $args[3]
} else {
    $targetHost = Read-Host "Enter target host"
    $username = Read-Host "Enter username"
    $current_pw = Read-Host "Enter current password"
    $new_pw = Read-Host "Enter new password"
}

# Create a credential object for SSH authentication.
$securePass = ConvertTo-SecureString $current_pw -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ($username, $securePass)

# Establish an SSH session on the JUNOS device.
$session = New-SSHSession -ComputerName $targetHost -Credential $cred
if (-not $session) {
    Write-Error "Failed to create SSH session."
    exit 1
}

# Create an interactive shell stream.
$shellStream = New-SSHShellStream -SSHSession $session -TerminalName "xterm" -TerminalWidth 80 -TerminalHeight 24 -BufferSize 1024

# Reads data from the shell stream until the specified pattern is found or a timeout occurs.
function Wait-ForPrompt {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Pattern,
        [int]$TimeoutSec = 20
    )
    $output = ""
    $startTime = Get-Date
    while (((Get-Date) - $startTime).TotalSeconds -lt $TimeoutSec) {
        $output += $shellStream.Read()
        if ($output -match $Pattern) {
            return $output
        }
        Start-Sleep -Milliseconds 500
    }
    throw "Timeout waiting for prompt matching '$Pattern'. Output received: $output"
}

# Wait for the initial JUNOS prompt.
try {
    $initialOutput = Wait-ForPrompt -Pattern "JUNOS"
    Write-Host "Initial output received:`n$initialOutput"
} catch {
    Write-Error $_.Exception.Message
    exit 1
}

# Check if the output indicates primary or secondary node.
if ($initialOutput -match "primary:node") {
    Write-Host "Primary node detected."
} elseif ($initialOutput -match "secondary:node0") {
    Write-Host "Secondary node0 detected. Switching to node1."
    $shellStream.WriteLine("request routing-engine login node 1")
    try {
        $switchOutput = Wait-ForPrompt -Pattern "JUNOS"
        Write-Host "Output after switching:`n$switchOutput"
    } catch {
        Write-Error $_.Exception.Message
        exit 1
    }
} elseif ($initialOutput -match "secondary:node1") {
    Write-Host "Secondary node1 detected. Switching to node0."
    $shellStream.WriteLine("request routing-engine login node 0")
    try {
        $switchOutput = Wait-ForPrompt -Pattern "JUNOS"
        Write-Host "Output after switching:`n$switchOutput"
    } catch {
        Write-Error $_.Exception.Message
        exit 1
    }
} else {
    Write-Host "Unrecognized prompt. Assuming primary node."
}

# At this point, we are on the primary node.
# Enter exclusive configuration mode.
Write-Host "Entering exclusive configuration mode."
$shellStream.WriteLine("configure exclusive")
try {
    $configOutput = Wait-ForPrompt -Pattern ">"
    Write-Host "Configuration mode prompt received:`n$configOutput"
} catch {
    Write-Error $_.Exception.Message
    exit 1
}

# Issue the command to change the password.
Write-Host "Issuing password change command for user $username."
$shellStream.WriteLine("set system login user $username authentication plain-text-password")
try {
    $newPassPrompt = Wait-ForPrompt -Pattern "(?i)new.*password.*:"
    Write-Host "New password prompt detected.`n$newPassPrompt"
    $shellStream.WriteLine($new_pw)
} catch {
    Write-Error $_.Exception.Message
    exit 1
}

# Wait for the confirmation prompt to retype the password.
try {
    $retypePrompt = Wait-ForPrompt -Pattern "(?i)retype.*password.*:"
    Write-Host "Retype password prompt detected.`n$retypePrompt"
    $shellStream.WriteLine($new_pw)
} catch {
    Write-Error $_.Exception.Message
    exit 1
}

# Commit the configuration.
Write-Host "Committing configuration."
$shellStream.WriteLine("commit")
try {
    $commitOutput = Wait-ForPrompt -Pattern ">"
    Write-Host "Commit completed. Prompt received:`n$commitOutput"
} catch {
    Write-Error $_.Exception.Message
    exit 1
}

# Exit configuration mode.
Write-Host "Exiting configuration mode."
$shellStream.WriteLine("exit")
try {
    $exitOutput = Wait-ForPrompt -Pattern ">"
    Write-Host "Exited configuration mode. Prompt received:`n$exitOutput"
} catch {
    Write-Error $_.Exception.Message
    exit 1
}

# Log out of the session.
Write-Host "Logging out."
$shellStream.WriteLine("exit")
Start-Sleep -Seconds 2

# Clean up the SSH session.
Remove-SSHSession -SessionId $session.SessionId

Write-Host "Password change completed successfully."


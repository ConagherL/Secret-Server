<#  
.SYNOPSIS  
    Change the password of an LDAP user account in Red Hat Directory Server

.DESCRIPTION  

.PARAMETERS  
    $args[0] - LDAP server address (e.g., ldap.example.com)  
    $args[1] - Administrator DN (e.g., cn=Directory Manager)  
    $args[2] - Administrator password  
    $args[3] - DN of the user whose password is to be changed  
    $args[4] - The new password to set  
#>

# ========================
# Configuration Variables
# ========================

$ldapport = 636                  # Change port if necessary (636 for LDAPS, 389 for LDAP)
$useSSL = $true                  # Change to $false if not using SSL
$debug = $false                  # Change to $true to enable debug output
$logFile = "ldap_debug.log"      # Log file for detailed SSL information
$acceptAllCerts = $true          # Change to $false to enforce certificate validation

# Arguments
$ldaphost = $args[0]
$adminUser = $args[1]
$adminPassword = $args[2]
$userDN = $args[3]
$newPassword = $args[4]


if ($debug) {
    $DebugPreference = "Continue"
    $VerbosePreference = "Continue"
}

# ========================
# Helper Functions
# ========================

function Write-DebugInfo {
    param([string]$Message)
    if ($debug) {
        Write-Host "[DEBUG] $Message"
    }
}

function Write-LogInfo {
    param([string]$Message)
    if ($debug) {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        "$timestamp - $Message" | Out-File -FilePath $logFile -Append -Encoding UTF8
    }
}

Write-DebugInfo "Starting RHDS Password Change Script"
Write-DebugInfo "LDAP Host: $ldaphost"
Write-DebugInfo "LDAP Port: $ldapport"
Write-DebugInfo "Using SSL: $useSSL"
Write-DebugInfo "Admin User: $adminUser"
Write-DebugInfo "Target User DN: $userDN"

Write-LogInfo "=== LDAP Debug Session Started ==="
Write-LogInfo "LDAP Host: $ldaphost"
Write-LogInfo "LDAP Port: $ldapport"
Write-LogInfo "Using SSL: $useSSL"
Write-LogInfo "Admin User: $adminUser"
Write-LogInfo "Target User DN: $userDN"

# ========================
# Script Execution
# ========================

# Load the required assembly  
Add-Type -AssemblyName "System.DirectoryServices.Protocols"  

# Establish an LDAP connection  
Write-DebugInfo "Creating LDAP connection object"
$ldapConnection = New-Object System.DirectoryServices.Protocols.LdapConnection("$ldaphost`:$ldapport")  

Write-DebugInfo "Configuring SSL options"
$ldapConnection.SessionOptions.SecureSocketLayer = $useSSL
$ldapConnection.SessionOptions.VerifyServerCertificate = { 
    param($connection, $certificate)
    Write-LogInfo "SSL Certificate Validation"
    
    try {
        if ($certificate) {
            Write-LogInfo "Subject: $($certificate.Subject)"
            Write-LogInfo "Issuer: $($certificate.Issuer)"
            Write-LogInfo "Serial Number: $($certificate.GetSerialNumberString())"
            Write-LogInfo "Valid From: $($certificate.NotBefore)"
            Write-LogInfo "Valid To: $($certificate.NotAfter)"
            Write-LogInfo "Thumbprint: $($certificate.Thumbprint)"
            Write-LogInfo "Has Private Key: $($certificate.HasPrivateKey)"
            Write-LogInfo "Key Algorithm: $($certificate.PublicKey.Oid.FriendlyName)"
            Write-LogInfo "Signature Algorithm: $($certificate.SignatureAlgorithm.FriendlyName)"
        } else {
            Write-LogInfo "No certificate provided by server"
        }
    } catch {
        Write-LogInfo "Error capturing certificate details: $($_.Exception.Message)"
    }
    
    return $acceptAllCerts
}

$ldapConnection.AuthType = [System.DirectoryServices.Protocols.AuthType]::Basic

# Bind with admin credentials  
Write-DebugInfo "Attempting to bind with admin credentials"
try {
    $credential = New-Object System.Net.NetworkCredential($adminUser, $adminPassword)  
    $ldapConnection.Bind($credential)  
    Write-DebugInfo "Admin binding successful"
    Write-LogInfo "LDAP bind successful"
} catch {
    Write-Host "Error: Failed to bind with admin credentials"
    Write-DebugInfo "Bind error: $($_.Exception.Message)"
    Write-DebugInfo "Error type: $($_.Exception.GetType().Name)"
    
    Write-LogInfo "LDAP Bind Failed:"
    Write-LogInfo "Full Exception: $($_.Exception.ToString())"
    if ($_.Exception.InnerException) {
        Write-LogInfo "Inner Exception: $($_.Exception.InnerException.ToString())"
    }
    
    $ldapConnection.Dispose()
    exit 1
}

# Perform password change
Write-DebugInfo "Password change request"
try {  
    Write-DebugInfo "User DN: $userDN"
    $modifyPasswordRequest = New-Object System.DirectoryServices.Protocols.ModifyRequest(  
        $userDN,  
        [System.DirectoryServices.Protocols.DirectoryAttributeOperation]::Replace,  
        "userPassword",  
        $newPassword  
    )  

    Write-DebugInfo "Sending password change request"
    $response = $ldapConnection.SendRequest($modifyPasswordRequest)  
    
    Write-DebugInfo "Response received: $($response.ResultCode)"
    
    if ($response.ResultCode -eq [System.DirectoryServices.Protocols.ResultCode]::Success) {
        Write-Host "Password updated successfully for $userDN."  
        Write-DebugInfo "Operation completed successfully"
    } else {
        Write-Host "Password change failed with result code: $($response.ResultCode)"
        Write-DebugInfo "Error message: $($response.ErrorMessage)"
    }
}  
catch {  
    Write-Host "An error occurred during password change: $($_.Exception.Message)"  
    Write-DebugInfo "Password change error: $($_.Exception.Message)"
    Write-DebugInfo "Error type: $($_.Exception.GetType().Name)"
    
    Write-LogInfo "Password Change Failed:"
    Write-LogInfo "Full Exception: $($_.Exception.ToString())"
}  
finally {  
    Write-DebugInfo "Cleaning up connection"
    if ($ldapConnection) {
        $ldapConnection.Dispose()  
        Write-DebugInfo "Connection disposed successfully"
        Write-LogInfo "Connection disposed"
    }
}
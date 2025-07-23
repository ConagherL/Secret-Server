<#
.SYNOPSIS
    Change the password of an LDAP user account in Red Hat Directory Server

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

$ldapport = 636
$useSSL = $true

# Arguments
$ldaphost = $args[0]
$adminUser = $args[1]
$adminPassword = $args[2]
$userDN = $args[3]
$newPassword = $args[4]

# ========================
# Script Execution
# ========================

# Load the required assembly
try {
    Add-Type -AssemblyName "System.DirectoryServices.Protocols"
} catch {
    Write-Host "Error: Unable to load the required assembly. Ensure that .NET is installed." -ForegroundColor Red
    throw "Unable to load required assembly: System.DirectoryServices.Protocols"
}

# Create LDAP connection using LdapDirectoryIdentifier
$ldapIdentifier = New-Object System.DirectoryServices.Protocols.LdapDirectoryIdentifier($ldaphost, $ldapport, $true, $false)
$ldapConnection = New-Object System.DirectoryServices.Protocols.LdapConnection($ldapIdentifier)
$ldapConnection.SessionOptions.SecureSocketLayer = $useSSL
$ldapConnection.AuthType = [System.DirectoryServices.Protocols.AuthType]::Basic

# Bind with admin credentials
try {
    $credential = New-Object System.Net.NetworkCredential($adminUser, $adminPassword)
    $ldapConnection.Bind($credential)
} catch {
    Write-Host "Error: Failed to bind with admin credentials: $($_.Exception.Message)" -ForegroundColor Red
    $ldapConnection.Dispose()
    throw "Failed to bind with admin credentials: $($_.Exception.Message)"
}

# Perform password change
try {
    $modifyPasswordRequest = New-Object System.DirectoryServices.Protocols.ModifyRequest(
        $userDN,
        [System.DirectoryServices.Protocols.DirectoryAttributeOperation]::Replace,
        "userPassword",
        $newPassword
    )

    $response = $ldapConnection.SendRequest($modifyPasswordRequest)

    if ($response.ResultCode -eq [System.DirectoryServices.Protocols.ResultCode]::Success) {
        Write-Host "Password updated successfully for $userDN." -ForegroundColor Green
    } else {
        Write-Host "Password change failed with result code: $($response.ResultCode)" -ForegroundColor Red
        throw "Password change failed with result code: $($response.ResultCode)"
    }
}
catch {
    Write-Host "An error occurred during password change: $($_.Exception.Message)" -ForegroundColor Red
    throw "Password change failed: $($_.Exception.Message)"
}
finally {
    if ($ldapConnection) {
        $ldapConnection.Dispose()
    }
}
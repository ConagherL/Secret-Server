<#
.SYNOPSIS
    Heartbeat validation script for Red Hat Directory Server.

.DESCRIPTION
    This script attempts to authenticate a user against the Red Hat Directory Server
    to ensure the credentials are valid.

.USAGE
    ./RHDS_Heartbeat_Validation.ps1 "ldap.example.com" "uid=user1,ou=people,dc=example,dc=com" "UserPassword123!"

.PARAMETERS
    $args[0] - LDAP server address (e.g., ldap.example.com)
    $args[1] - Distinguished Name (DN) of the user for authentication
    $args[2] - Password for the user

.NOTES
    Modify the `$ldapport` and `$useSSL` variables at the top if needed.
#>

# ========================
# Configuration Variables
# ========================

$ldapport = 636                  # Change port if necessary (636 for LDAPS, 389 for LDAP)
$useSSL = $true                  # Change to $false if not using SSL

# Assigning arguments
$ldaphost = $args[0]
$userDN = $args[1]
$userPassword = $args[2]

# ========================
# Script Execution
# ========================

# Load the required assembly
try {
    Add-Type -AssemblyName "System.DirectoryServices.Protocols"
} catch {
    Write-Host "Error: Unable to load the required assembly. Ensure that .NET is installed." -ForegroundColor Red
    exit 1
}

# ========================
# LDAP Connection
# ========================

# Changes to SSL portion to match RPC values for SSL binding
$identifier = New-Object System.DirectoryServices.Protocols.LdapDirectoryIdentifier($ldaphost, $ldapport, $true, $false)
$ldapConnection = New-Object System.DirectoryServices.Protocols.LdapConnection($identifier)

$ldapConnection.SessionOptions.SecureSocketLayer = $useSSL
###$ldapConnection.SessionOptions.VerifyServerCertificate = { $true }
$ldapConnection.AuthType = [System.DirectoryServices.Protocols.AuthType]::Basic

# Attempt authentication
try {
    $credential = New-Object System.Net.NetworkCredential($userDN, $userPassword)
    $ldapConnection.Bind($credential)
    Write-Host "✅ Heartbeat successful: Authentication successful for user $userDN." -ForegroundColor Green
} catch {
    Write-Host "❌ Heartbeat failed: Authentication error - $($_.Exception.Message)" -ForegroundColor Red
} finally {
    # Dispose of the LDAP connection
    $ldapConnection.Dispose()
}

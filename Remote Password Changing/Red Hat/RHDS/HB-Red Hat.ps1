<#

.SYNOPSIS
    Heartbeat validation script for Red Hat Directory Server.

.DESCRIPTION
    This script attempts to authenticate a user against the Red Hat Directory Server
    to ensure the server is responsive and the credentials are valid.

.PARAMETERS
    $ldaphost      - LDAP server address (e.g., ldap.example.com).
    $ldapport      - LDAP server port (e.g., 636 for LDAPS).
    $userDN        - Distinguished Name (DN) of the user for authentication.
    $userPassword  - Password for the user.

.NOTES
    Usage: ./RHDS_Heartbeat_Validation.ps1 -ldaphost "ldap.example.com" -ldapport 636 -userDN "uid=user1,ou=people,dc=example,dc=com" -userPassword "UserPassword123!"
#>

param (
    [string]$ldaphost,
    [int]$ldapport,
    [string]$userDN,
    [string]$userPassword
)

# Load the required assembly
try {
    Add-Type -AssemblyName "System.DirectoryServices.Protocols"
} catch {
    Write-Host "Error: Unable to load the required assembly. Ensure that .NET is installed." -ForegroundColor Red
    exit 1
}

# Create LDAP connection
$ldapConnection = New-Object System.DirectoryServices.Protocols.LdapConnection("$ldaphost`:$ldapport")
$ldapConnection.SessionOptions.SecureSocketLayer = $true  # Use SSL/TLS for secure connection
$ldapConnection.AuthType = [System.DirectoryServices.Protocols.AuthType]::Basic

# Attempt authentication
try {
    $credential = New-Object System.Net.NetworkCredential($userDN, $userPassword)
    $ldapConnection.Bind($credential)
    Write-Host "Heartbeat successful: Authentication successful for user $userDN." -ForegroundColor Green
} catch {
    Write-Host "Heartbeat failed: Authentication error - $_" -ForegroundColor Red
} finally {
    # Dispose of the LDAP connection
    $ldapConnection.Dispose()
}

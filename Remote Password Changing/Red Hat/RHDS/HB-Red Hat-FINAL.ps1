<#
.SYNOPSIS
    Heartbeat validation script for Red Hat Directory Server.

.PARAMETERS
    $args[0] - LDAP server address (e.g., ldap.example.com)
    $args[1] - Administrator Distinguished Name (DN) for binding (e.g., cn=Directory Manager)
    $args[2] - Administrator password
    $args[3] - Distinguished Name (DN) of the user for authentication
    $args[4] - Password for the user
#>

# ========================
# Configuration Variables
# ========================

$ldapport = 636  # Change port if necessary (636 for LDAPS, 389 for LDAP)
$useSSL = $true  # Change to $false if not using SSL

# Assigning arguments
$ldaphost = $args[0]
$adminDN = $args[1]
$adminPassword = $args[2]
$userDN = $args[3]
$userPassword = $args[4]

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

# Create admin LDAP connection
$ldapIdentifier = New-Object System.DirectoryServices.Protocols.LdapDirectoryIdentifier($ldaphost, $ldapport, $true, $false)
$adminConnection = New-Object System.DirectoryServices.Protocols.LdapConnection($ldapIdentifier)
$adminConnection.SessionOptions.SecureSocketLayer = $useSSL
$adminConnection.AuthType = [System.DirectoryServices.Protocols.AuthType]::Basic

# Bind with admin credentials
$adminCredential = New-Object System.Net.NetworkCredential($adminDN, $adminPassword)
try {
    $adminConnection.Bind($adminCredential)
} catch {
    Write-Host "Error: Failed to bind with admin credentials. $_" -ForegroundColor Red
    $adminConnection.Dispose()
    throw "Failed to bind with admin credentials: $_"
}

# Search for the user account
$searchRequest = New-Object System.DirectoryServices.Protocols.SearchRequest(
    $userDN,
    "(objectClass=*)",
    [System.DirectoryServices.Protocols.SearchScope]::Base,
    "distinguishedName"
)

try {
    $searchResponse = $adminConnection.SendRequest($searchRequest)
    if ($searchResponse.Entries.Count -eq 0) {
        Write-Host "Error: Account not found for DN $userDN." -ForegroundColor Red
        throw "Account not found for DN $userDN"
    } else {
        Write-Host "Account found for DN $userDN." -ForegroundColor Green
    }
} catch {
    Write-Host "Error: Failed to search for user account. $_" -ForegroundColor Red
    throw "Failed to search for user account: $_"
} finally {
    $adminConnection.Dispose()
}

# Create user LDAP connection
$ldapIdentifier = New-Object System.DirectoryServices.Protocols.LdapDirectoryIdentifier($ldaphost, $ldapport, $true, $false)
$userConnection = New-Object System.DirectoryServices.Protocols.LdapConnection($ldapIdentifier)
$userConnection.SessionOptions.SecureSocketLayer = $useSSL
$userConnection.AuthType = [System.DirectoryServices.Protocols.AuthType]::Basic

# Attempt authentication with user creds
$userCredential = New-Object System.Net.NetworkCredential($userDN, $userPassword)
try {
    $userConnection.Bind($userCredential)
    Write-Host "Heartbeat successful: Authentication successful for user $userDN." -ForegroundColor Green
} catch {
    Write-Host "Heartbeat failed: Authentication error for user $userDN. $_" -ForegroundColor Red
    throw "Heartbeat failed: Authentication error for user $userDN.  $_"
} finally {
    $userConnection.Dispose()
}
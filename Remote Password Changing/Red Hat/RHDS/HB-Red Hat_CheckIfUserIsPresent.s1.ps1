<#
.SYNOPSIS
    Heartbeat validation script for Red Hat Directory Server.

.DESCRIPTION
    This script connects to the RHDS LDAP server, checks if a specified user account exists,
    and if it does, attempts to authenticate the user to ensure the server is responsive
    and the credentials are valid.

.USAGE
    Run the script with the required arguments:

    ./HB-RedHat.ps1 "<LDAP Host>" "<Admin DN>" "<Admin Password>" "<User DN>" "<User Password>"
 

.PARAMETERS
    $args[0] - LDAP server address (e.g., ldap.example.com)
    $args[1] - Administrator Distinguished Name (DN) for binding (e.g., cn=Directory Manager)
    $args[2] - Administrator password
    $args[3] - Distinguished Name (DN) of the user for authentication
    $args[4] - Password for the user

.NOTES
    Modify the `$ldapport` and `$useSSL` variables at the top if needed.
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
    exit 1
}

# Create an LDAP connection for admin
$adminConnection = New-Object System.DirectoryServices.Protocols.LdapConnection("$ldaphost`:$ldapport")
$adminConnection.SessionOptions.SecureSocketLayer = $useSSL
$adminConnection.AuthType = [System.DirectoryServices.Protocols.AuthType]::Basic

# Bind with admin credentials
$adminCredential = New-Object System.Net.NetworkCredential($adminDN, $adminPassword)
try {
    $adminConnection.Bind($adminCredential)
} catch {
    Write-Host "Error: Failed to bind with admin credentials. $_" -ForegroundColor Red
    exit 1
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
        exit 1
    } else {
        Write-Host "Account found for DN $userDN." -ForegroundColor Green
    }
} catch {
    Write-Host "Error: Failed to search for user account. $_" -ForegroundColor Red
    exit 1
} finally {
    # Dispose of the admin LDAP connection
    $adminConnection.Dispose()
}

# Create an LDAP connection for user authentication
$userConnection = New-Object System.DirectoryServices.Protocols.LdapConnection("$ldaphost`:$ldapport")
$userConnection.SessionOptions.SecureSocketLayer = $useSSL
$userConnection.AuthType = [System.DirectoryServices.Protocols.AuthType]::Basic

# Attempt authentication with user credentials
$userCredential = New-Object System.Net.NetworkCredential($userDN, $userPassword)
try {
    $userConnection.Bind($userCredential)
    Write-Host "Heartbeat successful: Authentication successful for user $userDN." -ForegroundColor Green
} catch {
    Write-Host "Heartbeat failed: Authentication error for user $userDN. $_" -ForegroundColor Red
} finally {
    # Dispose of the user LDAP connection
    $userConnection.Dispose()
}

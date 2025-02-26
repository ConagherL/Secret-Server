<#  
.SYNOPSIS  
    Heartbeat validation script for Red Hat Directory Server.  

.DESCRIPTION  
    This script attempts to authenticate a user against the Red Hat Directory Server  
    to ensure the credentials are valid.  

.USAGE  
    Run the script with the required arguments:  

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

# Ensure all required arguments are provided
if ($args.Count -lt 3) {
    Write-Host "Usage: ./RHDS_Heartbeat_Validation.ps1 <LDAP Host> <User DN> <Password>" -ForegroundColor Yellow
    exit 1
}

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

# Create an LDAP connection  
$ldapConnection = New-Object System.DirectoryServices.Protocols.LdapConnection("$ldaphost`:$ldapport")  
$ldapConnection.SessionOptions.SecureSocketLayer = $useSSL
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

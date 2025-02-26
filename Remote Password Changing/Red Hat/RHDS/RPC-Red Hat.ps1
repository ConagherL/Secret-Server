<#  
.SYNOPSIS  
    Script to change the password of an LDAP user account in Red Hat Directory Server without prompting for a password change on next login.  

.DESCRIPTION  
    Connects to the RHDS LDAP server over a secure connection, updates a user's password. Red Hat by default wants to enforce the  

.USAGE  
    Run the script with the required arguments:  
    ```  
    ./ChangeRHDSUserPassword.ps1 "ldap.example.com" "cn=Directory Manager" "admin123" "uid=user1,ou=people,dc=example,dc=com" "NewPassword123!"
    ```  

.PARAMETERS  
    $args[0] - LDAP server address (e.g., ldap.example.com)  
    $args[1] - Administrator DN (e.g., cn=Directory Manager)  
    $args[2] - Administrator password  
    $args[3] - DN of the user whose password is to be changed  
    $args[4] - The new password to set  

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
    exit 1  
}  

# Establish an LDAP connection  
$ldapConnection = New-Object System.DirectoryServices.Protocols.LdapConnection("$ldaphost`:$ldapport")  
$ldapConnection.SessionOptions.SecureSocketLayer = $useSSL
$ldapConnection.AuthType = [System.DirectoryServices.Protocols.AuthType]::Basic  

# Bind with admin credentials  
$credential = New-Object System.Net.NetworkCredential($adminUser, $adminPassword)  
$ldapConnection.Bind($credential)  

try {  
    # Set up the password change request  
    $modifyPasswordRequest = New-Object System.DirectoryServices.Protocols.ModifyRequest(  
        $userDN,  
        [System.DirectoryServices.Protocols.DirectoryAttributeOperation]::Replace,  
        "userPassword",  
        $newPassword  
    )  

    # Send the password change request  
    $ldapConnection.SendRequest($modifyPasswordRequest)  
    Write-Host "Password updated successfully for $userDN." -ForegroundColor Green  
}  
catch {  
    Write-Host "An error occurred: $_" -ForegroundColor Red  
}  
finally {  
    # Close the connection  
    $ldapConnection.Dispose()  
}

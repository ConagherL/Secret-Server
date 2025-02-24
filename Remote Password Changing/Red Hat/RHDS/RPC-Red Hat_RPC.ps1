<#

.SYNOPSIS
    Script to change the password of an LDAP user account in Red Hat Directory Server without prompting for a password change on next login.

.DESCRIPTION
    Connects to the RHDS LDAP server over a secure connection, updates a user's password, and ensures the user is not prompted to change their password upon next login.

.PARAMETERS
    $ldaphost      - LDAP server address (e.g., ldap.example.com).
    $ldapport      - LDAP server port (e.g., 636 for LDAPS).
    $adminUser     - Administrator DN (e.g., cn=Directory Manager).
    $adminPassword - Administrator password.
    $userDN        - DN of the user whose password is to be changed.
    $newPassword   - The new password to set.

.NOTES
    Usage: .\ChangeRHDSUserPassword.ps1 -ldaphost "ldap.example.com" -ldapport 636 -adminUser "cn=Directory Manager" -adminPassword "admin123" -userDN "uid=user1,ou=people,dc=example,dc=com" -newPassword "NewPassword123!"
#>

# Input Parameters
param (
    [string]$ldaphost,
    [int]$ldapport,
    [string]$adminUser,
    [string]$adminPassword,
    [string]$userDN,
    [string]$newPassword
)

# Load the required assembly
Add-Type -AssemblyName "System.DirectoryServices.Protocols"

# Establish LDAP connection
$ldapConnection = New-Object System.DirectoryServices.Protocols.LdapConnection("$ldaphost`:$ldapport")
$ldapConnection.SessionOptions.SecureSocketLayer = $true  # Use SSL/TLS for secure connection
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
    Write-Host "Password updated successfully for $userDN."

    # Ensure the user is not prompted to change password on next login
    $preventPwdChangePromptRequest = New-Object System.DirectoryServices.Protocols.ModifyRequest(
        $userDN,
        [System.DirectoryServices.Protocols.DirectoryAttributeOperation]::Replace,
        "pwdReset",
        "FALSE"
    )

    # Send the request to set pwdReset
    $ldapConnection.SendRequest($preventPwdChangePromptRequest)
    Write-Host "User will NOT be prompted to change password at next login."
}
catch {
    Write-Host "An error occurred: $_"
}
finally {
    # Close the connection
    $ldapConnection.Dispose()
}

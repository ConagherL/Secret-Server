# Function to safely import the ActiveDirectory module
function Import-ActiveDirectoryModule {
    try {
        Import-Module ActiveDirectory -ErrorAction Stop
        Write-Host "Active Directory module imported successfully." -ForegroundColor Green
    } catch {
        Write-Host "Error: Active Directory module is not installed or available. Please ensure the module is installed." -ForegroundColor Red
        exit
    }
}

# Call the function to import the module
Import-ActiveDirectoryModule

# Function to get AdminSDHolder path dynamically
function Get-AdminSDHolderPath {
    # Get the root domain partition dynamically
    $rootDomain = (Get-ADDomain).DistinguishedName

    # Search in the System container of the root domain
    $adminSDHolder = Get-ADObject -LDAPFilter "(CN=AdminSDHolder)" -SearchBase "CN=System,$rootDomain"
    
    # Return the distinguished name
    if ($adminSDHolder) {
        return $adminSDHolder.DistinguishedName
    } else {
        Write-Host "AdminSDHolder object not found. Please ensure you are connected to the correct domain." -ForegroundColor Red
        exit
    }
}

# Prompt user to query AdminSDHolder path dynamically or provide manually
$useDynamicPath = Read-Host "Do you want to query the AdminSDHolder path dynamically? (Y/N)"
if ($useDynamicPath -eq 'Y') {
    $adminSDHolderPath = Get-AdminSDHolderPath
    Write-Host "AdminSDHolder path dynamically retrieved: $adminSDHolderPath" -ForegroundColor Green
} else {
    # User provides the path manually
    $adminSDHolderPath = Read-Host "Enter the full LDAP path to the AdminSDHolder (e.g., CN=AdminSDHolder,CN=System,DC=BLT,DC=LOCAL)"
}

# Prompt user for the account name
$accountName = Read-Host "Enter the NETBIOS name and account name (e.g., NETBIOS\AccountName)"
Write-Host "Processing permissions for account: $accountName" -ForegroundColor Cyan

# Set Permissions
$acl = Get-Acl "AD:\$adminSDHolderPath"

# Grant Read Property (RP) permission
$rule1 = New-Object System.DirectoryServices.ActiveDirectoryAccessRule (
    [System.Security.Principal.NTAccount] "$accountName",
    "ReadProperty",
    "Allow"
)
$acl.AddAccessRule($rule1)
Write-Host "Added Read Property (RP) permission for $accountName" -ForegroundColor Yellow

# Grant Change Password permission
$rule2 = New-Object System.DirectoryServices.ActiveDirectoryAccessRule (
    [System.Security.Principal.NTAccount] "$accountName",
    "ExtendedRight",
    "Allow",
    [Guid]("{00299570-246d-11d0-a768-00aa006e0529}") # GUID for Change Password
)
$acl.AddAccessRule($rule2)
Write-Host "Added Change Password permission for $accountName" -ForegroundColor Yellow

# Grant Reset Password permission
$rule3 = New-Object System.DirectoryServices.ActiveDirectoryAccessRule (
    [System.Security.Principal.NTAccount] "$accountName",
    "ExtendedRight",
    "Allow",
    [Guid]("{00299570-246d-11d0-a768-00aa006e0529}") # Same GUID for Reset Password
)
$acl.AddAccessRule($rule3)
Write-Host "Added Reset Password permission for $accountName" -ForegroundColor Yellow

# Grant Write permission for lockoutTime
$rule4 = New-Object System.DirectoryServices.ActiveDirectoryAccessRule (
    [System.Security.Principal.NTAccount] "$accountName",
    "WriteProperty",
    "Allow",
    [Guid]("{28630EB3-41D5-11D1-A9C1-0000F80367C1}") # GUID for lockoutTime
)
$acl.AddAccessRule($rule4)
Write-Host "Added Write permission for lockoutTime for $accountName" -ForegroundColor Yellow

# Grant Write permission for pwdLastSet
$rule5 = New-Object System.DirectoryServices.ActiveDirectoryAccessRule (
    [System.Security.Principal.NTAccount] "$accountName",
    "WriteProperty",
    "Allow",
    [Guid]("{28630EC0-41D5-11D1-A9C1-0000F80367C1}") # GUID for pwdLastSet
)
$acl.AddAccessRule($rule5)
Write-Host "Added Write permission for pwdLastSet for $accountName" -ForegroundColor Yellow

# Grant Write permission for userAccountControl
$rule6 = New-Object System.DirectoryServices.ActiveDirectoryAccessRule (
    [System.Security.Principal.NTAccount] "$accountName",
    "WriteProperty",
    "Allow",
    [Guid]("{28630EC1-41D5-11D1-A9C1-0000F80367C1}") # GUID for userAccountControl
)
$acl.AddAccessRule($rule6)
Write-Host "Added Write permission for userAccountControl for $accountName" -ForegroundColor Yellow

# Apply the ACL back to the AdminSDHolder object
Set-Acl -Path "AD:\$adminSDHolderPath" -AclObject $acl

Write-Host "Permissions have been updated successfully for $accountName." -ForegroundColor Green

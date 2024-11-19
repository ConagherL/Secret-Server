$params = $args
$username = $params[0]
$password = $params[1]

$privCred = [PSCredential]::new($username,(ConvertTo-SecureString $password -AsPlainText -Force))
$properties = @{L = "Domain";E = { ($_.PrimaryGroup -split ",")[-2].Replace("DC=","") + "." + ($_.PrimaryGroup -split ",")[-1].Replace("DC=","") } },
@{L = "Username";E = { $_.samAccountName } },
'SamAccountName',
'DisplayName',
'extensionAttribute14',
@{L = "extensionAttribute01";E = { $_.mail } },
'UserPrincipalName',
'sn',
@{L = "Active";E = { $_.Enabled } },
'PasswordExpired',
@{L = "extensionAttribute02";E = { $_.Manager } },
'UserAccountControl',
@{L = "PwdLastSet";E = { [datetime]::FromFileTime($_.PwdLastSet) } },
@{L = "PwdAge";E = { ((Get-Date) - [datetime]::FromFileTime($_.pwdLastSet)).Days } },
@{L = "LastLogonTimestamp";E = { [datetime]::FromFileTime($_.lastLogonTimestamp) } },
'WhenCreated',
'DistinguishedName'

Import-Module ActiveDirectory
$params = @{
    Filter     = '*'
    Credential = $privCred
    Properties = '*'
}
Get-ADUser @params | Select-Object $properties
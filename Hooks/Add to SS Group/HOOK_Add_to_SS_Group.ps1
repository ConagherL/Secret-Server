<#
    Expected arguments to Add to Secret Server Group:
        $[1]$URL $[1]$USERNAME $[1]$PASSWORD "SS_GROUP_NAME"
    Expected arguments to Remove from Secret Server Group:
        $[1]$URL $[1]$USERNAME $[1]$PASSWORD "SS_GROUP_NAME"
#>

$SecretServerHost = $args[0]
$Username = $args[1]
$Password = ConvertTo-SecureString $args[2] -AsPlainText -Force
$cred = [pscredential]::new($Username,$Password)
$action = $args[3]

if (Get-Module Thycotic.SecretServer -List) {
    Import-Module Thycotic.SecretServer -Force
} else {
    throw 'Please install Thycotic.SecretServer module: Install-Module Thycotic.SecretServer -Scope AllUsers'
}

try {
    $session = New-TssSession -SecretServer $SecretServerHost -Credential $cred -ErrorAction Stop
} catch {
    throw "Issue connecting to $SecretServerHost with $Username : $($_)"
}

$uri = "$($session.ApiUrl)/configuration/unlimited-admin"
switch ($action) {
    'enable' {
        try {
            Add-TssGroupMember -TssSession $session -Id 8 -UserId 54 -ErrorAction Stop
        } catch {
            throw "Issue adding to the group: $($_)"
        }
    }
    'disable' {
        try {
            Remove-TssGroupMember -TssSession $session -Id 8 -UserId 54 -ErrorAction Stop
        } catch {
            throw "Issue removing from the group: $($_)"
        }
    }
}
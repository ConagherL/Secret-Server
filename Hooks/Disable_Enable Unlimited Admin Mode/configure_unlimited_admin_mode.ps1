<#
    Expected arguments to Enable Unlimited:
        $[1]$URL $[1]$USERNAME $[1]$PASSWORD "enable"

    Expected arguments to Disable Unlimited:
        $[1]$URL $[1]$USERNAME $[1]$PASSWORD "disable"

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
            Enable-TssUnlimitedAdmin -TssSession $session -Note 'Turning UL on' -ErrorAction Stop
        } catch {
            throw "Issue enabling Unlimited Admin Mode: $($_)"
        }
    }
    'disable' {
        try {
            Disable-TssUnlimitedAdmin -TssSession $session -Note 'Turning UL off' -ErrorAction Stop
        } catch {
            throw "Issue enabling Unlimited Admin Mode: $($_)"
        }
    }
}

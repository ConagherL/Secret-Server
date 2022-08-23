<#
    .EXAMPLE
    $MACHINE $USERNAME $NEWPASSWORD "4641" $[1]$DOMAIN $[1]$USERNAME $[1]$PASSWORD

    Arguments supporting use of proxied port for PowerShell remoting

    .EXAMPLE
    $MACHINE $USERNAME $NEWPASSWORD "0" $[1]$DOMAIN $[1]$USERNAME $[1]$PASSWORD

    Arguments that will not use proxied port for PowerShell remoting
#>
$machine = $args[0]
$username = $args[1]
$password = ConvertTo-SecureString -String $args[2] -AsPlainText -Force
$port = $args[3]
$privDomain = $args[4]
$privUsername = $args[5]
$privPassword = ConvertTo-SecureString -String $args[6] -AsPlainText -Force
$privAccount = $privDomain, $privUsername -join '\'

$privCred = [pscredential]::new($privAccount,$privPassword)

$sessionParams = @{
    ComputerName = $machine
    Credential = $privCred
}
if ($port -gt 0) {
    $sessionOption = New-PSSession -ProxyAccessType NoProxyServer
    $authOption = 'CredSSP'

    $sessionParams.Add('Port',$port)
    $sessionParams.Add('SessionOption',$sessionOption)
    $sessionParams.Add('Authentication',$authOption)
}

try {
    $session = New-PSSession @sessionParams
} catch {
    throw "Unable to remotely connect to [$machine]: $($_)"
}

if ($session) {
    $ScriptBlock = {
        $user = $using:username
        try {
            $localUser = Get-LocalUser -Name $user -ErrorAction Stop
        } catch {
            throw "Issue getting User [$user]: $($_)"
        }

        try {
            $localUser | Set-LocalUser -Password $using:password -ErrorAction Stop
        } catch {
            throw "Issue changing password for User [$user]: $($_)"
        }
    }
    Invoke-Command -Session $session -Command $ScriptBlock
} else {
    throw "PSSession object not found"
}
# clear session out, not worried about errors
Get-PSSession -ErrorAction SilentlyContinue | Remove-PSSession -ErrorAction SilentlyContinue
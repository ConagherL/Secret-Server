<#
    .SYNOPSIS
    This script for HB can be used when the Secret account is not set in policy "Deny access to this computer from the network". If that policy is enforced this HB script will not function.
    .EXAMPLE
    $MACHINE $USERNAME $PASSWORD "4614" $[1]$DOMAIN $[1]$USERNAME $[1]$PASSWORD

    Arguments supporting use of proxied port for PowerShell remoting

    .EXAMPLE
    $MACHINE $USERNAME $PASSWORD "0" $[1]$DOMAIN $[1]$USERNAME $[1]$PASSWORD

    Arguments that will not use proxied port for PowerShell remoting
#>
$machine = $args[0]
$username = $args[1]
$password = $args[2]
$port = $args[3]
$privDomain = $args[4]
$privUsername = $args[5]
$privPassword = ConvertTo-SecureString -String $args[6] -AsPlainText -Force
$privAccount = $privDomain, $privUsername -join '\'

$privCred = [pscredential]::new($privAccount,$privPassword)

$sessionParams = @{
    ComputerName = $machine
    Credential   = $privCred
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
        $passwd = $using:password
        Add-Type -AssemblyName System.DirectoryServices.AccountManagement
        $testAcct = [System.DirectoryServices.AccountManagement.PrincipalContext]::new('machine',$env:COMPUTERNAME)
        $result = $testAcct.ValidateCredentials($user,$passwd)

        if (-not $result) {
            throw "Password validation for user [$user] failed"
        }
    }
    Invoke-Command -Session $session -Command $ScriptBlock
} else {
    throw "PSSession object not found"
}
# clear session out, not worried about errors
Get-PSSession -ErrorAction SilentlyContinue | Remove-PSSession -ErrorAction SilentlyContinue
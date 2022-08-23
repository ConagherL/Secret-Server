# Expected arguments: $MACHINE $PASSWORD $[1]$DOMAIN $[1]$USERNAME $[1]$PASSWORD
$server = $args[0]
$password = $args[1]
$privAccount = $args[2], $args[3] -join '\'
$privPassword = ConvertTo-SecureString -String $args[4] -AsPlainText -Force
$privCred = [pscredential]::new($privAccount,$privPassword)

$tsmPath = 'C:\Program Files\Tableau\Tableau Server\<version>\tsm.exe'

$scriptBlock = [scriptblock]{
    & "$using:tsmPath configuration set -k service.runas.password -v `"$($using:password)`""
    & "$using:tsmPath pending-changes apply"
}

$invokeParams = @{
    ComputerName = $server
    Credential   = $privCred
    ScriptBlock  = $scriptBlock
}
Invoke-Command @invokeParams
<#
    Input Arguments expected: $URL $USERNAME $PASSWORD
#>
$params = $args
$SecretServer = $params[0]
$SecretUser = $params[1]
$SecretUserPwd = ConvertTo-SecureString -String $params[2] -AsPlainText -Force

$credUser = [pscredential]::new($SecretUser,$SecretUserPwd)

if (Get-Module Thycotic.SecretServer -ListAvailable) {
    Import-Module Thycotic.SecretServer
} else {
    throw "Thycotic.SecretServer module not found, please install or update script to include explicit path to the PSD1 file"
}

try {
    $session = New-TssSession -SecretServer $SecretServer -Credential $credUser
    $session.SessionExpire() >$null
} catch {
    throw $_
}
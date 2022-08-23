$params = $args
$computerName = $params[0]
$filter = $params[1]
$domain = $params[2]
$username = $params[3]
$password = $params[4]

$scriptBlock = {
    Import-Module WebAdministration
    $username = ($using:domain + "\" + $using:username)
    try {
        Set-WebConfigurationProperty -Filter $using:filter -Name "userName" -Value $using:username
        Set-WebConfigurationProperty -Filter $using:filter -Name "password" -Value $using:password
    } catch [Exception] {
        throw $_.Exception.Message
    }
}
Invoke-Command -ComputerName $computerName -ScriptBlock $scriptBlock
$params = $args
$privUser = $params[0]
$privPwd = (ConvertTo-SecureString -String $params[1] -AsPlainText -Force)
$username = $params[2]
$newPassword = (ConvertTo-SecureString -String $params[3] -AsPlainText -Force)
$RepoInstance = $params[4]
$RepoName = $params[5]
$TargetInstance = $params[6]

$privCred = [PSCredential]::new("$privUser",$privPwd)
$sqlCred = [PSCredential]::new($username,$newPassword)

try {
    Add-PSSnapin sqldmsnapin
} catch {
    throw "Issue loading Idera snapin: $($_.Exception.Message)"
}

if (-not (Get-PSProvider -PSProvider SQLdm)) {
    throw "Idera SQLdm Snapin not found"
} else {
    New-SQLdmDrive -Name 'dm' -RepositoryInstance $RepoInstance -RepositoryName $RepoName -Credential $privCred
}

Set-SQLdmMonitoredInstance -Path "dm:\Instances\$TargetInstance\" -Credential $sqlcred
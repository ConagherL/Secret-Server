$cred = Get-Credential
$URL = https://blt.secretservercloud.com
$session = New-TssSession -SecretServer $URL -Credential $Cred

$cred = Get-Credential
$URL = 'https://XXXXXXX.secretservercloud.com'
$session = New-TssSession -SecretServer $URL -Credential $Cred

Search-TssSecret -TssSession $session -FolderId 2394| Stop-TssSecretChangePassword -TssSession $session -Id 15143
$cred = Get-Credential
$tenant = "https://yourssurl.com"
$session = New-TssSession -SecretServer $tenant -Credential $cred
$value = "PICK VALUE"


$secrets = Get-TssSecretField -TssSession $session -Id 5678

foreach ($secret in $secrets) {

    $name = $secret.Name.Split("\")[0]
    $id = $secret.secretid



### Update secret name to the name of the exsiting secret minus anything after the \
Set-TssSecret -TssSession $session -id $id -Secretname "$name\$value"
### Update the username on the secret to 'PICK VALUE' from arguments
Set-TssSecretField -TssSession $session -id $id -Slug username -Value $value
}

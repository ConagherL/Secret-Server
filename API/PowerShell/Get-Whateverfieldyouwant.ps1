$cred = Get-Credential
$URL = 'https://XXXsecretservercloud.com'
$session = New-TssSession -SecretServer $URL -Credential $Cred


Get-TssSecretTemplate -Id 6010 -TssSession $session -Verbose | Select-Object Fields
6010


$secrets = Search-TssSecret -TssSession $session -FolderId 7554 -IncludeSubFolders
$secrets.Foreach({
    [pscustomobject]@{
        SecretName = $_.SecretName
        SecretId = $_.SecretId
        Password_Expiration = Get-TssSecretField -TssSession $session -Id $_.SecretId -Slug password-state-expiration
    }
}) | Out-File C:\temp\testout.txt
Invoke-Item C:\temp\testout.txt

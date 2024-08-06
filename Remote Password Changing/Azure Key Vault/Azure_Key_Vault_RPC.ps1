#Args $[1]$clientid $[1]$secret $[1]$tenantid $vault $secret $newpassword
$clientid = $args[0]
$clientSecret = $args[1]
$tenantID = $args[2]
$AKVaultName = $args[3]
$AKSecretName = $args[4]
$NewPassword = $args[5]

$ReqTokenBody = @{
Grant_Type = "client_credentials"
Scope = "https://vault.azure.net/.default"
client_Id = $clientID
Client_Secret = $clientSecret
}


$TokenResponse = Invoke-RestMethod -Uri "https://login.microsoftonline.com/$TenantID/oauth2/v2.0/token" -Method POST -Body $ReqTokenBody


$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("Authorization", "Bearer $($Tokenresponse.access_token)")
$headers.Add("Content-type", "application/json")


$akvSecretURL = "https://"+$AKVaultName+".vault.azure.net/secrets/"+$AKSecretName+"?api-version=7.2"
$Data = Invoke-RestMethod -Headers $headers -Uri $akvSecretURL -Method Get
$SecretValue = ($Data | select-object Value).Value



if($SecretValue -ne $NewPassword){

$json = @"
{
"value": "$NewPassword"
}
"@
$patchdata = Invoke-RestMethod -Headers $headers -Uri $akvSecretURL -Method PUT -Body $json
}
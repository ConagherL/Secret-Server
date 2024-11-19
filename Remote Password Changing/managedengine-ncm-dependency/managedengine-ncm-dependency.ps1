# Expected arguments: $SERVICENAME $MACHINE $DOMAIN $USERNAME $PASSWORD
$apiKey = '939fbb0dd3d4100cc7a0f8a3e7d02647'
$profileName = $args[0]
$baseUrl = $args[1]
$username = $args[2], $args[3] -join '\'
$password = $args[4]

$filtercontent = @{
    groupOp = 'AND'
    rules   = @(
        @{
            field = 'NCMSharedProfile__PROFILENAME'
            op    = 'eq'
            data  = $profileName
        }
    )
} | ConvertTo-Json -Depth 20
$encFiltercontent = [System.Web.HttpUtility]::UrlEncode($filtercontent)

$profListResults = Invoke-RestMethod -Uri "$baseUrl/ncmsettings/credProfList?apiKey=$apikey&jqgridLoad=true&filters=$encFiltercontent" -ContentType 'application/json' -Method GET

$profileId = $profListResults.rows.id | ConvertTo-Json
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("Content-Type", "application/x-www-form-urlencoded")

$description = "Updated by Secret Server on $(Get-Date -Format FileDateTime)"
$body = @{
    apiKey                = $apiKey
    IS_SNMP_PROFILE       = 'false'
    PROFILEID             = $profileId
    PROFILENAME           = $profileName
    PROFILEDESCRIPTION    = $description
    telnet_loginname      = $username
    telnet_password       = $password
    telnet_prompt         = '#'
    telnet_enableUserName = ''
    telnet_enablepassword = ''
    telnet_enableprompt   = ''
    ssh_loginname         = ''
    ssh_password          = ''
    ssh_prompt            = ''
    ssh_enableUserName    = ''
    ssh_enablepassword    = ''
    ssh_enableprompt      = ''
    snmp_version          = '0'
    snmp_readcommunity    = ''
    snmp_writecommunity   = ''
    snmp_username         = ''
    snmp_contextname      = ''
    snmp_authprotocol     = '20'
    snmp_authpassword     = ''
    snmp_privprotocol     = '51'
    snmp_privpassword     = ''
}

$updateParams = @{
    Uri     = "$baseUrl/ncmsettings/updateSharedProfile"
    Method  = 'POST'
    Body    = $body
    Headers = $headers
}

$updateProfResults = Invoke-RestMethod @updateParams
Write-Output $updateProfResults.statusMsg | ConvertTo-Json
if (-not $updateProfResults.isSuccess) {
    throw "Error updating profile password: $($updateProfResults.statusMsg)"
}
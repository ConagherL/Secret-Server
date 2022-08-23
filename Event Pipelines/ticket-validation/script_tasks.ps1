$params = $args
$SecretServerUrl = $params[0]
$SSUser = $params[1]
$SSPassword = $params[2]
$ReportId = $params[3]
$SecretId = $params[4]
$MasAccountNumber = $params[5]
$ByUser = $params[6]
$EventUserId = $params[7]

#region Static values
$baseInforURL = 'http://atlmslx84webd1.noblesys.com/sdata/slx/dynamic/-/vstargateabbrevs'
$soapUrl = "$SecretServerUrl/webservices/sswebservice.asmx"
#endregion Static values

#region Token request
$credential = [pscredential]::new($SSUser,(ConvertTo-SecureString $SSPassword -AsPlainText -Force))

$SecretServerHost = 'http://ss3'
$apiUrl = "$SecretServerHost/api/v1"

$Body = @{
    "grant_type" = "password"
    "username"   = $Credential.UserName
    "password"   = $Credential.GetNetworkCredential().Password
}

$token = Invoke-RestMethod -Method Post -Uri "$SecretServerHost/oauth2/token" -Body $Body | Select-Object -Expandproperty access_token

$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("Authorization", "Bearer $token")
#endregion Token request

#region pull data
$reportBody = @{
    id         = "$ReportId"
    parameters = @(
        @{
            Name  = "CustomText"
            Value = "$SecretId"
        }
    )
} | ConvertTo-Json

$ticketNumber = Invoke-RestMethod "$apiUrl/reports/execute" -Method 'POST' -Headers $headers -Body $reportBody -ContentType 'application/json' | Select-Object -ExpandProperty rows
$urlMetadata = [PSCustomObject]@{
    TicketNumber     = $ticketNumber[0]
    MasAccountNumber = $MasAccountNumber
}
#endregion pull data

#region CRM validation
$inforUrl = "$baseInforURL('$($urlMetadata.MasAccountNumber)-$($urlMetadata.TicketNumber)')"
try {
    $InforCrmResponse = Invoke-WebRequest -Uri $inforUrl
} catch {
    $auditMsg = "$ByUser | $($urlMetadata.TicketNumber) | $SecretId | $($urlMetadata.MasAccountNumber) | 'ticket could not be validated'"
}
if ($InforCrmResponse.SatusCode -eq 200) {
    [xml]$inforXml = $InforCrmResponse.Content
    if ($inforXml.diagnoses) {
        if ($inforXml.dianoses.daignosis.message -match "not found") {
            $auditMsg = "$ByUser | $($urlMetadata.TicketNumber) | $SecretId | $($urlMetadata.MasAccountNumber) | 'ticket not found'"
        }
    } elseif ($inforXml.entry) {
        switch ($inforXml.entry.payload.Vstargateabbrev.Result) {
            "Invalid-Closed" {
                $auditMsg = "$ByUser | $($urlMetadata.TicketNumber) | $SecretId | $($urlMetadata.MasAccountNumber) | 'ticket invalid or closed'"
            }
            "Valid*" {
                $auditMsg = "$ByUser | $($urlMetadata.TicketNumber) | $SecretId | $($urlMetadata.MasAccountNumber) | 'ticket valid'"
            }
            default {
                $auditMsg = "$ByUser | $($urlMetadata.TicketNumber) | $SecretId | $($urlMetadata.MasAccountNumber) | $($inforXml.entry.payload.Vstargateabbrev.Result)"
            }
        }
    }
}
#region CRM validation

#region soap - write custom audit
$soap = New-WebServiceProxy -Uri $soapUrl -Namespace 'ss'
$result = $soap.AddSecretCustomAudit($token,$SecretId,$auditMsg,$null,$null,$null,$EventUserId)
if ($result.Errors) {
    throw "Issue writing audit message to secret $SecretId [$($result.Errors)]"
}
#endregion soap - write custom audit
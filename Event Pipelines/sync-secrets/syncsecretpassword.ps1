$url = 'https://customer Secret Server URL'
$username = $args[0]
$password = $args[1]
$domain = $args[2]
$newpassword = $args[3]
$secretIdArray = $args[4]

$secretIds = $secretidArray.Split(',')

$comment = "Checkout for password sync process"

$soapUrl = "$url/webservices/sswebservice.asmx?wsdl"
$restUrl = "$url/api/v1"

$proxy = New-WebServiceProxy -uri $soapUrl
$auth = $proxy.Authenticate($username, $password, $null, $domain)
if ([string]::IsNullOrEmpty($auth.Errors)) {
    $token = $auth.Token

    $header = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $header.Add("Authorization", "Bearer $token")
} else {
    $errors = $auth.Errors[0]
    throw "Error authenticating to API: $errors"
}

foreach ($secretId in $secretIds) {
    Write-Output "Processing Secret: $secretId"
    $checkoutStatus = $proxy.GetCheckOutStatus($token, $secretId)
    if (-not [string]::IsNullOrEmpty($checkoutStatus.Errors)) {
        throw "Error capturing checkout status: $($checkoutStatus.Errors)"
    }
    if($checkoutStatus.Secret.active -eq $false){
        continue
    }
    if ($checkoutStatus.IsCheckedOut) {
        $checkin = $proxy.CheckIn($token, $secretId)
        if ([string]$checkin.Errors -match "currently checked out") {
            $restrictedEnd = "$restUrl/secrets/$secretId/restricted"
            $body = @{forceCheckIn = 'true' }

            $irmParams = @{
                Uri     = $restrictedEnd
                Method  = 'Post'
                Headers = $header
                Body    = $body
            }
            try {
                $checkedOut = Invoke-RestMethod @irmParams
                Write-Output "Secret $secretId checked out"
            } catch {
                throw "Issue checking out secret $secretId : $_ | $($checkedOut.Message)"
            }
        }
    }
    if ($checkoutStatus.Secret.SecretSettings.RequiresComment) {
        $restrictedEnd = "$restUrl/secrets/$secretId/restricted"
        $body = @{comment = $comment }

        $irmParams = @{
            Uri     = $restrictedEnd
            Method  = 'Post'
            Headers = $header
            Body    = $body
        }
        try {
            $checkedOut = Invoke-RestMethod @irmParams
            Write-Output "Secret $secretId checked out"
        } catch {
            throw "Issue checking out secret $secretId : $_ | $($checkedOut.Message)"
        }
    }
    $codeResponseProp = @{
        ErrorCode = "COMMENT"
        Comment = $comment
    }
    $coderesponse = new-object psobject -Property $codeResponseProp
    $currentSecret = $proxy.GetSecret($token, $secretId, $null, $coderesponse)
    if ([string]::IsNullOrEmpty($currentSecret.Errors)) {
        $secretName = $currentSecret.Secret.Name
        Write-Output "Setting password for Secret $secretName"
        foreach ($item in $currentSecret.Secret.Items) {
            if ($item.IsPassword) {
                $item.Value = $newpassword
            }
        }
        $secret = $currentSecret.Secret
        $updateSecret = $proxy.UpdateSecret($token, $secret)
        if ([string]::IsNullOrEmpty($updateSecret.Errors)) {
            Write-Output "Updated Secret: $secretName"
        } else {
            $errors = $updateSecret.Errors
            Write-Output "Errors updating secret $secretId : $errors"
            throw "Error updating secret $secretId - $errors"
        }
    } else {
        $errors = $currentSecret.Errors
        throw "Errors getting secret $secretId - $errors"
    }

    $checkoutStatus = $proxy.GetCheckOutStatus($token, $secretId)
    if ($checkoutStatus.IsCheckedOut) {
        Write-Output "Secret $secretId checked in"
        $null = $proxy.CheckIn($token, $secretId)
    }
    $currentSecret = $null
}
$params = $args
$url = $params[0].split(',')[0]
$user = $params[-3]
$cPass = $params[-2]
$nPass = $params[-1]

# Build auth header
$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $user, $cPass)))

# Set proper headers
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add('Authorization',('Basic {0}' -f $base64AuthInfo))

$uri = "$url/controller/changePassword"
$body = @{
    password =$nPass
}
# Send HTTP request
try {
    $response = Invoke-RestMethod -Headers $headers -Method POST -Uri $uri -Body $body
} catch {
    throw "$url returned error updating password for $user`: $($_.Exception.Message)"
}
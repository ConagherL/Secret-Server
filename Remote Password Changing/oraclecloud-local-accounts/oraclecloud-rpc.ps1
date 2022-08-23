$params = $args
$url = $params[0]
$user = $params[1]
$cPass = $params[2]
$nPass = $params[3]

# Build auth header
$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $user, $cPass)))

# Set proper headers
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add('Authorization',('Basic {0}' -f $base64AuthInfo))

# get user's ID
$uri = "$url/hcmRestApi/scim/Users?filter=username eq `"$user`""

# Send HTTP request
try {
    $restUser = Invoke-RestMethod -Headers $headers -Method GET -Uri $uri
} catch {
    throw "$url returned error getting user ID for $user`: $($_.Exception.Message)"
}

if ($restUser) {
    # update password for user
    $uri = "$url/hcmRestApi/scim/Users/$($restUser.Resources.id)"

    $body = @{
        schemas  = @("urn:scim:schemas:core:2.0:User")
        password = $nPass
    } | ConvertTo-Json
    # Send HTTP request
    try {
        $response = Invoke-RestMethod -Headers $headers -Method PATCH -Uri $uri -Body $body -ContentType 'application/json'
    } catch {
        throw "$url returned error updating password for $user`: $($_.Exception.Message)"
    }
} else {
    throw "Something went wrong with getting user id"
}

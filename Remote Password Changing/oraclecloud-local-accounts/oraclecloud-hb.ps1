$params = $args
$url = $params[0]
$user = $params[1]
$pass = $params[2]

# Build auth header
$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $user, $pass)))

# Set proper headers
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add('Authorization',('Basic {0}' -f $base64AuthInfo))

# Specify endpoint uri
$uri = "$url/hcmRestApi/scim/Users?filter=username eq `"$user`""

# Send HTTP request
try {
    $null = Invoke-RestMethod -Headers $headers -Method GET -Uri $uri
    $true
} catch {
    throw "Error returned for $user`: $($_.Exception.Message)"
}
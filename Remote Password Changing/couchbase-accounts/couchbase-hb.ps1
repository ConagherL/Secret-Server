$params = $args
$url = $params[0].split(',')[0]
$user = $params[-2]
$pass = $params[-1]

# Build auth header
$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $user, $pass)))

# Set proper headers
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add('Authorization',('Basic {0}' -f $base64AuthInfo))

# Specify endpoint uri
$uri = $url + "/whoami"

# Send HTTP request
try {
    $null = Invoke-RestMethod -Headers $headers -Method GET -Uri $uri
    $true
} catch {
    throw "Error returned for $user connecting to $url`: $($_.Exception.Message)"
}
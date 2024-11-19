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
$headers.Add('Accept','application/json')

# Specify endpoint uri
$uri = "$url/api/now/table/sys_user?sysparm_query=user_name%3D$($user)&sysparm_fields=sys_id&sysparm_limit=1"

# Specify HTTP method
$method = "get"

# Send HTTP request
try {
    $response = Invoke-RestMethod -Headers $headers -Method $method -Uri $uri -UseBasicParsing
} catch {
    throw "$url returned error retrieving $user`: $($_.Exception.Message)"
}

# Specify endpoint uri
if ($response) {
    $uri = "$url/api/now/table/sys_user/$($response.result.sys_id)?sysparm_input_display_value=true"
} else {
    throw "Response data missing"
}

# Specify HTTP method
$method = "patch"
# Specify request body
$body = "{`"user_password`":`"$nPass`"}"

# Send HTTP request
try {
    Invoke-RestMethod -Headers $headers -Method $method -Uri $uri -Body $body
} catch {
    throw "$url returned error updating the password: $($_.Exception.Message)"
}

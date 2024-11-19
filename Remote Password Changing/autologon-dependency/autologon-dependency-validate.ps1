# Assign arguments to variables for clarity and use in the script
$userId = $args[0]               # User ID for which the password needs to be updated
$newPassword = $args[1]          # New password to be set for the user
$authMethod = $args[2]           # Authentication method to be used (OAuth or APIKey)
$credentials = $args[3]          # Authentication credentials (token or API key)
$scenario = $args[4]             # Scenario identifier: 'SystemUser' or 'UserManagement'
$tenantId = $args[5]             # Tenant ID, needed for the User Management scenario
$communityId = $args[6]          # Community ID, needed for the User Management scenario

# Set up HTTP headers with content type. Additional headers are conditionally added below.
$headers = @{
    'Content-Type' = 'application/json'
}

# Conditionally add authorization headers based on the specified authentication method
if ($authMethod -eq "OAuth") {
    $headers['Authorization'] = "Bearer $credentials"  # Use bearer token for OAuth
} elseif ($authMethod -eq "APIKey") {
    $headers['X-API-Key'] = $credentials               # Use API key for APIKey method
}

# Prepare the JSON body with the new password and user ID
$body = @{
    "newPassword" = $newPassword
}

# Configure API endpoint and request body based on the scenario
switch ($scenario) {
    "SystemUser" {
        $endpointUrl = 'https://api.1kosmos.net/systemuser/changepassword'  # Endpoint for System User
        $body["accountId"] = $userId                                       # System User requires accountId
    }
    "UserManagement" {
        $endpointUrl = "https://api.1kosmos.net/tenant/$tenantId/community/$communityId/user/changepassword"  # Endpoint for User Management
        $body["userId"] = $userId                                                                     # User Management requires userId
    }
}

$jsonBody = $body | ConvertTo-Json  # Convert the body to JSON format

# Try to execute the REST API call and handle success or failure
try {
    $response = Invoke-RestMethod -Uri $endpointUrl -Method Post -Headers $headers -Body $jsonBody  # Invoke the REST method
    Write-Output "Password updated successfully. Response: $response"  # Output success message and response
} catch {
    Write-Error "Failed to update password: $_"  # Output error message if the call fails
}

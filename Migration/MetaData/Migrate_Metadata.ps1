# MetaData Migration Script

# Set global variables
# These must be set to the specific instances of Secret Server in your environment

# Source Secret Server instance URL
$site = "https://xxx.com/secretserver"
# API endpoint for the source Secret Server instance
$api = "$site/api/v1" # Do Not Change

# Target Secret Server instance URL
$tsite = "https://XXX.secretservercloud.com"
# API endpoint for the target Secret Server instance
$tapi = "$tsite/api/v1" # Do Not Change

# Path to the CSV file containing source metadata
$sourceMetadata_csv = "C:\temp\Secrets With Metadata.csv"
# Path to the CSV file containing target metadata (commented out)
#$targetMetadata_csv = "C:\temp\Target Secrets With Metadata.csv"

# IDs for the target metadata field and section
$targetMetadataFieldId = 3
$targetMetadatSectionId = 3

# New value to update in the metadata
$NewValue = "Updated 12/16"

# Get authentication token for the source Secret Server instance
try {
    # Prompt for credentials for the source Secret Server instance
    $AuthToken = Get-Credential -Message "Source Secret Server Instance"
    
    # Prepare the credentials for the token request
    $creds = @{
        username = $AuthToken.UserName
        password = $AuthToken.GetNetworkCredential().Password
        grant_type = "password"
    }
    
    # Initialize the token variable
    $token = ""
    
    # Request the OAuth2 token from the source Secret Server instance
    $response = Invoke-RestMethod -Uri "$site/oauth2/token" -Method Post -Body $creds
    
    # Extract the access token from the response
    $token = $response.access_token
} catch {
    # Handle any errors that occur during the token request
    Write-Host "Error obtaining authentication token: $_" -ForegroundColor Red
}

# Function to find secrets in the target Secret Server instance
function find-Secrets {
    param(
        $sourceName,  # The name of the source secret
        $secretID,    # The ID of the source secret
        $line         # The current line being processed
    )

    try {
        $secretName = $sourceName
        $uri = "$tsite/api/v1/secrets?filter.includeInactive=false&take=64961406"
        $results = Invoke-RestMethod -Uri $uri -Method GET -Headers $theaders

        foreach ($secret in $results.records) {
            if ($secretName -eq $secret.name) {
                # Add your logic here for what to do when the secret is found
            }
        }
    } catch {
        # Handle any errors that occur during the secret search
        Write-Host "Error finding secret: $_" -ForegroundColor Red
    }
}

# Function to update metadata in the target Secret Server instance
function update-Metadata {
    param(
        $secretID,    # The ID of the secret to update
        $newValue     # The new value to set in the metadata
    )

    try {
        $uri = "$tapi/secrets/$secretID/metadata"
        $body = @{
            fieldId = $targetMetadataFieldId
            sectionId = $targetMetadatSectionId
            value = $newValue
        }

        # Make the API call to update the metadata
        Invoke-RestMethod -Uri $uri -Method PUT -Body ($body | ConvertTo-Json) -Headers $theaders
        Write-Host "Successfully updated metadata for SecretID: $secretID" -ForegroundColor Green
    } catch {
        # Handle any errors that occur during the metadata update
        Write-Host "Error updating metadata for SecretID: $secretID. Error: $_" -ForegroundColor Red
    }
}

# Main script execution
try {
    # Import the source metadata from the CSV file
    $sourceMetadata = Import-Csv -Path $sourceMetadata_csv

    # Iterate through each row in the CSV file
    foreach ($row in $sourceMetadata) {
        $sourceName = $row.SecretName
        $secretID = $row.SecretID

        # Find the corresponding secret in the target Secret Server instance
        find-Secrets -sourceName $sourceName -secretID $secretID -line $row

        # Update the metadata for the found secret
        update-Metadata -secretID $secretID -newValue $NewValue
    }
} catch {
    # Handle any errors that occur during the main script execution
    Write-Host "Error during script execution: $_" -ForegroundColor Red
}

# Exit the script with a status code of 1
exit 1
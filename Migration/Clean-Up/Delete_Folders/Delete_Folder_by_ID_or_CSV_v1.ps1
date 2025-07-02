###############################################################################
# Variables for API Endpoints
###############################################################################
$oauthUrl = "https://XXX.secretservercloud.com/oauth2/token"
$apiBase  = "https://XXX.secretservercloud.com/api/v1/folders"

###############################################################################
# 1. PROMPT FOR USERNAME/PASSWORD CREDENTIALS
###############################################################################
Write-Host "Enter your Secret Server credentials. A prompt will appear..."
$creds = Get-Credential

$userName = $creds.UserName
$password = $creds.GetNetworkCredential().Password

###############################################################################
# 2. OBTAIN OAUTH2 TOKEN (PASSWORD GRANT, NO CLIENT ID)
###############################################################################

$body = @{
    grant_type = "password"
    username   = $userName
    password   = $password
}

try {
    $tokenResponse = Invoke-RestMethod -Uri $oauthUrl -Method POST -Body $body -ContentType "application/x-www-form-urlencoded"
    $accessToken   = $tokenResponse.access_token

    if (-not $accessToken) {
        throw "No access_token returned. Double-check your OAuth2 parameters."
    }

    Write-Host "Successfully obtained OAuth2 token."
}
catch {
    Write-Host "Failed to obtain OAuth2 token. Error details:"
    Write-Host $_
    return
}

###############################################################################
# 3. SET UP HEADERS FOR SUBSEQUENT REST CALLS
###############################################################################
$headers = @{
    "Authorization" = "Bearer $accessToken"
    "Content-Type"  = "application/json"
}

###############################################################################
# 4. MENU: DELETE SINGLE ID OR MULTIPLE IDS FROM CSV
###############################################################################
Write-Host "`nWould you like to delete a single Folder ID or import from CSV?"
Write-Host "[1] Single Folder ID"
Write-Host "[2] CSV File"

$userChoice = Read-Host "Enter 1 or 2"

switch ($userChoice) {

    ###########################################################################
    # OPTION 1: DELETE A SINGLE FOLDER BY ID
    ###########################################################################
    '1' {
        $folderId = Read-Host "Enter the Folder ID to delete"

        $url = "$apiBase/$folderId"
        
        # Build the JSON body if your environment requires it for DELETE
        # If it's optional, remove '-Body $jsonBody'
        $jsonBody = @{
            id            = $folderId
            objectType    = "folder"
            responseCodes = @("string")
        } | ConvertTo-Json
        
        try {
            Invoke-RestMethod -Uri $url -Method DELETE -Headers $headers -Body $jsonBody
            Write-Host "Folder with ID '$folderId' has been deleted."
        }
        catch {
            Write-Host "Failed to delete folder with ID '$folderId'. Error details:"
            Write-Host $_
        }
    }

    ###########################################################################
    # OPTION 2: DELETE MULTIPLE FOLDERS FROM A CSV
    ###########################################################################
    '2' {
        $csvPath = Read-Host "Enter the full path to your CSV file (e.g. C:\Path\To\FolderIDs.csv)"
        
        # CSV must have a header "FolderID"
        #
        # Example:
        # FolderID
        # 123
        # 456
        # 789
        #
        $folderList = Import-Csv -Path $csvPath

        foreach ($folder in $folderList) {
            $folderId = $folder.FolderID
            $url      = "$apiBase/$folderId"

            # Build the JSON body if your environment requires it for DELETE
            $jsonBody = @{
                id            = $folderId
                objectType    = "folder"
                responseCodes = @("string")
            } | ConvertTo-Json

            try {
                Invoke-RestMethod -Uri $url -Method DELETE -Headers $headers -Body $jsonBody
                Write-Host "Folder with ID '$folderId' has been deleted."
            }
            catch {
                Write-Host "Failed to delete folder with ID '$folderId'. Error details:"
                Write-Host $_
            }
        }
    }

    default {
        Write-Host "Invalid selection. Exiting..."
    }
}

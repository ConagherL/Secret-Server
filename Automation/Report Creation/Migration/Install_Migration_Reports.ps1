# Variables
$apiBaseUrl = "https://XXX.secretservercloud.com" # Base URL for Secret Server API
$repoOwner = "XXXXX"                          # GitHub username or organization name
$repoName = "XXXX"                       # Name of the GitHub repository
$branch = "main"                                  # Branch of the repository to access
$repoPath = "reports/discovery"                   # Path within the repository where the .sql files are located. If not root then format like "Reports/Migration"
$baseDir = "C:\temp\Migration"                    # Base directory for logs and files
$logDir = Join-Path -Path $baseDir -ChildPath "Logs"  # Directory for log files
$fileDir = Join-Path -Path $baseDir -ChildPath "Files" # Directory for downloaded files
$logFilePath = Join-Path -Path $logDir -ChildPath "log.txt" # Path to the log file
$zipFilePath = Join-Path -Path $fileDir -ChildPath "sql_reports.zip" # Path to the zip file that will contain the downloaded .sql files
$categoryId = "XXX"                                # CategoryId for the "Migration" category (set this to the appropriate value)

# Function to log messages
$global:headerWritten = $false

function Write-Log {
    param (
        [string]$message,
        [string]$color = "White",
        [string]$header
    )
    # Write to host with color
    Write-Host $message -ForegroundColor $color

    # Write to log file
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    if ($header -and -not $global:headerWritten) {
        Add-Content -Path $logFilePath -Value "`n[$header]"
        $global:headerWritten = $true
    }
    Add-Content -Path $logFilePath -Value "$timestamp $message"
}

# Function to authenticate with Secret Server API
function Authenticate-SecretServer {
    param (
        [string]$apiBaseUrl,
        [switch]$ShowToken
    )

    # Reset header flag
    $global:headerWritten = $false

    # Prompt for username and password
    $credential = Get-Credential -Message "Enter your Secret Server username and password"

    # Construct the authentication URL
    $authUrl = "$apiBaseUrl/oauth2/token"

    # Construct the body for the authentication request
    $body = @{
        grant_type = "password"
        username   = $credential.UserName
        password   = $credential.GetNetworkCredential().Password
        scope      = "api"
    }

    try {
        # Perform the authentication request
        $response = Invoke-RestMethod -Method Post -Uri $authUrl -ContentType "application/x-www-form-urlencoded" -Body $body

        if ($response.access_token) {
            Write-Log "Successfully authenticated with Secret Server API." "Green" "Authentication"
            Write-Log "Access Token: $($response.access_token)" "Yellow"
            if ($ShowToken) {
                Write-Host "Access Token: $($response.access_token)" -ForegroundColor Yellow
            } else {
                Write-Host "Access Token: [HIDDEN]" -ForegroundColor Yellow
            }
            return $response.access_token
        } else {
            Write-Log "Failed to authenticate with Secret Server API." "Red" "Authentication"
            return $null
        }
    } catch {
        Write-Log "Error during authentication with Secret Server API: $_" "Red" "Authentication"
        return $null
    }
}

# Function to download and zip SQL reports from GitHub
function Download-And-ZipSQLReports {
    param (
        [string]$repoOwner,
        [string]$repoName,
        [string]$branch,
        [string]$repoPath,
        [string]$fileDir,
        [string]$logFilePath,
        [string]$zipFilePath
    )

    # Reset header flag
    $global:headerWritten = $false

    # Create directories if they don't exist
    if (-Not (Test-Path -Path $fileDir)) {
        New-Item -ItemType Directory -Force -Path $fileDir -ErrorAction SilentlyContinue | Out-Null
    }

    if (-Not (Test-Path -Path $logDir)) {
        New-Item -ItemType Directory -Force -Path $logDir -ErrorAction SilentlyContinue | Out-Null
    }

    if (-Not (Test-Path -Path $logFilePath)) {
        New-Item -ItemType File -Force -Path $logFilePath -ErrorAction SilentlyContinue | Out-Null
    }

    # Dynamically construct the API URL using the -f format operator
    $apiUrl = "https://api.github.com/repos/{0}/{1}/contents/{2}?ref={3}" -f $repoOwner, $repoName, $repoPath, $branch
    Write-Log "Dynamically Constructed API URL: $apiUrl" "Yellow" "Download-And-ZipSQLReports"

    try {
        # Get the list of all .sql files in the specified directory of the repository
        $response = Invoke-RestMethod -Uri $apiUrl -Headers @{ 'User-Agent' = 'Mozilla/5.0' }
        Write-Log "Response received from GitHub API." "Green" "Download-And-ZipSQLReports"
    } catch {
        Write-Log "Failed to get response from GitHub API. Check the API URL and repository details." "Red" "Download-And-ZipSQLReports"
        exit 1
    }

    if ($response -eq $null) {
        Write-Log "No response received from GitHub API. Check the API URL and repository details." "Red" "Download-And-ZipSQLReports"
        exit 1
    }

    $sqlFiles = $response | Where-Object { $_.name -like "*.sql" }

    # Download each .sql file
    foreach ($file in $sqlFiles) {
        $fileUrl = $file.download_url
        $outputFilePath = Join-Path -Path $fileDir -ChildPath $file.name

        # Create subdirectories if necessary
        $fileDirPath = Split-Path -Path $outputFilePath -Parent
        if (-Not (Test-Path -Path $fileDirPath)) {
            New-Item -ItemType Directory -Force -Path $fileDirPath -ErrorAction SilentlyContinue | Out-Null
        }

        try {
            # Download the file
            Invoke-WebRequest -Uri $fileUrl -OutFile $outputFilePath -ErrorAction Stop
            Write-Log "File Name: $($file.name)" "Cyan" "Download-And-ZipSQLReports"
            Write-Log "Downloaded to: $outputFilePath" "Green" "Download-And-ZipSQLReports"
        } catch {
            Write-Log "Failed to download $($file.name)" "Red" "Download-And-ZipSQLReports"
        }
    }

    # Compress the downloaded files into a zip
    Compress-Archive -Path "$fileDir\*" -DestinationPath $zipFilePath -Force

    Write-Log "Downloaded and zipped all .sql files from the repository to $zipFilePath" "Green" "Download-And-ZipSQLReports"
}

# Function to create or update reports in Secret Server
function Create-ReportsInSecretServer {
    param (
        [string]$apiBaseUrl,
        [string]$accessToken,
        [string]$categoryId,
        [string]$fileDir
    )

    # Reset header flag
    $global:headerWritten = $false

    # Get all .sql files in the specified directory
    $sqlFiles = Get-ChildItem -Path $fileDir -Filter *.sql

    foreach ($file in $sqlFiles) {
        $fileContent = Get-Content -Path $file.FullName -Raw

        $body = @{
            categoryId  = [int]$categoryId
            name        = $file.BaseName
            description = "Imported from Github"
            reportSql   = $fileContent
        }

        $jsonBody = $body | ConvertTo-Json -Depth 10

        $headers = @{
            Authorization = "Bearer $accessToken"
            "Content-Type"   = "application/json"
        }

        $reportUrl = "$apiBaseUrl/api/v1/reports"

        try {
            # Check if the report already exists
            $existingReportsUrl = "$apiBaseUrl/api/v1/reports?name=$($file.BaseName)"
            $existingReports = Invoke-RestMethod -Method Get -Uri $existingReportsUrl -Headers $headers

            if ($existingReports.totalCount -gt 0) {
                # Update the existing report
                $reportId = $existingReports.data[0].id
                $updateReportUrl = "$apiBaseUrl/api/v1/reports/$reportId"
                $response = Invoke-RestMethod -Method Put -Uri $updateReportUrl -Headers $headers -Body $jsonBody
                Write-Log "Successfully updated report: $($file.BaseName)" "Green" "Create-ReportsInSecretServer"
            } else {
                # Create a new report
                $response = Invoke-RestMethod -Method Post -Uri $reportUrl -Headers $headers -Body $jsonBody
                Write-Log "Successfully created report: $($file.BaseName)" "Green" "Create-ReportsInSecretServer"
            }
        } catch {
            # Parse error response
            $errorResponse = $_.ErrorDetails | ConvertFrom-Json

            if ($errorResponse.modelState.reportSql) {
                foreach ($error in $errorResponse.modelState.reportSql) {
                    if ($error -eq "The SQL that was entered is not valid for reporting.") {
                        Write-Log "Invalid SQL for report: $($file.BaseName)" "Red" "Create-ReportsInSecretServer"
                    } else {
                        Write-Log "Error creating or updating report: $($file.BaseName) - $error" "Red" "Create-ReportsInSecretServer"
                    }
                }
            } elseif ($errorResponse.modelState.name) {
                foreach ($error in $errorResponse.modelState.name) {
                    if ($error -eq "Report Name must be unique for active reports.") {
                        Write-Log "Report names must be unique for report: $($file.BaseName)" "Red" "Create-ReportsInSecretServer"
                    } else {
                        Write-Log "Error creating or updating report: $($file.BaseName) - $error" "Red" "Create-ReportsInSecretServer"
                    }
                }
            } else {
                Write-Log "Error creating or updating report: $($file.BaseName)" "Red" "Create-ReportsInSecretServer"
            }
        }
    }
}

# Call the function to authenticate
$accessToken = Authenticate-SecretServer -apiBaseUrl $apiBaseUrl

if ($accessToken) {
    # Call the function to download and zip SQL reports
    Download-And-ZipSQLReports -repoOwner $repoOwner -repoName $repoName -branch $branch -repoPath $repoPath -fileDir $fileDir -logFilePath $logFilePath -zipFilePath $zipFilePath

    # Call the function to create or update reports in Secret Server
    Create-ReportsInSecretServer -apiBaseUrl $apiBaseUrl -accessToken $accessToken -categoryId $categoryId -fileDir $fileDir
} else {
    Write-Log "Failed to obtain access token." "Red"
}

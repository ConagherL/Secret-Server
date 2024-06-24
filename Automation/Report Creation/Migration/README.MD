# Install Migration Reports

This PowerShell script automates the process of downloading SQL reports from a GitHub repository, zipping them, and creating or updating reports in Secret Server.

## Prerequisites

Before using this script, ensure you have the following:

- PowerShell 5.1 or later
- Internet access to download files from GitHub
- Secret Server API access

## Variables

The script uses the following variables:

- `$apiBaseUrl`: Base URL for Secret Server API.
- `$repoOwner`: GitHub username or organization name.
- `$repoName`: Name of the GitHub repository.
- `$branch`: Branch of the repository to access.
- `$repoPath`: Path within the repository where the .sql files are located.
- `$baseDir`: Base directory for logs and files.
- `$logDir`: Directory for log files.
- `$fileDir`: Directory for downloaded files.
- `$logFilePath`: Path to the log file.
- `$zipFilePath`: Path to the zip file that will contain the downloaded .sql files.
- `$categoryId`: CategoryId for the "Migration" category.

## Installation

1. **Clone the repository:**

    ```sh
    git clone https://github.com/ConagherL/Secret-Server.git
    ```

2. **Navigate to the script directory:**

    ```sh
    cd Secret-Server/Automation/Report Creation
    ```

## Usage

1. **Run the script:**

    ```powershell
    .\Install_Migration_Reports.ps1
    ```

2. **Follow the prompts to enter your Secret Server username and password.**

## Script Details

### Functions

#### `Write-Log`

Logs messages to both the console and a log file.

#### `Authenticate-SecretServer`

Authenticates with the Secret Server API using the provided username and password.

#### `Download-And-ZipSQLReports`

Downloads SQL reports from a specified GitHub repository and zips them.

#### `Create-ReportsInSecretServer`

Creates or updates reports in Secret Server using the downloaded SQL files.

### Example Call

```powershell
# Variables
$apiBaseUrl = "https://happygolucky.secretservercloud.com"
$repoOwner = "PS"
$repoName = "Secret-Server"
$branch = "main"
$repoPath = "Reports/Migration"
$baseDir = "C:\temp\Migration"
$logDir = Join-Path -Path $baseDir -ChildPath "Logs"
$fileDir = Join-Path -Path $baseDir -ChildPath "Files"
$logFilePath = Join-Path -Path $logDir -ChildPath "log.txt"
$zipFilePath = Join-Path -Path $fileDir -ChildPath "sql_reports.zip"
$categoryId = "26"

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

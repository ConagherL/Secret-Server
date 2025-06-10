# Secret Server Policy Creation Automation

This PowerShell script automates the creation and updating of Secret Server policies from a CSV file, and assigns them to folders as needed.

## Features

- **Bulk policy creation/update** from a CSV file.
- **Approver group resolution** (users or groups).
- **Policy assignment** to folders.
- **Logging** and debug output.
- **Customizable defaults** for policy settings.

## Prerequisites

- PowerShell 5.1+ (Windows)
- Access to Secret Server API (with appropriate permissions)
- A CSV file with policy definitions

## Usage

1. **Edit the script parameters** as needed (or pass via command line):

    - `$BaseUrl`: Your Secret Server base URL (e.g., `https://yourssurl`)
    - `$CsvPath`: Path to your CSV file (default: `C:\temp\Policy_Creation\Policy_Info.csv`)
    - `$LogPath`: Path for log output

2. **Prepare your CSV file** with the following columns:

    | PolicyName | PolicyDescription | Approvers           | FolderName         |
    |------------|------------------|---------------------|--------------------|
    | Example    | Example policy   | Group1,User2        | \Folder\Subfolder  |

    - `Approvers` is a comma-separated list of group/user names.
    - `FolderName` is the full folder path (optional).

3. **Run the script**:

    ```powershell
    .\Create_Policy_From_CSV_v2.ps1
    ```

    You will be prompted for Secret Server credentials.

## Script Overview

- **Connect-SecretServer**: Authenticates and retrieves an access token.
- **Write-Log**: Logs messages to file and console.
- **Resolve-ApproverGroup**: Resolves approver names to group/user IDs.
- **Get-ExistingPolicy**: Checks if a policy already exists.
- **Build-CreatePolicyBody / Build-PolicyPatchBody**: Constructs API request bodies.
- **Set-FolderPolicy**: Assigns a policy to a folder.
- **Invoke-PolicyCreate / Invoke-PolicyPatch**: Creates or updates policies via API.

## Logging

- All actions and errors are logged to the file specified by `$LogPath`.

## Notes

- The script uses Secret Server REST API v1/v2.
- Approvers must exist in Secret Server.
- Folder assignment is optional; if not specified, policy is created/updated only.

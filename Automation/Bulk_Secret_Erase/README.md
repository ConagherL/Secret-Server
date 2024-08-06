```markdown
# Secret Server Automation Script

## Overview

This PowerShell script automates the process of exporting a report of secrets and submitting a bulk request to erase those secrets using the Secret Server API. It is designed to help manage and remove outdated secrets in an automated and efficient manner.

## Features

- **Authentication**: Prompts for user credentials and uses OAuth2 to authenticate with the Secret Server API.
- **Report Export**: Exports a specified report of secrets to a CSV file for backup and review.
- **Secret Erasure**: Identifies secrets from the exported report and sends a bulk erase request for secrets older than a specified period.
- **Completion Notification**: Outputs messages indicating the status of each operation and confirms successful script execution with ASCII art.

## Prerequisites

- **PowerShell**: Ensure PowerShell is installed and configured on your system.
- **API Access**: You must have valid credentials and appropriate permissions to access the Secret Server API.
- **Network Access**: The script requires network access to communicate with the Secret Server endpoints.

## Usage

### Running the Entire Script

1. **Open PowerShell**: Navigate to the directory containing the script.
2. **Execute the Script**: Run the script using the following command:
   ```powershell
   .\YourScriptName.ps1
   ```
3. **Provide Credentials**: Enter your Secret Server username and password when prompted.
4. **Check Output**: Confirm that the script outputs messages indicating the success or failure of each operation 

### Running Specific Functions

To run specific functions individually, follow these steps:

1. **Dot-Source the Script**: Load the functions into your current PowerShell session:
   ```powershell
   . .\YourScriptName.ps1
   ```

2. **Run the `New-Session` Function**: Establish a session and retrieve an access token:
   ```powershell
   $authToken = New-Session -SecretServerURL "https://XXXX.secretservercloud.com/oauth2/token"
   ```

3. **Run the `Export-Report` Function**: Export a report and save it to a specified path:
   ```powershell
   Export-Report -reportId "217" -authToken $authToken -outputPath "C:\temp\Secret_erase\report.csv"
   ```

4. **Run the `Send-BulkSecretEraseRequest` Function**: Send a bulk erase request with specific secret IDs:
   ```powershell
   $secretIds = @("123", "456", "789")  # Example secret IDs
   Send-BulkSecretEraseRequest -secretIds $secretIds -authToken $authToken -requestComment "Erase old secrets" -eraseAfter (Get-Date).AddHours(48).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
   ```

## Variables

- `$apiBaseUri`: Base URI for the Secret Server API endpoints.
- `$reportExportEndpoint`: Endpoint for exporting the report.
- `$eraseEndpoint`: Endpoint for sending the bulk erase request.
- `$authEndpoint`: Endpoint for obtaining the OAuth2 token.
- `$reportId`: ID of the report to be exported.
- `$requestComment`: Comment associated with the erase request.
- `$eraseAfter`: Date set to 48 hours in the future for scheduling erasure.
- `$outputDirectory` and `$outputPath`: Locations for saving the exported CSV file.

## Error Handling

- The script includes basic error handling. If any operation fails, an error message will be outputted, and the script will terminate if necessary.
- Common errors include invalid credentials, network issues, or insufficient permissions.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

```

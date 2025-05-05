# Auto Approval Script for Secret Server

This PowerShell script automates the approval of secret access requests in Secret Server. It fetches pending requests, evaluates them against predefined criteria, and approves eligible requests.

## Features

- **Authentication**: Supports both interactive and SDK-based authentication.
- **Approval Criteria**:
  - Excludes requests from a specific ticket system ID.
  - Skips requests exceeding a maximum allowed duration.
- **Logging**: Logs all actions, errors, and summaries to a specified log file.
- **Pagination**: Handles paginated API responses to process all pending requests.

## Configuration

### Parameters

- `-Interactive`: Enables interactive mode for authentication using user credentials. If not specified, SDK-based authentication is used.

### Variables

- **BaseUrl**: The base URL of your Secret Server instance.
- **OauthUrl**: The OAuth token endpoint for authentication.
- **ExcludedTicketSystemId**: The ticket system ID to exclude from approval.
- **ApprovalReason**: The reason provided for approvals.
- **MaxAllowedMinutes**: The maximum allowed duration (in minutes) for approval.
- **PageSize**: The number of records to fetch per API call.
- **EnableLogging**: Enables or disables logging to a file.
- **EnableDebug**: Enables or disables debug output to the console.
- **LogFilePath**: The file path for storing logs.
- **SdkProfilePath**: The path to the SDK profile for authentication.

## Usage

1. **Set Configuration**: Update the configuration variables in the script to match your environment.
2. **Run the Script**:
   - For interactive authentication:
     ```powershell
     .\Auto_Approval.ps1 -Interactive
     ```
   - For SDK-based authentication:
     ```powershell
     .\Auto_Approval.ps1
     ```
3. **Monitor Logs**: Check the log file specified in `$LogFilePath` for detailed information about the script's execution.

## Logging

The script logs informational and error messages to the specified log file. Debug messages can also be enabled by setting `$EnableDebug` to `$true`.

## Error Handling

- Authentication errors are logged and displayed in the console.
- API errors during request fetching or approval are logged with detailed error messages.

## Summary

At the end of each run, the script logs a summary of the operation, including the number of approved, skipped, and failed requests, as well as the total execution time.

## Requirements

- PowerShell 5.1 or later.
- Access to Secret Server API.
- SDK installed and configured (if using SDK-based authentication).

## Notes

- Ensure the `$BaseUrl` and `$SdkProfilePath` are correctly configured for your environment.
- The script skips requests that do not meet the approval criteria, such as those with excluded ticket system IDs or excessive durations.

## Example

```powershell
# Run the script in interactive mode
.\Auto_Approval.ps1 -Interactive

# Run the script using SDK-based authentication
.\Auto_Approval.ps1
```

## License

This script is provided "as-is" without warranty of any kind. Use it at your own risk.
# Secret Server - Auto-Decline Expired Access Requests

A PowerShell script to automatically decline expired Secret Server access requests that are past their expiration date.

## Overview

This script connects to Delinea Secret Server and processes pending access requests, automatically declining those that have expired beyond a configurable buffer period. It's designed to run as an automated process to keep approval queues clean by removing stale expired requests.

## Features

- **Automatic Expiration Detection**: Identifies requests that are past their expiration date
- **Configurable Buffer Period**: Only declines requests that have been expired for a specified amount of time
- **Flexible Authentication**: Supports both interactive credential prompts and SDK-based authentication
- **Comprehensive Logging**: Detailed logging with timestamps for audit trails
- **Timezone Handling**: Properly converts UTC timestamps from the API to local time
- **Error Handling**: Robust error handling with detailed error logging
- **Exclusion Support**: Optional ticket system exclusions
- **Pagination Support**: Handles large numbers of requests efficiently

## Prerequisites

- **Secret Server Access**: Service account with approval permissions across target secrets
- **PowerShell 5.1+**: Windows PowerShell or PowerShell Core
- **Network Access**: HTTPS connectivity to Secret Server
- **Authentication Method**:
  - **Interactive**: Valid Secret Server credentials
  - **SDK**: Thycotic Secret Server SDK installed and configured

## Configuration

Edit the configuration variables at the top of the script:

```powershell
# Authentication
$Interactive            = $false    # Set to $true for credential prompt, $false for SDK

# Secret Server Connection
$BaseUrl                = "https://YOURURL.secretservercloud.com"
$OauthUrl               = "$BaseUrl/oauth2/token"

# Expiration Settings
$ExpiredDeclineBuffer   = 60        # Minutes past expiration before auto-declining
$DeclineReason          = "Auto-declined: Request expired"

# Optional Exclusions
$ExcludedTicketSystemId = $null     # Set to ticket system ID to exclude, or $null for none

# Logging
$EnableLogging          = $true
$EnableDebug            = $false
$LogFilePath            = "C:\Temp\ExpiredAccessDeclineLog.txt"

# SDK Configuration (if using SDK authentication)
$SdkProfilePath         = "E:\SDK\SDK_Profiles\ACCOUNTNAME\Config"
$SdkKeypath             = "E:\SDK\SDK_Profiles\ACCOUNTNAME\Key"
```

## Usage

### Basic Execution

```powershell
# Run with current configuration
.\Clear_Expired_Approvals.ps1
```

### Authentication Modes

**Interactive Mode** (prompts for credentials):
```powershell
# Set in script: $Interactive = $true
.\Clear_Expired_Approvals.ps1
```

**SDK Mode** (uses pre-configured SDK profile):
```powershell
# Set in script: $Interactive = $false
.\Clear_Expired_Approvals.ps1
```

## How It Works

1. **Authentication**: Connects to Secret Server using either interactive credentials or SDK
2. **Request Retrieval**: Fetches all pending access requests the service account can approve
3. **Expiration Check**: For each request:
   - Converts UTC expiration time to local time
   - Calculates time since expiration
   - Compares against configured buffer period
4. **Auto-Decline**: Requests expired beyond the buffer period are automatically declined
5. **Logging**: All actions are logged with detailed information

## Buffer Period Logic

The `$ExpiredDeclineBuffer` setting controls when requests are declined:

- **`60` minutes**: Decline requests expired for more than 1 hour
- **`5` minutes**: Decline requests expired for more than 5 minutes  
- **`0` minutes**: Decline requests immediately upon expiration

**Example**: If a request expired at 2:00 PM and the buffer is 60 minutes:
- At 2:30 PM: Request is expired but within buffer → **Skipped**
- At 3:15 PM: Request expired 75 minutes ago → **Auto-declined**

## Service Account Setup

The script requires a service account that:

1. **Has approval permissions** for the secrets you want to manage
2. **Is added to approval workflows** either directly or through group membership
3. **Can authenticate** via Secret Server credentials or SDK

### Recommended Approach
Create a dedicated service account and add it to approval groups rather than individual secret permissions for easier management.

## Logging

The script provides detailed logging including:

- Authentication success/failure
- Configuration settings
- Processing details for each request
- Decline actions with reasons
- Execution summary with counts and timing

**Log Levels**:
- `[INFO]`: Normal operations
- `[ERROR]`: Failures and exceptions

**Sample Log Output**:
```
2025-07-09 10:01:12 [INFO] ==== Expired Access Request Decline Run Started ====
2025-07-09 10:01:12 [INFO] Configuration: ExpiredDeclineBuffer=60 minutes
2025-07-09 10:01:12 [INFO] Processing request ID 118 by John Doe for secret 'Database Server' (expires: 07/09/2025 09:55:00)
2025-07-09 10:01:12 [INFO] Auto-declining expired request ID 118 (expired: 07/09/2025 09:55:00)
2025-07-09 10:01:12 [INFO] Successfully declined expired request ID 118
2025-07-09 10:01:12 [INFO] Run Summary: Declined=1, Skipped=0, Failed=0
```

## Error Handling

The script includes comprehensive error handling:

- **Authentication failures**: Detailed error messages and graceful exit
- **API connection issues**: Retry logic and detailed error logging
- **Individual request failures**: Continues processing other requests
- **Malformed responses**: Validation and error recovery

## Scheduling

For automated execution, schedule the script using:

**Windows Task Scheduler**:
```batch
powershell.exe -ExecutionPolicy Bypass -File "C:\Scripts\Clear_Expired_Approvals.ps1"
```

**Recommended Schedule**: Every 15-30 minutes during business hours

## Security Considerations

- **Service Account**: Use a dedicated service account with minimal required permissions
- **Credentials**: Store credentials securely (prefer SDK over interactive mode for automation)
- **Logging**: Ensure log files are stored securely and access is restricted
- **Network**: Use HTTPS and verify SSL certificates
- **Audit**: Review declined requests regularly through Secret Server audit logs

## Troubleshooting

### Common Issues

**"Authentication Failed"**
- Verify credentials are correct
- Check service account is not locked
- Ensure account has API access permissions

**"No pending access requests found"**
- Verify service account has approval permissions
- Check if requests exist in Secret Server UI
- Confirm `filter.isMyRequest=false` returns data

**"Request not expired but should be"**
- Check timezone settings
- Verify system clock is accurate
- Review `$ExpiredDeclineBuffer` configuration

**"Decline failed for request"**
- Ensure service account can approve the specific request
- Check request is still in "Pending" status
- Verify workflow permissions

### Debug Mode

Enable debug output for troubleshooting:
```powershell
$EnableDebug = $true
```

This provides detailed console output for each step of processing.

## API Endpoints Used

- `POST /oauth2/token` - Authentication
- `GET /api/v1/secret-access-requests` - Retrieve pending requests
- `PUT /api/v1/secret-access-requests` - Decline expired requests

## Version History

- **v1.0**: Initial release with basic auto-decline functionality
- **v1.1**: Added timezone handling and improved logging
- **v1.2**: Enhanced error handling and configuration options
# SentinelOne Remote Password Changing Script

This script automates the process of changing a user's password in SentinelOne using the SentinelOne API. It is designed to be used with Secret Server for secure password management.
This script automates the process of changing a user's password in SentinelOne. It uses the SentinelOne API to authenticate and perform the password change operation. The process is logged for auditing and debugging purposes.
---
## Features
## Prerequisitesto SentinelOne using admin credentials.
- Changes the password for a specified user.
1. **SentinelOne API Access**: Ensure you have API access to your SentinelOne instance.
2. **Admin Account**: An admin account with permissions to change user passwords.
3. **PowerShell**: The script is written in PowerShell and requires a compatible environment to execute.
4. **Network Connectivity**: Ensure the machine running the script can reach the SentinelOne API endpoint.The script requires the following parameters to be passed as arguments:
**ApiUrl**: The URL of the SentinelOne server.
---2. **AdminUsername**: The username of an admin account with permissions to change passwords.
rd**: The password for the admin account.
## Configuration4. **UserId**: The ID of the user whose password needs to be changed.

The script requires the following parameters to be passed as arguments:
gurations:
1. **ApiUrl**: The URL of the SentinelOne server.
2. **AdminUsername**: The username of an admin account with permissions to change passwords.mp\Logs\ChangePasswordLog.txt`).
3. **AdminPassword**: The password for the admin account.` to disable it.
4. **UserId**: The ID of the user whose password needs to be changed.
5. **NewPassword**: The new password to set for the user.## Usage
the required arguments in the following order:
### Default Settings```powershell
inUsername> <AdminPassword> <UserId> <NewPassword>
- **Log Directory**: `C:\Temp\Logs`
- **Log File**: `C:\Temp\Logs\ChangePasswordLog.txt`
- **Debug Mode**: Enabled by default. Set `$DebugEnabled` to `$false` in the script to disable debug logging.### Example
powershell
---.\SentinelOne_RPC.ps1 "https://sentinelone.example.com" "admin" "password123" "user123" "newpassword456"

## Usage

Run the script with the required arguments in the following order:- Logs are stored in the directory specified by `LogDir`.
try includes a timestamp and a message describing the operation or error.
```powershell
.\SentinelOne_RPC.ps1 <ApiUrl> <AdminUsername> <AdminPassword> <UserId> <NewPassword>Error Handling
```- The script will throw an error if authentication fails or if the password change operation encounters an issue.
e logged to the log file for troubleshooting.
### Example

```powershell
.\SentinelOne_RPC.ps1 "https://sentinelone.example.com" "admin" "password123" "user123" "newpassword456"he `DebugEnabled` flag can be toggled to control the verbosity of the logs.
```---## Logging- Logs are stored in the directory specified by the `LogDir` variable.- Each log entry includes a timestamp and a message describing the operation or error.- Debug logs can be enabled or disabled by modifying the `$DebugEnabled` variable in the script.---## Troubleshooting1. **Authentication Errors**:   - Ensure the `ApiUrl`, `AdminUsername`, and `AdminPassword` are correct.   - Verify the admin account has API access and sufficient permissions.2. **Password Change Failures**:   - Confirm the `UserId` is valid and corresponds to an existing user in SentinelOne.   - Ensure the `NewPassword` meets SentinelOne's password policy requirements.3. **Network Issues**:   - Verify the machine running the script can reach the SentinelOne API endpoint.
   - Check for firewall or proxy restrictions that may block API requests.

4. **Debugging**:
   - Enable debug logging by setting `$DebugEnabled` to `$true` in the script.
   - Review the log file for detailed error messages and timestamps.

---

## Notes

- This script is intended to be used in conjunction with Secret Server for secure password management.
- Ensure the admin account has sufficient permissions to change user passwords.
- The `DebugEnabled` flag can be toggled to control the verbosity of the logs.

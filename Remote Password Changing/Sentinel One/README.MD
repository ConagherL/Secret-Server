# SentinelOne Scripts for Remote Password Management and Validation

This repository contains two PowerShell scripts for managing and validating user credentials in SentinelOne using the SentinelOne API. Both scripts are designed to be used with Secret Server for secure password management. All operations are logged for auditing and debugging purposes.

---

## Scripts Overview

### 1. **SentinelOne_RPC.ps1**
This script automates the process of changing a user's password in SentinelOne.

#### Features
- Changes the password for a specified user in SentinelOne.
- Logs all operations and errors for auditing and debugging.
- Supports debug mode for detailed logging.

#### Configuration
The script requires the following parameters to be passed as arguments:
1. **ApiUrl**: The URL of the SentinelOne server.
2. **AdminUsername**: The username of an admin account with permissions to change passwords.
3. **AdminPassword**: The password for the admin account.
4. **UserId**: The ID of the user whose password needs to be changed.
5. **NewPassword**: The new password to set for the user.

#### Default Settings
- **Log Directory**: `C:\Temp\Logs`
- **Log File**: `C:\Temp\Logs\ChangePasswordLog.txt`
- **Debug Mode**: Enabled by default. Set `$DebugEnabled` to `$false` in the script to disable debug logging.

#### Usage
Run the script with the required arguments in the following order:

```powershell
.\SentinelOne_RPC.ps1 <ApiUrl> <AdminUsername> <AdminPassword> <UserId> <NewPassword>
```

##### Example
```powershell
.\SentinelOne_RPC.ps1 "https://sentinelone.example.com" "admin" "password123" "user123" "newpassword456"
```

---

### 2. **SentinelOne_HB.ps1**
This script validates a user's credentials against a SentinelOne instance.

#### Features
- Authenticates a user against SentinelOne using their credentials.
- Logs the authentication result for auditing and debugging.
- Supports debug mode for detailed logging.

#### Configuration
The script requires the following parameters to be passed as arguments:
1. **ApiUrl**: The URL of the SentinelOne server.
2. **Username**: The username to validate.
3. **Password**: The password to validate.

#### Default Settings
- **Log Directory**: `C:\Temp\Logs`
- **Log File**: `C:\Temp\Logs\ValidationLog.txt`
- **Debug Mode**: Enabled by default. Set `$DebugEnabled` to `$false` in the script to disable debug logging.

#### Usage
Run the script with the required arguments in the following order:

```powershell
.\SentinelOne_HB.ps1 <ApiUrl> <Username> <Password>
```

##### Example
```powershell
.\SentinelOne_HB.ps1 "https://sentinelone.example.com" "user123" "password123"
```

---

## Logging
- Logs are stored in the directory specified by the `LogDir` variable in each script.
- Each log entry includes a timestamp and a message describing the operation or error.
- Debug logs can be enabled or disabled by modifying the `$DebugEnabled` variable in the scripts.

---

## Troubleshooting
### For **SentinelOne_RPC.ps1**:
1. **Authentication Errors**:
   - Ensure the `ApiUrl`, `AdminUsername`, and `AdminPassword` are correct.
   - Verify the admin account has API access and sufficient permissions.
2. **Password Change Failures**:
   - Confirm the `UserId` is valid and corresponds to an existing user in SentinelOne.
   - Ensure the `NewPassword` meets SentinelOne's password policy requirements.
3. **Network Issues**:
   - Verify the machine running the script can reach the SentinelOne API endpoint.
   - Check for firewall or proxy restrictions that may block API requests.

### For **SentinelOne_HB.ps1**:
1. **Authentication Errors**:
   - Ensure the `ApiUrl`, `Username`, and `Password` are correct.
   - Verify the user account has API access and valid credentials.
2. **Network Issues**:
   - Verify the machine running the script can reach the SentinelOne API endpoint.
   - Check for firewall or proxy restrictions that may block API requests.

---

## Notes
- These scripts are intended to be used in conjunction with Secret Server for secure password management.
- Ensure the accounts used have sufficient permissions for their respective operations.
- The `DebugEnabled` flag can be toggled to control the verbosity of the logs.

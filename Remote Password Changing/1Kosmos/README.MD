# Password Update Utility

This PowerShell script automates password changes for both system users and managed users within specified tenants and communities. It offers flexibility through support for multiple authentication methods and robust error handling.

## Features

- **Dynamic Endpoint Configuration**: Chooses the correct API endpoint based on user scenario.
- **Supports Multiple Authentication**: Compatible with OAuth and API Key methods.
- **Advanced Error Handling**: Provides detailed error messages to aid in troubleshooting.

## Getting Started

### Prerequisites

- PowerShell 5.1 or higher

### Installation

Download the script to your local machine or clone the repository using:



Usage
Executing the Script
Run the script from the command line by navigating to the script's directory and executing one of the following commands:

# Update password for a system user
```powershell
powershell .\ChangePassword.ps1 userID newPassword OAuth yourOAuthToken SystemUser
```
# Update password for a user managed within a specific tenant and community
```powershell
powershell .\ChangePassword.ps1 userID newPassword APIKey yourApiKey UserManagement tenantID communityID
```
### Parameters
The script accepts the following arguments in the order listed:

1. **userID**: The identifier for the user whose password is being updated. This could be a system user ID or a user ID managed within a specific tenant, depending on the scenario.
2. **newPassword**: The new password that will be set for the user.
3. **authMethod**: The type of authentication to be used. It can either be `OAuth` or `APIKey`.
4. **credentials**: The actual credentials (OAuth token or API Key) corresponding to the chosen authentication method.
5. **scenario**: This defines the context of the password update and should be either `SystemUser` for system users or `UserManagement` for users managed within a specific tenant and community.
6. **tenantID**: (Required only for `UserManagement` scenario) The tenant ID under which the user is managed.
7. **communityID**: (Required only for `UserManagement` scenario) The community ID under which the user is managed.

Each argument must be provided in the exact order as specified for the script to function correctly.


Debugging
If you encounter errors during execution, check the PowerShell error output for specific messages. Common issues include:

Authentication Failures: Ensure credentials are correct and appropriate for the chosen authentication method.
Connection Issues: Verify network settings and endpoint accessibility.

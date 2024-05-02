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

# Update password for a user managed within a specific tenant and community
```powershell
powershell .\ChangePassword.ps1 userID newPassword APIKey yourApiKey UserManagement tenantID communityID



Parameters
* userID: Identifier for the user whose password is being updated.
* newPassword: The new password to set.
* authMethod: Type of authentication (OAuth or APIKey).
* credentials: Specific credentials for the chosen auth method.
* scenario: Defines context (SystemUser or UserManagement).
* tenantID and communityID: Required for the UserManagement scenario.

Debugging
If you encounter errors during execution, check the PowerShell error output for specific messages. Common issues include:

Authentication Failures: Ensure credentials are correct and appropriate for the chosen authentication method.
Connection Issues: Verify network settings and endpoint accessibility.

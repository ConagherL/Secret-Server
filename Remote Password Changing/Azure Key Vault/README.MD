# Azure Key Vault Password Rotation Script

This PowerShell script is designed to update a secret in an Azure Key Vault if its value differs from the provided new password. The script uses the Azure AD client credentials flow to authenticate and interact with the Azure Key Vault API.

## Prerequisites

Before using this script, ensure you have the following:

1. **Azure AD Application**: You need an Azure AD application registered with the appropriate permissions for accessing Azure Key Vault (e.g., **Key Vault Secret Management** permission).
2. **Azure Key Vault**: Ensure the secret you want to rotate exists in your Azure Key Vault.
3. **PowerShell**: Make sure you have PowerShell installed on your system.

## Arguments

This script accepts the following arguments:

1. `clientid` - The Client ID of your Azure AD application.
2. `clientSecret` - The Client Secret of your Azure AD application.
3. `tenantID` - The Tenant ID of your Azure AD tenant.
4. `vault` - The name of the Azure Key Vault.
5. `secret` - The name of the secret in Azure Key Vault to be rotated.
6. `newpassword` - The new password value to update the secret with.

## Usage

Run the script using PowerShell, passing in the required arguments:

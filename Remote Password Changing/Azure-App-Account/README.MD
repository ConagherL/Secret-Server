# Azure App Registration Password Management

Effortlessly manage Azure App Registration client secrets by automating password generation, removing expired credentials, updating Azure Key Vault secrets, and integrating seamlessly with Delinea Secret Server.

## 🚀 Features
- **Authentication**: Logs into Azure using a Service Principal.
- **Secret Cleanup**: Removes expired client secrets.
- **Password Generation**: Creates a new client secret for the specified App Registration.
- **Expiration Management**: Uses a predefined expiration period for secret rotation.
- **Azure Key Vault Integration**: Updates specified Azure Key Vault(s) with the new client secret.
- **Logging**: Records all actions to a log file for auditing.
- **Secret Server Integration**: Returns password and expiration date as DataItems.

## 🛠️ Parameters
| Parameter   | Description                                      |
|-------------|--------------------------------------------------|
| `$username` | Secret Name associated with the new client secret|
| `$Object-ID`| Object ID of the Azure App Registration          |
| `$client-id`| Service Principal Application ID                 |
| `$client-secret` | Service Principal Secret                    |
| `$tenant-id` | Azure Active Directory Tenant ID                |
| `$keyvaults` | Comma-separated list of Azure Key Vault names   |

## ⚡ Usage
Run the script with the required parameters:

```powershell
.\Azure-App_Registration-RPC.ps1 "MyAppSecret" "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" "yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy" "SuperSecretKey" "tenant123" "vault1,vault2"
```

## 📌 Example Output
```plaintext
password    : AbCdE1!@#Xyz
Expiration  : 2025-09-14 10:45:00
```

## 📒 Notes
- ❗ The script removes only expired secrets to prevent unintended deletions.
- The expiration period is hardcoded and can be adjusted in the script (`$ExpirationDays`).
- Optimized for use with Delinea Secret Server.

## 📂 Logging
Logs are stored at:
```
C:\temp\Logs\AppPasswordLog.txt
```

## 🔧 Setup & Configuration

### Azure Permissions
The Service Principal used by the script requires the following permissions:

#### Azure Key Vault
The script requires the following permissions for Azure Key Vault:
- `If using Access Policies: "Set" (plus optionally "Get"/"List") secret permissions`
- `If using RBAC: Key Vault Secrets Officer (or Key Vault Contributor)`

#### Azure AD / Graph
The script requires the following permissions for Azure AD / Graph:
- `Preferably Application.ReadWrite.OwnedBy if SP is the owner, otherwise Application.ReadWrite.All (plus necessary read permissions)`
- `Application.ReadWrite.OwnedBy or Application.ReadWrite.All (controls deletion/writing)`

These permissions can be granted by assigning the appropriate roles to the Service Principal in the Azure portal.

### PowerShell Module Requirements
The script requires the following PowerShell module:
- `Az.Accounts`
- `Az.KeyVault`

You can install them using the following command:
```powershell
Install-Module -Name Az.Accounts -Force
Install-Module -Name Az.KeyVault -Force
```

### Step 1: Add Scripts to Secret Server
- Upload the Heartbeat (HB) and Remote Password Changing (RPC) scripts to Secret Server.
- Modify RPC script to set Expiration and tenantID values

### Step 2: Create Password Changer
- **Base Password Changer**: PowerShell Script
- **Name**: Azure App Registration

#### Verify Password Change Commands
| Field   | Value                           |
|---------|---------------------------------|
| Script  | Azure_App_Registration_HB.ps1   |
| Arguments | NO ARGUMENTS                  |

#### Password Change Commands
| Field   | Value                           |
|---------|---------------------------------|
| Script  | Azure_App_Registration_RPC.ps1  |
| Arguments | `$username $Object-ID $[1]$client-id $[1]$client-secret $azure-key-vaults $tenant-id` |



### Step 3: Import Secret Template
- Import the secret template via the provided XML file.
- Set the Expiration field to "Not Editable" to prevent users from modifying it.
- Adjust password complexity to avoid "Password Complexity" warnings.
- Map the previously built password changer to the template.


### Step 4: Create Secret
- Create a new Secret using the imported template.

### Step 5: Add Privileged Account
- Assign the privileged account to the associated secrets section.
- Secret must use the Out-of-Box Azure App Registration template

### Step 6: Verify Password Changing
- Test and verify that password rotation functions correctly.
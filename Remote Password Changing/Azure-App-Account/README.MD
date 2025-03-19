# Azure App Registration Password Management

Effortlessly manage Azure App Registration client secrets by automating password generation, removing expired credentials, and integrating seamlessly with Delinea Secret Server.

## 🚀 Features
- **Authentication**: Logs into Azure using a Service Principal.
- **Secret Cleanup**: Removes expired client secrets.
- **Password Generation**: Creates a new client secret for the specified App Registration.
- **Expiration Management**: Uses a predefined expiration period for secret rotation.
- **Logging**: Records all actions to a log file for auditing.
- **Secret Server Integration**: Returns password and expiration date as DataItems.

## 🛠️ Parameters
| Parameter   | Description                                      |
|-------------|--------------------------------------------------|
| `$username` | Secret Name associated with the new client secret|
| `$Object-ID`| Object ID of the Azure App Registration          |
| `$client-id`| Service Principal Application ID                 |
| `$client-secret` | Service Principal Secret                    |

## ⚡ Usage
Run the script with the required parameters:

```powershell
.\Azure-App_Registration-RPC.ps1 "MyAppSecret" "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" "yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy" "SuperSecretKey"
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
- `Application.ReadWrite.All`
- `Directory.Read.All`

These permissions can be granted by assigning the appropriate roles to the Service Principal in the Azure portal.

### PowerShell Module Requirements
The script requires the following PowerShell module:
- `Az.Accounts`

You can install it using the following command:
```powershell
Install-Module -Name Az.Accounts -Force
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
| Arguments | `$[1]$client-id $[1]$client-secret $[1]$tenant-id $username $newpassword` |

![My Image](https://github.com/user-attachments/assets/081a02e2-91d4-426a-b551-74c317135769)

### Step 3: Import Secret Template
- Import the secret template via the provided XML file.
- Set the Expiration field to "Not Editable" to prevent users from modifying it.
- Adjust password complexity to avoid "Password Complexity" warnings.
- Map the previously built password changer to the template.

![My Image](https://github.com/user-attachments/assets/b951cfb3-ec64-4179-8ca7-d56feba08d7e)

### Step 4: Create Secret
- Create a new Secret using the imported template.

### Step 5: Add Privileged Account
- Assign the privileged account to the associated secrets section.
- Secret must use the Out-of-Box Azure App Registration template

### Step 6: Verify Password Changing
- Test and verify that password rotation functions correctly.


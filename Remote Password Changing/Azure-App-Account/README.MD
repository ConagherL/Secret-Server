# Azure App Registration Password Management

Effortlessly manage Azure App Registration client secrets by automating password generation, removing expired credentials, updating Azure Key Vault secrets, and integrating seamlessly with Delinea Secret Server. 

- Two versions of this code exist.
- The first version handles the RPC for App registration and AKV secrets.
- The second one utilizes the released AKV external secrets feature in Secret Server and only performs the RPC on the app registration. External secrets must be set up and listed on the master secret.

## 🚀 Features
- **Authentication**: Logs into Azure using a Service Principal (App ID + Secret).
- **Secret Cleanup**: Removes expired client secrets whose names match the current `SecretName`.
- **Password Generation**: Creates a new client secret for the specified App Registration.
- **Expiration Management**: Uses a configurable expiration period for secret rotation (default: 180 days).
- **Azure Key Vault Integration**: Updates one or more Azure Key Vaults with the new client secret.
- **Logging**: Logs all actions and errors to a local log file.
- **Secret Server Integration**: Returns the new password and expiration date as DataItems for Secret Server to consume.
- **Fails Fast**: Exits immediately if any Azure Key Vault update fails, ensuring consistency.

## 🛠️ Parameters
| Parameter        | Description                                                        |
|------------------|--------------------------------------------------------------------|
| `$SecretName`    | The name of the secret used in Azure Key Vault and credential tag. |
| `$ObjectId`      | Object ID of the target Azure App Registration.                    |
| `$AuthAppId`     | Application ID of the Service Principal used for auth.             |
| `$AuthSecret`    | Secret for the Service Principal.                                  |
| `$TenantId`      | Azure Active Directory Tenant ID.                                  |
| `$KeyVaultsCsv`  | Comma-separated list of Azure Key Vault names to update.           |

## ⚡ Usage
```powershell
.\Azure-App_Registration-RPC.ps1 "MyAppSecret" `
    "00000000-0000-0000-0000-000000000001" `
    "00000000-0000-0000-0000-000000000002" `
    "SuperSecretKey" `
    "tenant123" `
    "vault1,vault2"
```

📌 Example Output
```plaintext
password    : AbCdE1!@#Xyz
Expiration  : 2025-09-14 10:45:00
```

📒 Notes
-    ❗ Expired secrets are removed only if their CustomKeyIdentifier matches the current SecretName (Base64-encoded).
-    The expiration period is defined by $ExpirationDays inside the script (default is 180 days).
-    If any Azure Key Vault update fails, the script logs the error and exits immediately to avoid inconsistent states.
-    Logs include timestamps, error levels, and detailed operation summaries.

📂 Logging
Logs are written to the following location (edit the script to change this):

```
C:\temp\Logs\AppPassword-AKVPassword-Log.txt
```

🔧 Setup & Configuration

### Azure Permissions

#### Azure Key Vault
The Service Principal used by the script requires one of the following for each vault:

- **If using Access Policies**: Set (and optionally Get/List) permissions.
- **If using RBAC**: Key Vault Secrets Officer or Key Vault Contributor.

#### Azure AD / Microsoft Graph
The Service Principal requires:

- `Application.ReadWrite.All` (or `Application.ReadWrite.OwnedBy` if it owns the App Reg).
- Optional: `Directory.Read.All` for better listing/debugging.

### Required PowerShell Modules
```powershell
Install-Module -Name Az.Accounts -Force
Install-Module -Name Az.KeyVault -Force
Install-Module -Name Az.Resources -Force
```

🔁 Integration with Secret Server

### Step 1: Upload Scripts
Upload the RPC script `Azure-App_Registration-RPC.ps1` to Secret Server.

Heartbeat script is optional depending on your setup.

### Step 2: Create a Password Changer
- **Type**: PowerShell Script
- **Name**: Azure App Registration
- **Arguments Format**:
  ```plaintext
  $SecretName $ObjectId $AuthAppId $AuthSecret $TenantId $KeyVaultsCsv
  ```

### Step 3: Import Secret Template
- Import XML template with fields: Secret Name, Object ID, App ID, Secret, Tenant ID, Key Vaults.
- Mark expiration as "Not Editable".
- Associate this Password Changer to the template.

### Step 4: Create a New Secret
- Use the imported template.
- Populate all fields, especially Key Vaults (comma-separated).

### Step 5: Link a Privileged Account
The privileged account should have sufficient Azure permissions.

- Can be a Managed Identity, but this script is written for App ID + Secret.

### Step 6: Test Rotation
Use “Change Password” in Secret Server.

Verify:
- New password is created in App Reg.
- Azure Key Vault secret is updated.
- Expired secret (if any) is removed.


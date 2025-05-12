# Azure App Registration Secret Manager

This PowerShell script creates a new client secret for a specified Azure App Registration using the Microsoft Graph API. It also includes optional cleanup of previously created secrets based on specific criteria such as expiration and tagging.

## 📌 Features

- 🔐 Authenticates to Microsoft Graph using `client_credentials` flow
- 🆕 Creates a new `passwordCredential` (client secret) with:
  - Custom `displayName`
  - `startDateTime` and `endDateTime` based on defined expiration
  - Base64-encoded custom key identifier (e.g., `"CreatedBy:SecretServer"`)
- 🧹 Optional cleanup:
  - Deletes expired secrets matching a name **and** tag
  - Force deletes **all** secrets matching a given name
- 📜 Logs activity to a timestamped log file

---

## ⚙️ Configuration Options

| Variable                     | Description |
|-----------------------------|-------------|
| `$EnableLogging`            | Enables log file output (default: `true`) |
| `$EnableDebugLogging`       | Enables verbose output to console (default: `true`) |
| `$EnableExpiredSecretCleanup` | Deletes expired secrets with the correct tag (default: `false`) |
| `$EnableFullNameMatchCleanup` | Deletes **all** secrets with matching name, ignoring expiration/tag (default: `false`) |
| `$ExpirationDays`           | Number of days the new secret is valid (default: `180`) |
| `$CustomKeyIdentifierTag`   | Tag used to identify secrets created by this script (default: `CreatedBy:SecretServer`) |
| `$LogFilePath`              | Location for log output; generated per run with timestamp |

---

## ❗ Notes

- Requires Microsoft Graph App permissions for:
  - `Application.ReadWrite.All`
- The `secretText` is **only visible at creation time** and cannot be retrieved afterward.
- Failed or incomplete Graph API requests will be logged and surfaced via error messages.

---

## 🧾 Arguments

The script expects the following positional arguments passed via `$args[]`:

| Index | Name          | Description                          |
|-------|---------------|--------------------------------------|
| 0     | `$SecretName` | Display name for the new secret      |
| 1     | `$ObjectId`   | Object ID of the Azure App Registration |
| 2     | `$ClientId`   | Client ID of the script's App Registration |
| 3     | `$ClientSecret` | Secret value for the script's App Registration |
| 4     | `$TenantId`   | Azure AD Tenant ID                   |

---

## ✅ Output

The script returns a PowerShell object with the following properties:

```powershell
$password = $result.password         # The new secret value
$expiration = $result.Expiration     # Expiration in yyyy-MM-dd HH:mm:ss
```

---

## 🗑 Cleanup Behavior

The script can optionally delete existing secrets based on the following conditions:

### Mode 1: Expired + Tagged Cleanup
- Enabled with: `$EnableExpiredSecretCleanup = $true`
- Deletes secrets if:
  - `displayName` matches `$SecretName`
  - `endDateTime` is in the past
  - Base64-decoded `customKeyIdentifier` matches `$CustomKeyIdentifierTag`

### Mode 2: Full Force Delete
- Enabled with: `$EnableFullNameMatchCleanup = $true`
- Deletes **all** secrets that match `$SecretName` regardless of expiration or tag

---

## 🐞 Logging

All logs are written to a file at:

```
C:\Temp\Logs\AppSecret-Graph-Log-<timestamp>.txt
```

Logs include:
- Authentication steps
- Secret creation
- Cleanup operations
- Full credential metadata if debug is enabled

Use `$EnableDebugLogging` to toggle verbose logs to console for troubleshooting.

---

## 🧪 Example Usage

```powershell
powershell .\Create-AppSecret.ps1 `
  "MyAppSecret" `
  "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" `
  "yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy" `
  "your-client-secret" `
  "tenant-id-guid"
```

---

## 📂 Return Integration (Secret Server)

This script is designed to return credentials in the format expected by Delinea Secret Server Remote Password Changing (RPC):

```powershell
return $dataItem
```

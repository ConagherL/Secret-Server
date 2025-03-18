# Azure App Registration Password Management

This project automates the management of Azure App Registration client secrets by generating new passwords and removing expired credentials. It integrates seamlessly with Delinea Secret Server to store and manage the generated secrets.

## Features

- **Authentication:** Logs into Azure using a Service Principal.
- **Secret Cleanup:** Identifies and removes only expired client secrets.
- **Password Generation:** Creates a new client secret for the specified App Registration.
- **Expiration Management:** Uses a predefined static expiration period for the new client secret.
- **Logging:** Records all actions to a log file.
- **Secret Server Integration:** Returns the newly generated password and its expiration date as DataItems.

## Parameters

- **$username:** The Secret Name associated with the new client secret.
- **$Object-ID:** The Object ID of the Azure App Registration.
- **$client-id:** The Service Principal Application ID.
- **$client-secret:** The Service Principal Secret.

## Usage

```powershell
.\Azure-App_Registration-RPC.ps1 "MyAppSecret" "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" "yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy" "SuperSecretKey"
```

## Example Output

```plaintext
password    : AbCdE1!@#Xyz
Expiration  : 2025-09-14 10:45:00
```

## Notes

- The script only removes expired client secrets to prevent unintended deletions.
- The expiration period is hardcoded in the script and can be adjusted by modifying `$ExpirationDays`.
- This script is optimized for use with Delinea Secret Server.

## Logging

Logs are stored at `C:\temp\Logs\AppPasswordLog.txt`.

## Steps to Build

1. **Import Secret Template:**
   - Import the secret template via the provided XML file.

2. **Add Scripts to Secret Server:**
   - Upload the Heartbeat (HB) and Remote Password Changing (RPC) scripts to Secret Server.
   - Ensure the RPC script includes a static tenant ID and maintains the expiration period.

3. **Create Password Changer:**
![My Image](https://github.com/user-attachments/assets/b951cfb3-ec64-4179-8ca7-d56feba08d7e)

   - Base Password Changer: PowerShell Script
   - Name: Azure App Registration
   - Verify Password Change Commands:
     - Script: Azure_App_Registration_HB.ps1
     - Arguments: NO ARGUMENTS
   - Password Change Commands:
     - Script: Azure_App_Registration_RPC.ps1
     - Arguments: `$[1]$client-id $[1]$client-secret $[1]$tenant-id $username $newpassword`

4. **Create Secret:**
   - Create a new secret using the imported template.

5. **Add Privileged Account:**
   - Add the privileged account to the associated secrets section.

6. **Verify Password Changing:**
   - Verify that password changing works correctly on the created secret.

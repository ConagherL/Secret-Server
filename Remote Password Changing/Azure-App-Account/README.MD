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

- **$args[0]:** The Secret Name associated with the new client secret.
- **$args[1]:** The Object ID of the Azure App Registration.
- **$args[2]:** The Service Principal Application ID.
- **$args[3]:** The Service Principal Secret.

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

## Secret Template

```xml
<!-- filepath: c:\Github\Secret-Server\Remote Password Changing\Azure-App-Account\SecretTemplate.xml -->
<SecretTemplate>
    <SecretType>Azure App Registration Secret Rotation</SecretType>
    <Fields>
        <Field>
            <Name>Domain</Name>
            <Type>Text</Type>
            <Required>true</Required>
        </Field>
        <Field>
            <Name>Password</Name>
            <Type>Password</Type>
            <Required>true</Required>
        </Field>
        <Field>
            <Name>User name</Name>
            <Type>Text</Type>
            <Required>true</Required>
        </Field>
    </Fields>
</SecretTemplate>
```

## Mapping

![Mapping](attachment:image.png)

## Steps to Build

1. **Import Secret Template:**
   - Import the secret template via the provided XML file.

2. **Add Scripts to Secret Server:**
   - Add the Heartbeat (HB) and Remote Password Changing (RPC) scripts to Secret Server.
   - Ensure the RPC script includes a static tenant ID and maintains the expiration period.

3. **Create Password Changer:**
   - Configure the password changer using the provided mapping and settings.

4. **Create Secret:**
   - Create a new secret using the imported template.

5. **Add Privileged Account:**
   - Add the privileged account to the associated secrets section.

6. **Verify Password Changing:**
   - Verify that password changing works correctly on the created secret.

## License

This project is licensed under the MIT License.
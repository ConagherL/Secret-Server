# Azure Key Vault Password Rotation and Heartbeat

## Pre-requisites
- PowerShell 5.1 or higher
- 443 access to Azure
- The Azure AD application must have sufficient permissions for the Key Vault (e.g., "Set", "Get").

## Steps to Set Up

### Upload the RPC and HB Scripts to Secret Server
1. **Heartbeat Script**
   - **Path:** `Secret-Server/Remote Password Changing/Azure Key Vault/Azure_Key_Vault_HB.ps1`
   - **Script Name:** `Azure_Key_Vault_HB.ps1`
   - **Category:** Heartbeat

2. **Password Change Script**
   - **Path:** `Secret-Server/Remote Password Changing/Azure Key Vault/Azure_Key_Vault_RPC.ps1`
   - **Script Name:** `Azure_Key_Vault_RPC.ps1`
   - **Category:** PowerShell Changing

### Create a Password Changer
1. **Base Password Changer:** PowerShell Script
2. **Name:** Azure Key Vault
3. **Verify Password Change Commands**
   - **Script:** `Azure_Key_Vault_HB.ps1`
   - **Arguments:** 
     ```
     $[1]$client-id $[1]$client-secret $[1]$tenant-id $vault $username $password
     ```

4. **Password Change Commands**
   - **Script:** `Azure_Key_Vault_RPC.ps1`
   - **Arguments:** 
     ```
     $[1]$client-id $[1]$client-secret $[1]$tenant-id $vault $username $newpassword
     ```

### Create a New Template
1. Import template XML: [Azure Key Vault Template](https://github.com/ConagherL/Secret-Server/blob/main/Remote%20Password%20Changing/Azure%20Key%20Vault/Azure_Key_Vault_Template.xml)

2. **Mapping**
- Enable RPC and HB
- **Password Type to Use:** Azure Key Vault

3. **Password Mapping Fields**
- **Domain** → Vault
- **Password** → Password
- **User Name** → Vault-Secret-Name

### Modify an Existing Template
1. **Template Name:** Azure Application Registration
2. Update all field names:
- Remove spaces and replace them with a `-`.
- Example: `Client ID` → `Client-ID`
3. This is required as no spaces are allowed in field names when performing RPC.

### Additional Steps
1. **Create and Vault an Azure Application Registration Account**
- The account must have proper permissions to the Key Vault.

2. **Create a New Secret Using the Azure Key Vault Template**
- **Secret Name:** Any value
- **Vault-Secret-Name:** The name of the Key Vault secret.
- **Password:** Existing secret value from the Key Vault.
- **Vault:** The Azure Key Vault name.

3. Assign the Azure Application Registration account as the **Associated Secret** on the Azure Key Vault secret.

4. Specify a privileged account responsible for executing the PowerShell script on the Distributed Engine.

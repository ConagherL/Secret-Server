# AdminSDHolder Permissions Script

This PowerShell script is designed to modify the ACL of the AdminSDHolder object in Active Directory, allowing specific account permissions to be set for password rotation of protected accounts.

## Overview

The AdminSDHolder object plays a crucial role in maintaining the security of privileged accounts within Active Directory. Accounts and groups in Active Directory with elevated privileges are protected by a special process (`SDPROP`), which enforces security settings on these accounts. To automate password rotation for these protected accounts, specific permissions must be delegated on the AdminSDHolder object.

This script automates the application of the required permissions using PowerShell and can either query the AdminSDHolder path dynamically or allow for manual input.

### Permissions Applied

The script applies the following permissions to a specified account:
1. **Read Property (RP)**
2. **Change Password**
3. **Reset Password**
4. **Write Property for lockoutTime**
5. **Write Property for pwdLastSet**
6. **Write Property for userAccountControl**

Each permission is applied to the AdminSDHolder object to ensure that the password rotation account can function properly.

## How to Use

1. Ensure that the **Active Directory** module is installed on the machine where the script will be run.
   
2. Run the script in PowerShell. The script will:
   - Prompt you to query the AdminSDHolder path dynamically or enter it manually.
   - Prompt you to enter the account name for which permissions should be set.
   - Log each step with color-coded outputs for easier tracking.

3. After the script completes, it will display a success message if the permissions were applied correctly.

### Example Execution

```powershell
Do you want to query the AdminSDHolder path dynamically? (Y/N): Y
AdminSDHolder path dynamically retrieved: CN=AdminSDHolder,CN=System,DC=cnf-net,DC=niagarafalls,DC=ca
Enter the account name (e.g., CNF-NET\AccountName): CNF-NET\RotationAccount
Added Read Property (RP) permission for CNF-NET\RotationAccount
Added Change Password permission for CNF-NET\RotationAccount
Added Reset Password permission for CNF-NET\RotationAccount
Added Write permission for lockoutTime for CNF-NET\RotationAccount
Added Write permission for pwdLastSet for CNF-NET\RotationAccount
Added Write permission for userAccountControl for CNF-NET\RotationAccount
Permissions have been updated successfully for CNF-NET\RotationAccount.
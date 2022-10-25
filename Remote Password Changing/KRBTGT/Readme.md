Set-ADAccountPassword -Identity $user -Reset -NewPassword (ConvertTo-SecureString -AsPlainText "$newPass" -Force)

Prerequisites
  RSAT AD PowerShell on the distributed engines or web nodes if no DE’s are used. 
    Install-WindowsFeature RSAT-AD-PowerShell
The Active Directory module will need to be on the Distributed Engines or web nodes if no DE’s are used.

import-module activedirectory


The krbtgt-pwd-reset.ps1 script will add the web assembly. This can be completed outside of the script on the DE’s or the web nodes.

Kerberos Account
The account retains the previous and current passwords. You will want to complete two password rotations on the account to complete a true rotation

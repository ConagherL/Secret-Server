Below are the articles surrounding the AdminSD Holder and the reasoning around the changes needed for PWD rotation of Protected accounts. As reviewed, these is the same permissions we applied to our existing PWD rotation account through delegation. However, the AdminSDHolder has a secondary ACL.

1.	Here Microsoft suggests what we did today as a workaround for a Forefront Identify Manager password reset issue:  [Link](https://docs.microsoft.com/en-US/troubleshoot/developer/webapps/iis/iisadmin-service-inetinfo/fim-password-reset-issue#more-information)
2.	This article gives information and context around AdminSDHolder and SDPROP (Security Descriptor Propagation propagates the settings out once per hour so even after running the ‘dsacls’ commands the effects won't be immediate):  [Link](https://docs.microsoft.com/en-us/previous-versions/technet-magazine/ee361593(v=msdn.10))
3.	This article has guidance from Microsoft on creating accounts that are meant to manage protected accounts, which involves delegating permissions on AdminSDHolder, so it's very relevant to what we're doing: [Link](https://docs.microsoft.com/en-us/windows-server/identity/ad-ds/manage/component-updates/appendix-i--creating-management-accounts-for-protected-accounts-and-groups-in-active-directory)


Required changes:

NOTE: Replace account and domain path to match your environment


Make sure to change the domain in each line to match the actual domain of the client. Nothing else needs to be changed. Only the highlighted parts. Run each line one at a time. 

dsacls "CN=AdminSDHolder,CN=System,DC=domain,DC=com" /G "DOMAIN\AccountName:RP"
dsacls "CN=AdminSDHolder,CN=System,DC=domain,DC=com" /G "DOMAIN\AccountName:CA;Change Password"
dsacls "CN=AdminSDHolder,CN=System,DC=domain,DC=com" /G "DOMAIN\AccountName:CA;Reset Password"
dsacls "CN=AdminSDHolder,CN=System,DC=domain,DC=com" /G "DOMAIN\AccountName:WP;lockoutTime"
dsacls "CN=AdminSDHolder,CN=System,DC=domain,DC=com" /G "DOMAIN\AccountName:WP;pwdLastSet"
dsacls "CN=AdminSDHolder,CN=System,DC=domain,DC=com" /G "DOMAIN\AccountName:WP;userAccountControl"

Revert changes:

dsacls CN=AdminSDHolder,CN=System,DC=domain,DC=com /R DOMAIN\PWRotationAccount

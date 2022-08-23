# Introduction

This will push the password to an encrypted registry location for configuring AutoLogon of a credential.

## Prerequisites

- Machines with Autologon preconfigured
- Powershell remoting enabled on these machines

## Configuration

1. Add [autologon-dependency.ps1](autologon-dependency.ps1) script to Secret Server:
   - **ADMIN** > **Scripts**

2. Configure Dependency Changer:
   - **ADMIN** > **Remote Password Changing** > **Configure Dependency Changers** >
   - Click on Create New Dependency Changer
   - Type "PowerShell Script"
   - Select "Windows Autologon" from the previous tutorial
   - Name: Autologon Dependency
   - Check the box for "Create Template"
   - Click on the Scripts Tab:
      - Leave the box unchecked for "Use Advanced Scripts"
      - Select the Script from the previous steps
      - Arguments `$[1]$USERNAME $[1]$DOMAIN $[1]$PASSWORD $MACHINE $PASSWORD`
      - Save

## Notes

The [autologon-dependency-validate.ps1](autologon-dependency-validate.ps1) has been required a few times now to be implemented as well as a secondary dependency. Windows has some requirement that after the autologon key is updated on the machine that it will fail to auto login. It requires the new password to be "provided" first before taking effect. The second dependency does just that. Research into further seeing why this is happening has not been available. At some point in the future the scripts could be combined to make deployment easier.

You may want to implement the [windows-restart-computer](../windows-restart-computer) dependency after updating this credential.

## Autologin Validate Configuration

1. Add [autologon-validate.ps1](autologon-validate.ps1) script to Secret Server:
   - **ADMIN** > **Scripts**

2. Configure Dependency Changer:
   - **ADMIN** > **Remote Password Changing** > **Configure Dependency Changers** >
   - Click on Create New Dependency Changer
   - Type "PowerShell Script"
   - Select "Windows Autologon" from the previous tutorial
   - Name: Autologon Dependency Verify
   - Check the box for "Create Template"
   - Click on the Scripts Tab:
      - Leave the box unchecked for "Use Advanced Scripts"
      - Select the Script from the previous steps
      - Arguments `$[1]$USERNAME $[1]$DOMAIN $[1]$PASSWORD $MACHINE $USERNAME $PASSWORD $DOMAIN`
      - Save

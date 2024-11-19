# Introduction

This will push the password to IIS configurations for Connect As accounts.

## Prerequisites

- Powershell remoting enabled on these machines
- Completed [IIS Physical Path Credentials](../../discovery/microsoft/iis-physical-path-credentials/index.md)

## Configuration

1. Add iisphysicalpathcred-rpc.ps1 script to Secret Server: **ADMIN** > **Scripts**
2. Configure Dependency Changer:

   - **ADMIN** > **Remote Password Changing** > **Configure Dependency Changers** >
   - Click on *Create New Dependency Changer* and select the following:
       - Type: *PowerShell Script*
       - Scan Template: Connect As
       - Name: ConnectAs Dependency Changer
       - Description: Connect As on %TARGET%
       - Check the box for "Create Template"
   - Click on the Scripts Tab:
       - Leave the box unchecked for "Use Advanced Scripts"
       - Select the Script from the previous steps
       - Arguments $ComputerName $ItemXPath $Domain $UserName $Password
       - Save

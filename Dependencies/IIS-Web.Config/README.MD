# IIS Web.Config Encryption and Decryption Scripts

This repository contains PowerShell scripts designed to encrypt and decrypt specific sections of a `web.config` file on remote IIS servers. These scripts utilize the `aspnet_regiis.exe` utility and are intended for integration with Secret Server dependencies or launchers.

## Scripts Overview

### 1. `Encrypt-WebConfig.ps1`
- **Purpose**: Encrypts a specified section of a `web.config` file.
- **Usage**:
  ```powershell
  powershell.exe -ExecutionPolicy Bypass -File Encrypt-WebConfig.ps1 `
    "<username>" "<domain>" "<password>" "<machine>" "<section>" "<config_path>"
  ```
- **Example**:
  ```powershell
  powershell.exe -ExecutionPolicy Bypass -File Encrypt-WebConfig.ps1 `
    "svc_app_user" "corp" 'P@ssword!"2024' "web01" "connectionStrings" "C:\inetpub\wwwroot\App"
  ```

### 2. `Decrypt-WebConfig.ps1`
- **Purpose**: Decrypts a specified section of a `web.config` file.
- **Usage**:
  ```powershell
  powershell.exe -ExecutionPolicy Bypass -File Decrypt-WebConfig.ps1 `
    "<username>" "<domain>" "<password>" "<machine>" "<section>" "<config_path>"
  ```
- **Example**:
  ```powershell
  powershell.exe -ExecutionPolicy Bypass -File Decrypt-WebConfig.ps1 `
    "svc_app_user" "corp" 'P@ssword!"2024' "web01" "connectionStrings" "C:\inetpub\wwwroot\App"
  ```

## Parameters

Both scripts accept the following parameters:
- **`<username>`**: The username for connecting to the remote server.
- **`<domain>`**: The domain or machine prefix for the username.
- **`<password>`**: The password for the username (in plain text).
- **`<machine>`**: The target computer where the `web.config` file resides.
- **`<section>`**: The section of the `web.config` file to encrypt or decrypt (e.g., `connectionStrings`).
- **`<config_path>`**: The full folder path on the remote machine where the `web.config` file is located.

## Logging

- Logs are saved to `C:\Temp\WebConfigEncryptLogs\<machine>_<timestamp>.log` by default.
- Logging can be toggled by modifying the `$EnableLogging` variable in the scripts.

## Notes

- Ensure the target folder contains a valid `web.config` file and is part of an IIS application.
- These scripts are designed to be triggered via Secret Server RPC or dependency changers.

## Prerequisites

- PowerShell remoting must be enabled on the target machine.
- The `aspnet_regiis.exe` utility must be available on the target machine.

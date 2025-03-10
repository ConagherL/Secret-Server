# Selenium Changer Tool (Microsoft Edge Version)

## Overview
The **Selenium Changer Tool** is a PowerShell-based automation script that uses **Selenium WebDriver** to manage passwords for web applications that do not provide an API. This tool automates two key functions:

- **Password Verification (Heartbeat):** Checks if stored credentials are still valid by attempting a login.
- **Password Rotation (RPC):** Updates the password on the target system by navigating through the web interface.

This version of the tool is designed to use **Microsoft Edge WebDriver**

## Features
- Automates login and password changes for web-based applications.
- Uses **Selenium WebDriver** with **Microsoft Edge**.
- Supports **headless mode** for automation on servers.
- Can be integrated into Secret Server or other password vault solutions.

## Prerequisites

### 1. Install Edge WebDriver
Edge WebDriver must match your installed **Microsoft Edge** version. Download it from:

🔗 **[Download Edge WebDriver](https://developer.microsoft.com/en-us/microsoft-edge/tools/webdriver/)**

- Place `msedgedriver.exe` in a directory (e.g., `C:\WebDriver\`).
- Add the directory to your **system PATH** or specify it in the script.

### 2. Install Selenium PowerShell Module
Run the following command to install Selenium for PowerShell:

```powershell
Install-Module Selenium
```

### 3. Set Execution Policy (if needed)

```powershell
Set-ExecutionPolicy RemoteSigned -Scope Process
```

### 4. Ensure Microsoft Edge is Installed
Microsoft Edge must be installed and up-to-date to match the WebDriver version.

## Usage

### Password Verification (Heartbeat)
Run the script in **heartbeat mode** to check if a stored password is still valid:

```powershell
./SeleniumChanger.ps1 -Username "exampleUser" -Password "CurrentPassword123"
```

### Password Rotation (RPC)
Run the script in **password rotation mode** to update the password:

```powershell
./SeleniumChanger.ps1 -Username "exampleUser" -Password "OldPassword123" -NewPassword "NewPassword456!"
```

## PowerShell Script Implementation
The script follows these steps:
1. **Login using Edge WebDriver.**
2. **Verify the credentials** (heartbeat mode) or **change the password** (RPC mode).
3. **Close the browser session** upon success or failure.

```powershell
# Import Selenium module
Import-Module -Name Selenium

# Define target system login URL
$LoginUrl = "https://target-system.example.com/login"

# Function: Test-PortalCredentials
function Test-PortalCredentials {
    param(
        [string]$Username,
        [string]$Password
    )
    Write-Host "Starting heartbeat for user $Username..."

    $Driver = Start-SeEdge -WebDriverDirectory "C:\WebDriver" -Headless
    Enter-SeUrl -Driver $Driver $LoginUrl

    try {
        $userField = Find-SeElement -Driver $Driver -Id "username" -Wait -Timeout 15
        Send-SeKeys -Element $userField -Keys $Username

        $passField = Find-SeElement -Driver $Driver -Id "password" -Wait -Timeout 15
        Send-SeKeys -Element $passField -Keys $Password

        $loginBtn = Find-SeElement -Driver $Driver -Id "loginButton"
        Invoke-SeClick -Element $loginBtn

        Start-Sleep -Seconds 5
        Write-Host "Heartbeat successful for $Username."
    }
    finally {
        $Driver.Quit()
    }
}

# Function: Invoke-PasswordChange
function Invoke-PasswordChange {
    param(
        [string]$Username,
        [string]$CurrentPassword,
        [string]$NewPassword
    )
    Write-Host "Starting password rotation for $Username..."

    $Driver = Start-SeEdge -WebDriverDirectory "C:\WebDriver" -Headless
    Enter-SeUrl -Driver $Driver $LoginUrl

    try {
        $userField = Find-SeElement -Driver $Driver -Id "username" -Wait -Timeout 15
        Send-SeKeys -Element $userField -Keys $Username

        $passField = Find-SeElement -Driver $Driver -Id "password"
        Send-SeKeys -Element $passField -Keys $CurrentPassword

        $loginBtn = Find-SeElement -Driver $Driver -Id "loginButton"
        Invoke-SeClick -Element $loginBtn

        Start-Sleep -Seconds 5

        $changePwdLink = Find-SeElement -Driver $Driver -LinkText "Change Password" -Timeout 10
        Invoke-SeClick -Element $changePwdLink

        Start-Sleep -Seconds 2

        $currPwdField = Find-SeElement -Driver $Driver -Id "currentPassword" -Timeout 10
        Send-SeKeys -Element $currPwdField -Keys $CurrentPassword

        $newPwdField = Find-SeElement -Driver $Driver -Id "newPassword"
        Send-SeKeys -Element $newPwdField -Keys $NewPassword

        $confirmPwdField = Find-SeElement -Driver $Driver -Id "confirmPassword"
        Send-SeKeys -Element $confirmPwdField -Keys $NewPassword

        $submitBtn = Find-SeElement -Driver $Driver -XPath "//button[@type='submit' or @id='changeBtn']"
        Invoke-SeClick -Element $submitBtn

        Start-Sleep -Seconds 5
        Write-Host "Password change successful for $Username."
    }
    finally {
        $Driver.Quit()
    }
}

# ** Main Script Execution **
param(
    [Parameter(Mandatory=$true)][string]$Username,
    [Parameter(Mandatory=$true)][string]$Password,
    [string]$NewPassword  # Optional
)
if ($NewPassword) {
    Invoke-PasswordChange -Username $Username -CurrentPassword $Password -NewPassword $NewPassword
} else {
    Test-PortalCredentials -Username $Username -Password $Password
}
```

## Troubleshooting
- **Ensure Edge WebDriver matches the browser version.**
- **Run the script with logging enabled** for debugging.
- **Use `-Headless` mode** for automation or **remove it** to debug visually.



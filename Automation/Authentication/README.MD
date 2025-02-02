# Secret Server SDK & OAuth Authentication Script

This PowerShell script provides a **modular authentication system** for **Delinea Secret Server** using:
- **SDK Authentication** (`tss.exe` CLI)
- **OAuth Authentication** (Token & Refresh Flow)
- **Delinea Platform Authentication** (Placeholder for future integration)

## 📌 Features
✔ Supports **three authentication methods**  
✔ **Non-interactive execution** for scheduled tasks  
✔ **Token caching & refresh support**  
✔ **Standard & verbose logging** for debugging  
✔ **Modular structure** for easy integration  

---

## 🚀 **Setup & Configuration**
### **1️⃣ Prerequisites**
- PowerShell 5.1+ (or PowerShell Core)
- Secret Server SDK installed (`tss.exe` CLI)
- API credentials for OAuth authentication (Client ID & Secret)
- Access to the **Delinea Platform API** (if using future integration)

### **2️⃣ Configuration**
Edit the following variables in **`SDK_OAUTH.ps1`** before running the script:

```powershell
$SecretServerUrl = "https://blt.secretservercloud.com"  # Secret Server URL
$SdkPath = "C:\Path\To\SDK"                             # Path to SDK (`tss.exe`)
$ConfigDirectory = "C:\tss"                             # SDK Configuration Directory
$LogPath = "C:\Logs\SecretServerSDK.log"                # Log File Path
$ClientId = "your_client_id"                            # OAuth Client ID
$ClientSecret = "your_client_secret"                    # OAuth Client Secret
$EnableLogging = $true                                  # Enable ($true) or disable ($false) logging
$VerboseLogging = $false                                # Enable ($true) for detailed logging
```
## 🔥 Usage
1️⃣ Running the Script Manually (Interactive)
To run the script manually from PowerShell:

```powershell
.\Delinea_Authentication.ps1
```
This will authenticate via SDK or refresh tokens and output the token status.

2️⃣ Using in Another PowerShell Script
You can include this script in other scripts using dot-sourcing:

```powershell
. "$PSScriptRoot\SDK_OAUTH.ps1"

# Ensure a valid token before making API calls
Ensure-Token

# Retrieve the token
$token = Get-Token
$headers = @{ Authorization = "Bearer $token" }
```

3️⃣ Running as a Scheduled Task (Non-Interactive)
To execute this script as a Windows Scheduled Task, use:

```powershell
powershell.exe -ExecutionPolicy Bypass -File "C:\Path\To\SDK_OAUTH.ps1"
```
Set this command in Task Scheduler under:

```Run whether user is logged on or not
Run with highest privileges```

## 🔐 Authentication Methods

| **Method**                          | **Command**            | **Description**                                    |
|-------------------------------------|------------------------|--------------------------------------------------|
| **SDK Authentication (Secret Server CLI)** | `Auth-SDK`           | Uses `tss.exe` to authenticate                   |
| **OAuth Authentication (Token Refresh)**   | `Auth-OAuth`         | Uses API-based OAuth authentication             |
| **Delinea Platform Authentication**        | `Auth-DelineaPlatform` | Placeholder for future integration               |


                                          

# Run-Discovery.ps1

[![PowerShell](https://img.shields.io/badge/PowerShell-v3%2B-blue.svg)](https://docs.microsoft.com/en-us/powershell/)
[![MIT License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

> **Run-Discovery.ps1** is a PowerShell automation script designed for **Secret Server**.  
> It connects to your Secret Server using OAuth2 (with either a token or interactive credentials),  
> retrieves the current discovery scan status, and conditionally initiates a new scan if no scan is running  
> and the previous scan's fetch start time exceeds a configurable wait period.

---

## ✨ Features

- **Flexible Authentication:**  
  - Use interactive credential prompts or supply a pre-obtained token (ideal for scheduled tasks or SDK integration).
  
- **Discovery Status Verification:**  
  - Retrieves key fields such as the discovery fetch start time, and whether a fetch or computer scan is running. STILL IN PROGRESS. Info Only ATM
  
- **Conditional Execution:**  
  - Prevents multiple scans by comparing the last scan start time with a configurable wait period.
  
- **Configurable Logging:**  
  - Toggle logging on/off and specify a custom log file location.
  

---

## ⚙️ Configuration

Before using the script, modify the following global variables within the script:

- **`$Global:SecretServerURL`**  
  Set this to your Secret Server base URL (e.g., `https://blt.secretservercloud.com`).

- **`$Global:LogPath`**  
  Define the path where log entries will be stored (e.g., `C:\temp\script.log`).

- **`$Global:DiscoveryWaitPeriodMinutes`**  
  Specify the wait period in minutes. If you prefer no waiting period, set this to `0` or leave it blank.

- **`$Global:LoggingEnabled`**  
  Set to `$true` to enable logging, or `$false` to disable it.

---

## 🚀 Usage

### Interactive Mode

Run the script in your PowerShell console. You’ll be prompted to enter your Secret Server credentials if no token is provided.

```powershell
.\Run-Discovery.ps1
```

Non-Interactive Mode - WORK IN PROGRESS
For scheduled tasks or automated environments, supply a pre-obtained token by setting the $preObtainedToken variable in the script.
Note: You should integrate your secure token retrieval process (e.g., via an SDK) to avoid clear-text credentials.

```powershell
$preObtainedToken = "<Your Pre-Obtained Token>"
```
The script then uses the token for authentication and proceeds to check the discovery status and start a scan if appropriate.

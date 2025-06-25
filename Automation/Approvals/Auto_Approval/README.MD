# Secret Server Auto Approval Script (v2)

This PowerShell script automates the approval of Secret Server access requests. It is designed for use in environments with **multiple execution nodes**, ensuring each request is only approved once, even if processed concurrently.

---

## 🔐 Authentication Modes

The script supports two authentication modes:

### 1. Interactive OAuth
- Prompts for username/password at runtime.
- Uses Secret Server's OAuth2 `password` grant flow.

### 2. SDK CLI
- Uses `tss.exe` CLI to generate an access token.
- Requires:
  - `-cd`: Path to SDK profile (`Config`)
  - `-kd`: Path to key file (`Key`) if the profile is encrypted

> SDK token example: `tss token -cd E:\SDK\Config -kd E:\SDK\Key`

---

## 🧠 Key Features

- Approves only eligible access requests
- Skips requests based on:
  - Excluded Ticket System ID
  - Maximum allowed access duration
- Supports paging through pending requests
- Handles concurrent node conflicts via:
  - **Fallback check** for already-approved requests
  - Tracks and logs `AlreadyApproved` requests instead of failing

---

## 📋 Configuration Parameters

```powershell
$BaseUrl             = "https://YOURURL.secretservercloud.com"
$ExcludedTicketSystemId = 3
$ApprovalReason      = "Approved via automation process"
$MaxAllowedMinutes   = 60
$PageSize            = 100
$EnableLogging       = $true
$EnableDebug         = $false
$LogFilePath         = "C:\Temp\AccessApprovalLog.txt"
$SdkProfilePath      = "E:\SDK\SDK_Profiles\ACCOUNTNAME\Config"
$SdkKeypath          = "E:\SDK\SDK_Profiles\ACCOUNTNAME\Key"
```

---

## 📁 Logging

Log file includes:
- Execution start/stop
- Requests approved, skipped, failed
- Fallback checks for already-approved requests
- Summary of run statistics

Example:
```
[INFO] Approved request ID 123 for duration 45 mins
[ERROR] Approval failed for request ID 124: Already processed.
[INFO] Request ID 124 was already approved by another node.
[INFO] Run Summary: Approved=15, Skipped=2, AlreadyApproved=3, Failed=1
```

---

## 🧪 Recommended Use

- Schedule this script to run every 2 minutes via Task Scheduler or cron.
- Use the same logging path across nodes to consolidate logs (optional).
- Ensure SDK profile is available on all nodes if using SDK auth.

---

## 🛡️ Notes

- This script uses `$script:` scoped variables for compatibility with PSScriptAnalyzer and to avoid global state conflicts.
- Requires PowerShell 5.1+ or PowerShell Core for REST API support.

---

## 🔄 Future Enhancements (Optional)

- CSV/email summary reporting
- Lock file or token-based run control for multi-node environments
- Token refresh support for long-running instances
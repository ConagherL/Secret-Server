🎩 Export CyberArk Accounts to CSV 🔐
🚀 This PowerShell script automates the retrieval of CyberArk accounts, filters them by a Safe, and exports the results to a CSV.
💡 Optional: Retrieve real passwords, replace them with fake ones, or exclude them entirely.

📌 Features
✅ Authentication: Prompts for CyberArk credentials and retrieves a session token.
✅ Account Retrieval: Fetches up to 500 accounts from CyberArk (adjustable).
✅ Filtering: Filters accounts by Safe name (local filtering).
✅ Password Handling: Optionally retrieves real passwords, generates fake passwords, or omits them.
✅ Logging: Logs operations (INFO, WARN, ERROR) to both the console and a log file.
✅ CSV Export: Saves filtered account data to a CSV file.

⚙️ Configuration Parameters
Parameter	Description
$ExportToFile	Export results to a CSV file ($true/$false)
$ExportPwdField	Include the password in the export ($true/$false)
$ExportFakePw	Replace real passwords with fake ones ($true/$false)
$CyberArkURL	CyberArk API base URL (https://TENANT.privilegecloud.cyberark.com)
$SafeName	The Safe name to filter accounts (case-sensitive)
$OutputFilePath	CSV file path for export (C:\temp\export.csv)
$OutputLogPath	Log file path (C:\temp\T_export.log)
$Reason	Justification for password retrieval
🔧 How It Works
1️⃣ Prompts for CyberArk credentials (username/password).
2️⃣ Authenticates to CyberArk via REST API.
3️⃣ Retrieves up to 500 accounts (adjustable limit).
4️⃣ Filters accounts by Safe name locally.
5️⃣ Retrieves additional account details (including notes and password if enabled).
6️⃣ Logs all operations to a log file and console.
7️⃣ Exports the data to a CSV file (if enabled).

🚀 Usage
🔹 Run the Script
```powershell
.\Export-CyberArkAccounts.ps1
🔹 Example Output in CSV
ID	Name	Address	UserName	PlatformID	SafeName	CreatedTime	Notes	Password
1234	Admin01	192.168.1.10	admin	WindowsLocal	SecureSafe	2024-01-30T14:00:00Z	Admin account	FakePw-x3jT4Wv9
5678	DBUser	db-server	dbadmin	MSSQL	SecureSafe	2024-02-01T10:15:00Z	Database user	FakePw-G9hQW7Xy
```
📜 Example Log Output
```plaintext
2024/02/03 12:00:00 [INFO] - Starting data retrieval from CyberArk
2024/02/03 12:00:05 [INFO] - Authentication successful
2024/02/03 12:00:10 [INFO] - Retrieved 200 accounts without filtering
2024/02/03 12:00:15 [INFO] - Retrieved 50 accounts from safe 'SecureSafe'
2024/02/03 12:00:20 [INFO] - Processing account ID: 1234 - Admin01
2024/02/03 12:00:25 [WARN] - Failed to retrieve extended details for ID: 5678
2024/02/03 12:00:30 [INFO] - Successfully retrieved password for Account ID: 1234
2024/02/03 12:00:35 [INFO] - Exported data to C:\temp\export.csv
2024/02/03 12:00:40 [INFO] - Data retrieval from CyberArk completed
```
⚠️ Requirements
🔹 PowerShell 7+ (for UnixTimeseconds option in Get-Date)
🔹 CyberArk REST API Access (with permission to retrieve accounts)
🔹 Network connectivity to CyberArkURL

🏗 Customization
You can modify the following:
```plaintext
Increase account retrieval limit by adjusting $AllAccountsURI limit.
Change logging behavior (Write-Log function).
Modify password retrieval rules ($ExportPwdField and $ExportFakePw).
```
💡 Future Enhancements
📌 Multi-threading for faster execution
📌 Enhanced error handling
📌 Support for additional API endpoints
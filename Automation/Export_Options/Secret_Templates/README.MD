# Secret Server Template Exporter/Importer 🚀

This PowerShell script automates retrieving **Secret Server** templates and exporting them into structured CSV files. It also includes formatting into a XML (separating folders from Secrets) It supports:
- ✅ Authenticating to **Secret Server** via OAuth2
- ✅ Retrieving **all secret templates**, including their field details (names, types, required status)
- ✅ Ensuring proper field order (Secret Name first, Folder Path last)
- ✅ Skipping CSV updates for **unchanged templates**
- ✅ Generating new CSV files for **new templates**
- ✅ Convert CSV data to XML for Secret Import
- ✅ Convert CSV data to XML for Folder Creation
- ✅ Logging **all operations** for visibility and debugging

## 📌 Features
- **⚡ Automated Secret Server export process**
- **🎯 Works with PowerShell 7+ (recommended)**
- **📝 CSV format is structured for direct import into Secret Server**
- **🔍 Dynamic field detection (supports new/updated templates)**
- **🔄 Smart CSV updates (only modifies changed templates)**
- **📂 Organizes CSV exports in designated folders**

---

## 📥 **Installation & Requirements**
### ✅ **PowerShell Version**
- **PowerShell 7+** (Recommended)
- **PowerShell 5.1** (Limited support) - Some updated output will not render correctly

### ✅ **Prerequisites**
- **Internet access** (for API requests)
- **Valid Secret Server credentials** (Username & Password)
- **API access to retrieve secret templates**


---

## 🚀 Usage Examples

1️⃣ Authenticate to Secret Server
```powershell
Connect-SecretServer -SecretServerUrl "https://yourserver.com" -OauthUrl "https://yourserver.com/oauth2/token"
```
2️⃣ Initialize required output folders
```powershell
Initialize-SecretTemplateFolders -CsvDir "C:\temp\CSV_Files" -XmlDir "C:\temp\XML_Files"
```
3️⃣ Retrieve all secret templates and fields
```powershell
Get-AllSecretTemplates -SecretServerUrl "https://yourserver.com" -OutputPath "C:\temp\SecretTemplates.json"
```
4️⃣ Export Secret Templates to CSV
```powershell
Export-SecretTemplatesToCSV -JsonFilePath "C:\temp\SecretTemplates.json" -CsvDir "C:\temp\CSV_Files"
```
5️⃣ Convert Secret CSVs to XML for Import
```powershell
Convert-CSVToXML
```
6️⃣ Generate Folder Structure XML for Import
```powershell
Convert-FoldersToXML
```
7️⃣ Run all steps automatically (Recommended)
```powershell
Invoke-FullExport
```


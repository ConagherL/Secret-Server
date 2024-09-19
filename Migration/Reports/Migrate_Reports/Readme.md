Secret Server Report Migration Script
Overview
This PowerShell script automates the migration of reports from a source Secret Server tenant to a destination tenant. It handles the migration of report categories and reports, ensuring that no duplicates are created in the destination tenant. The script includes robust logging and error handling to facilitate a smooth migration process.

Features
Authentication: Securely authenticates with both the source and destination tenants using OAuth2.
Category Migration: Migrates report categories, creating any that do not exist in the destination tenant.
Report Migration: Migrates reports, mapping them to the appropriate categories in the destination tenant.
Selective Processing: Allows the user to select specific categories and reports to migrate or choose to migrate all.
Logging: Logs all actions and errors to a log file for easy troubleshooting.
Error Handling: Captures and logs errors, including API responses, to assist with debugging.
Prerequisites
PowerShell: Ensure you are running PowerShell 5.1 or later.
Network Access: The script must be able to reach the source and destination Secret Server tenants over the network.
Credentials: User accounts with appropriate permissions to read reports from the source tenant and create reports in the destination tenant.
Getting Started
1. Clone or Download the Repository
bash
Copy code
git clone https://github.com/yourusername/SecretServerReportMigration.git
2. Update Script Variables
Open the MigrateReports.ps1 script in a text editor and update the following variables at the top of the script:

powershell
Copy code
$sourceRootUrl = 'source.secretservercloud.com'       # Source tenant root URL
$destinationRootUrl = 'destination.secretservercloud.com'  # Destination tenant root URL
$outputDirectory = 'C:\temp\SQL_Reports'  # Directory for saving report details and logs
$sourceRootUrl: Replace with your source tenant's root URL.
$destinationRootUrl: Replace with your destination tenant's root URL.
$outputDirectory: (Optional) Specify the directory where you want to save report JSON files and logs.
3. Run the Script
Open PowerShell with appropriate permissions and navigate to the directory containing the script.

powershell
Copy code
cd path\to\SecretServerReportMigration
.\MigrateReports.ps1
4. Follow the Prompts
Authentication: When prompted, enter your credentials for both the source and destination tenants.
Category Processing: Choose whether to process specific categories or all categories.
Report Processing: Choose whether to process specific reports or all reports.
5. Review the Output
Logs: The script outputs progress to the console and logs detailed information to Migration_Log.txt in the specified output directory.
JSON Files: Report details are saved as JSON files in the output directory for reference or auditing purposes.
6. Clean Up (Optional)
After the migration, the script will prompt you to delete the JSON files saved in the output directory. Choose 'Y' to delete them or any other key to keep them.

Functions Overview
Log-Message
Logs messages to both the console and a log file.

Parameters:
Message: The message to log.
Color: (Optional) The color of the console text.
Authenticate-Tenant
Authenticates with a tenant and obtains an access token.

Parameters:
tenantName: A friendly name for the tenant (e.g., 'source' or 'destination').
tokenUrl: The OAuth2 token URL for the tenant.
Returns:
A hashtable containing headers with the access token and username.
Get-Categories
Fetches all report categories from a tenant.

Parameters:
apiUrl: The API base URL for the tenant.
headers: The headers containing the access token.
Create-Category
Creates a report category in the destination tenant.

Parameters:
apiUrl: The API base URL for the destination tenant.
headers: The headers containing the access token.
sourceCategory: The category object from the source tenant.
Process-Categories
Processes categories by ensuring all source categories exist in the destination tenant.

Parameters:
apiSource: The API base URL for the source tenant.
apiDestination: The API base URL for the destination tenant.
headersSource: The headers containing the access token for the source tenant.
headersDestination: The headers containing the access token for the destination tenant.
categoryIds: An array of category IDs to process (empty array for all categories).
Returns:
A hashtable mapping source category IDs to destination category IDs.
Get-AllReports
Fetches all reports from a tenant.

Parameters:
apiUrl: The API base URL for the tenant.
headers: The headers containing the access token.
Get-ReportDetails
Fetches detailed information about a specific report.

Parameters:
apiUrl: The API base URL for the tenant.
headers: The headers containing the access token.
reportId: The ID of the report.
Save-ReportToFile
Saves report details to a JSON file.

Parameters:
reportDetails: The report details object.
reportId: The ID of the report.
Create-Report
Creates a report in the destination tenant.

Parameters:
apiUrl: The API base URL for the destination tenant.
headers: The headers containing the access token.
reportData: The report data to be created.
Process-Reports
Processes reports by migrating them from the source to the destination tenant.

Parameters:
apiSource: The API base URL for the source tenant.
apiDestination: The API base URL for the destination tenant.
headersSource: The headers containing the access token for the source tenant.
headersDestination: The headers containing the access token for the destination tenant.
categoryIds: An array of category IDs to process.
categoryIdMap: A hashtable mapping source category IDs to destination category IDs.
reportIds: An array of report IDs to process.
Important Notes
Permissions: Ensure that the accounts you use have the necessary permissions to read reports from the source tenant and create reports in the destination tenant.
Testing: Before running the script in a production environment, consider testing it in a development or staging environment.
Error Handling: The script includes error handling to capture and log any issues during execution. Review the log file for detailed error messages if any problems occur.
Contributing
Contributions are welcome! Please submit a pull request or open an issue to discuss any changes or enhancements.

License
This project is licensed under the MIT License - see the LICENSE file for details.

Contact
For questions or support, please contact your.email@example.com.
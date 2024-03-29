```markdown

# Delinea Secret Server Inactive Secrets Report/Action

This PowerShell script is designed to manage secret deactivation and owner notification in Delinea Secret Server. It establishes a session with the server, invokes a specified report, deactivates secrets based on the report data, and sends notifications to the secret owners.

## Configuration

Before running the script, ensure the following variables are set according to your environment:

$Global:YourServerURL = "https://XXXX.DOMAIN.COM"  # Your Secret Server URL
$Global:ReportID = "148"                          # The Report ID to invoke
$Global:ExportPath = "C:\temp\Export"             # Path to export results
$Global:SmtpServer = "smtp.XXXXXXX.com"           # Your SMTP server
$Global:FromAddress = "ITAdmins@XXXX.com"         # Email address for notifications
```
##Prerequisites
- This code is dependent on the Thycotic Secret Server PowerShell Module. Please review any additional requirements [HERE](https://thycotic-ps.github.io/thycotic.secretserver/getting_started/install.html)
- PowerShell 7.1 or higher.
- SQL Database Compatibility Level = 140
- Requires "Administer Reports" permissions in SS
- API account used must have access to all secrets within scope (Owner Rights)
-   Optionally, if you want a "report" only mode, then the API account must have "View" rights
-   If you would like to run this through a controlled test, utilize the TEST-Secrets not viewed in 90 days report and specify on line 49 the IDs of secrets you would like to target

## Usage
Load the Thycotic Secret Server Module

Please make sure the Thycotic Secret Server module is loaded. If not, the script will terminate with an error message.

## Establish a Session

The script will prompt for credentials to establish a new session with the Secret Server.

## Invoke the Report

Use the Invoke-Report function to invoke a specified report from the Secret Server. User must have role permissions to reports.

```powershell
Invoke-Report
```

## Deactivate Secrets

The Invoke-Deactivate-Secrets function deactivates the secrets listed in the report and exports the results. Execution must be by a user with "Owner" rights

```powershell
Invoke-Deactivate-Secrets
```

## TEST - Notify Secret Owners

Generates notifications for secret owners regarding scheduled secret deactivation events. Notifications can be sent via email or exported to a CSV file.

```powershell
Test-Notify-SecretOwners -EmailOutput
```
```powershell
Test-Notify-SecretOwners
```

## Send-EmailtoSecretOwners

Notifies secret owners via email about scheduled secret deactivation events. One email is sent with a summary of secrets.

```powershell
Send-EmailtoSecretOwners
```

## Send Secure Mail

The Send-SecureMail function is used internally by the script to send emails. It can also be used standalone for testing email functionality.

```powershell
Send-SecureMail -To "recipient@example.com" -From $Global:FromAddress -Subject "Test Email" -Body "This is a test email." -SmtpServer $Global:SmtpServer
```

## Send-SecureMail-ToFile

Saves an email message to a specified folder in EML format.

```powershell
Send-SecureMail-ToFile -To "recipient@example.com" -From "sender@example.com" -Subject "Test Email" -Body "This is a test email message."
```

## Notes
- Ensure all global variables are set correctly before running the script.
- The script relies on the Thycotic.SecretServer PowerShell module; ensure it's installed and accessible.
- Test the script in a controlled environment before using it in production.

## Contributing

Contributions to this script are welcome. Please fork the repository and submit a pull request with your changes.

## License
This script is provided "as is", without warranty of any kind. Use it at your own risk.

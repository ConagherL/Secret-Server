```markdown

# Thycotic Secret Server Script

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

## Usage
Load the Thycotic Secret Server Module

Ensure the Thycotic Secret Server module is loaded. If not, the script will terminate with an error message.

## Establish a Session

The script will prompt for credentials to establish a new session with the Secret Server.

## Invoke the Report

Use the Invoke-Report function to invoke a specified report from the Secret Server.

```powershell
Invoke-Report
```
## Deactivate Secrets

The InvokeAndDeactivateSecrets function deactivates secrets listed in the report and exports the results.

```powershell
InvokeAndDeactivateSecrets
```

## Notify Secret Owners

Notify-SecretOwners sends notification emails to the owners of the secrets being deactivated.

```powershell
Notify-SecretOwners
```

## Send Secure Mail

The Send-SecureMail function is used internally by the script to send emails. It can also be used standalone for testing email functionality.

```powershell
Send-SecureMail -To "recipient@example.com" -From $Global:FromAddress -Subject "Test Email" -Body "This is a test email." -SmtpServer $Global:SmtpServer
```
## Notes
- Ensure all global variables are set correctly before running the script.
- The script relies on the Thycotic.SecretServer PowerShell module; ensure it's installed and accessible.
- Test the script in a controlled environment before using it in production.

## Contributing

Contributions to this script are welcome. Please fork the repository and submit a pull request with your changes.

## License
This script is provided "as is", without warranty of any kind. Use it at your own risk.

# Configuration Variables
$Global:YourServerURL = "https://XXXX.DOMAIN.COM"  # Replace with your actual Secret Server URL
$Global:ReportID = "148"                                     # Replace with your actual Report ID
$Global:ExportPath = "C:\temp\Export"                        # Replace with your desired export path
$Global:SmtpServer = "smtp.XXXXXXX.com"              # Replace with your SMTP server
$Global:FromAddress = "ITAdmins@XXXX.com"                     # Replace with your from email address

<#
.SYNOPSIS
This script interacts with Delinea Secret Server to manage secrets and notify secret owners about scheduled deactivation events.

.DESCRIPTION
The script contains several functions to interact with Delinea Secret Server. It first ensures that the Thycotic Secret Server module is loaded and establishes a session with the server using provided credentials. The main functions include:
1. Invoke-Report: Invokes a specified report from Delinea Secret Server and returns the report data.
2. InvokeAndDeactivateSecrets: Deactivates secrets based on a specified report and exports the results.
3. Test-Notify-SecretOwners: Generates notifications for secret owners regarding scheduled secret deactivation events. Notifications can be sent via email or exported to a CSV file.
4. Send-EmailtoSecretOwners: Notifies secret owners via email about scheduled secret deactivation events.
5. Send-SecureMail: Sends an email using specified SMTP settings.
6. Send-SecureMail-ToFile: Saves an email message to a specified folder in EML format.

.PARAMETER None
This script does not accept any parameters.

.NOTES
- The script requires the Thycotic Secret Server module to be installed.
- Global variables such as $Global:session, $Global:ReportID, and $Global:ExportPath need to be set before invoking certain functions.
- Error handling is implemented to manage exceptions during script execution.
#>

# Ensure the Thycotic Secret Server module is loaded
if (-not (Get-Module -ListAvailable -Name Thycotic.SecretServer)) {
    Write-Error "Thycotic.SecretServer module is not installed. Please install it to proceed."
    return                        
}
Import-Module Thycotic.SecretServer

# Prompt for credentials and establish a new session with the Secret Server
try {
    $Global:session = New-TssSession -SecretServer $Global:YourServerURL -Credential (Get-Credential)
    if (-not $Global:session) {
        Write-Error "Failed to establish a session with the Secret Server."
        return
    }
} catch {
    Write-Error "An error occurred while trying to establish a session: $_"
    return
}

# Output the session object to verify
Write-Output $Global:session

<#
.SYNOPSIS
Invokes a specified report from Delinea Secret Server.

.DESCRIPTION
This function uses global variables to invoke a report from Delinea Secret Server and returns the report data.

.EXAMPLE
Invoke-Report

This example invokes a report using the global session and ReportID variables.

.NOTES
Relies on $Global:session and $Global:ReportID being set prior to invocation.
#>
function Invoke-Report {
    Write-Host "Checking session validity..." -ForegroundColor Cyan
    if (-not $Global:session -or $Global:session.Expired) {
        Write-Host "Session is not valid or has expired. Please re-establish the session." -ForegroundColor Red
        return
    }

    Write-Host "Checking ReportID..." -ForegroundColor Cyan
    if (-not $Global:ReportID) {
        Write-Host "ReportID is not set. Please specify a valid ReportID." -ForegroundColor Red
        return
    }

    Write-Host "Invoking report with ID: $Global:ReportID" -ForegroundColor Cyan
    try {
        $reportData = Invoke-TssReport -TssSession $Global:session -Id $Global:ReportID
        Write-Host "Report invoked successfully." -ForegroundColor Green
        return $reportData
    } catch {
        Write-Host "An error occurred while invoking the report: $_" -ForegroundColor Red
    }
}

<#
.SYNOPSIS
Deactivates secrets based on a specified report and exports the results.

.DESCRIPTION
This function deactivates secrets listed in a Delinea Secret Server report and exports the deactivation results to a CSV file.

.EXAMPLE
InvokeAndDeactivateSecrets

This example deactivates secrets based on the report specified by $Global:ReportID and exports the results to the path specified by $Global:ExportPath.

.NOTES
Relies on $Global:session, $Global:ReportID, and $Global:ExportPath being set prior to invocation.
#>
function InvokeAndDeactivateSecrets {
    $results = @()

    Write-Host "Checking session validity..." -ForegroundColor Cyan
    if (-not $Global:session -or $Global:session.Expired) {
        Write-Host "Session is not valid or has expired. Please re-establish the session." -ForegroundColor Red
        return
    }

    Write-Host "Checking ReportID..." -ForegroundColor Cyan
    if (-not $Global:ReportID) {
        Write-Host "ReportID is not set. Please specify a valid ReportID." -ForegroundColor Red
        return
    }

    Write-Host "Invoking report and fetching data..." -ForegroundColor Cyan
    try {
        $reportData = Invoke-TssReport -TssSession $Global:session -Id $Global:ReportID
        if (-not $reportData) {
            Write-Host "No data returned from the report. Please check the ReportID and ensure it returns data." -ForegroundColor Red
            return
        }
    } catch {
        Write-Host "An error occurred while invoking the report: $_" -ForegroundColor Red
        return
    }

    Write-Host "Processing report data..." -ForegroundColor Cyan
    foreach ($secret in $reportData) {
        try {
            Remove-TssSecret -TssSession $Global:session -Id $secret.SecretId -Confirm:$false

            $result = [PSCustomObject]@{
                ID     = $secret.SecretId
                Name   = $secret.'Secret Name'
                Action = "Deactivated"
            }
            $results += $result

            Write-Host "Secret $($secret.SecretId) deactivated successfully." -ForegroundColor Green
        } catch {
            Write-Host "Failed to deactivate secret $($secret.SecretId): $_" -ForegroundColor Red

            $result = [PSCustomObject]@{
                ID     = $secret.SecretId
                Name   = $secret.'Secret Name'
                Action = "Failed to Deactivate"
            }
            $results += $result
        }
    }

    $csvPath = Join-Path -Path $Global:ExportPath -ChildPath "DeactivationResults.csv"
    $results | Export-Csv -Path $csvPath -NoTypeInformation

    Write-Host "Results exported to $csvPath" -ForegroundColor Green
}

<#
.SYNOPSIS
Test-Notify-SecretOwners function generates notifications for secret owners regarding scheduled secret deactivation events.

.DESCRIPTION
This PowerShell function simulates the notification process for secret owners about scheduled secret deactivation events. It retrieves report data and processes it to generate notifications. Depending on the presence of the -EmailOutput switch, notifications are either sent via email or exported to a CSV file.

.PARAMETER EmailOutput
Specifies whether to send notifications via email. If this switch is present, notifications are sent via email; otherwise, notifications are exported to a CSV file.

.EXAMPLE
Test-Notify-SecretOwners -EmailOutput

This example triggers the function to generate notifications for secret owners via email. These are exported as a .EML file.

.EXAMPLE
Test-Notify-SecretOwners

This example triggers the function to generate notifications for secret owners and export them to a CSV file.

.NOTES
- The function relies on the Invoke-Report function to fetch the latest report data.
- Each secret owner receives a notification detailing the secrets scheduled for deactivation.
- Notification content is formatted in HTML for readability.
- Secret owner email addresses and secret details are extracted from the report data.
- The Send-SecureMail-ToFile function is utilized for sending emails.
- Error handling is implemented to handle any failures during notification generation or export to CSV.
#>
function Test-Notify-SecretOwners {
    param (
        [switch]$EmailOutput
    )

    Write-Host "Fetching new report data for test..." -ForegroundColor Cyan
    $Global:reportData = Invoke-Report

    if (-not $Global:reportData) {
        Write-Host "Failed to fetch report data." -ForegroundColor Red
        return
    }

    Write-Host "Report data retrieved successfully. Processing notifications..." -ForegroundColor Green

    $ownersEmailData = @{}

    foreach ($secret in $Global:reportData) {
        $emailAddresses = $secret.EmailAddresses -split ','  
        $secretName = $secret.'Secret Name'
        
        foreach ($emailAddress in $emailAddresses) {
            $emailAddress = $emailAddress.Trim()
            if ($emailAddress) {
                if (-not $ownersEmailData.ContainsKey($emailAddress)) {
                    $ownersEmailData[$emailAddress] = @()
                }
                $uniqueSecretKey = "$($secret.secretid):$($secretName)"
                if (-not $ownersEmailData[$emailAddress].Contains($uniqueSecretKey)) {
                    $ownersEmailData[$emailAddress] += $uniqueSecretKey
                }
            } else {
                Write-Host "Invalid email address found for Secret: $secretName" -ForegroundColor Yellow
            }
        }
    }

    # If the -EmailOutput switch is used, send the notifications by email
    if ($EmailOutput) {
        foreach ($emailAddress in $ownersEmailData.Keys) {
            $emailBody = @"
<html>
<body>
Dear Secret Owner,<br><br>

Please review the following details for the secrets scheduled for deactivation:<br><br>

<table border="1">
<tr><th>Secret Name</th><th>ID</th><th>Folder Path</th><th>Secret Template</th><th>Days Since Last Accessed</th></tr>
"@

            foreach ($secretKey in $ownersEmailData[$emailAddress]) {
                $secretData = $secretKey -split ":"
                $secretID = $secretData[0]
                $secretName = $secretData[1]
                $emailBody += "<tr><td>$secretName</td><td>$secretID</td><td>$($secret.'Folder Path')</td><td>$($secret.'Secret Template')</td><td>$($secret.'Days Since Last View')</td></tr>"
            }

            $emailBody += @"
</table><br><br>

Best regards,<br>
Your IT Team
</body>
</html>
"@

            try {
                Write-Host "Preparing email for $emailAddress" -ForegroundColor Magenta
                Send-SecureMail-ToFile -To $emailAddress -From "sender@example.com" -Subject "Secret Deactivation Notification" -Body $emailBody
                Write-Host "Email content prepared for $emailAddress" -ForegroundColor Green
            } catch {
                Write-Host "Failed to prepare email content for $emailAddress" -ForegroundColor Red
            }
        }
    } else {
        # Export to CSV file
        $outputPath = Join-Path -Path $Global:ExportPath -ChildPath "SecretOwnersNotifications.csv"
        $notifications = @()

        foreach ($emailAddress in $ownersEmailData.Keys) {
            foreach ($secretKey in $ownersEmailData[$emailAddress]) {
                $secretData = $secretKey -split ":"
                $secretID = $secretData[0]
                $secretName = $secretData[1]
                $notification = [PSCustomObject]@{
                    'Owner Email' = $emailAddress
                    'Secret Name' = $secretName
                }
                $notifications += $notification
            }
        }

        $notifications | Export-Csv -Path $outputPath -NoTypeInformation

        # Append a summary with the actual count of unique secrets per owner to the end of the CSV
        Add-Content -Path $outputPath -Value "`nEmail Notification Summary:"
        Add-Content -Path $outputPath -Value "Owner Email, Total Secret"
        foreach ($email in $ownersEmailData.Keys) {
            # The count of unique secrets per owner is the length of the array in each hashtable entry
            $uniqueSecretsCount = $ownersEmailData[$email].Count
            Add-Content -Path $outputPath -Value "$email, $uniqueSecretsCount"
        }

        Write-Host "All notifications and summary exported to $outputPath" -ForegroundColor Green
    }
}

<#
.SYNOPSIS
Send-EmailtoSecretOwners function notifies secret owners via email about scheduled secret deactivation.

.DESCRIPTION
This PowerShell function ensures secret owners are informed promptly about upcoming secret deactivation events. It first validates the session and retrieves the latest report data. Then, it processes the data to generate personalized email notifications for each secret owner, detailing the secrets scheduled for deactivation.

.PARAMETER None
This function does not accept any parameters.

.EXAMPLE
Send-EmailtoSecretOwners

This example sends notifications to secret owners based on the report specified by $Global:ReportID, using the SMTP settings defined in the global variables.

.NOTES
- The session's validity is checked before proceeding.
- Invoke-Report function is used to fetch the latest report data.
- Each secret owner receives a personalized email listing their relevant secrets.
- Email content is formatted in HTML for readability.
- The Send-SecureMail function is utilized for sending emails.
#>
function Send-EmailtoSecretOwners {
    Write-Host "Checking session validity..." -ForegroundColor Cyan
    if (-not $Global:session -or $Global:session.Expired) {
        Write-Host "Session is not valid or has expired. Please re-establish the session." -ForegroundColor Red
        return
    }

    Write-Host "Clearing existing report data..." -ForegroundColor Cyan
    $Global:reportData = $null

    Write-Host "Fetching new report data..." -ForegroundColor Cyan
    $Global:reportData = Invoke-Report

    Write-Host "Report data retrieved successfully. Notifying secret owners..." -ForegroundColor Green

    $ownersEmailData = @{}

    foreach ($secret in $Global:reportData) {
        $emailAddresses = $secret.EmailAddresses -split ',' | ForEach-Object { $_.Trim().ToLower() } | Select-Object -Unique
        $uniqueSecretKey = "$($secret.secretid):$($secret.'Secret Name')"

        foreach ($emailAddress in $emailAddresses) {
            if (-not $ownersEmailData.ContainsKey($emailAddress)) {
                $ownersEmailData[$emailAddress] = @{}
            }
            if (-not $ownersEmailData[$emailAddress].ContainsKey($uniqueSecretKey)) {
                $ownersEmailData[$emailAddress][$uniqueSecretKey] = "<tr><td>$($secret.'Secret Name')</td><td>$($secret.secretid)</td><td>$($secret.'Folder Path')</td><td>$($secret.'Secret Template')</td><td>$($secret.'Days Since Last View')</td></tr>"
            }
        }
    }

    foreach ($emailAddress in $ownersEmailData.Keys) {
        $emailBody = @"
<html>
<body>
Dear Secret Owner,<br><br>

Please review the following details for the secrets scheduled for deactivation:<br><br>

<table border="1">
<tr><th>Secret Name</th><th>ID</th><th>Folder Path</th><th>Secret Template</th><th>Days Since Last Accessed</th></tr>
"@

        foreach ($secretKey in $ownersEmailData[$emailAddress].Keys) {
            $emailBody += $ownersEmailData[$emailAddress][$secretKey]
        }

        $emailBody += @"
</table><br><br>

Best regards,<br>
Your IT Team
</body>
</html>
"@

        try {
            Write-Host "Preparing email for $emailAddress" -ForegroundColor Magenta
            Send-SecureMail -To $emailAddress -From $Global:FromAddress -Subject "Secret Deactivation Notification" -Body $emailBody -SmtpServer $Global:SmtpServer
            Write-Host "Email content prepared for $emailAddress" -ForegroundColor Green
        } catch {
            Write-Host "Failed to prepare email content for $emailAddress" -ForegroundColor Red
        }
    }
}

<#
.SYNOPSIS
Sends an email using specified SMTP settings.

.DESCRIPTION
The Send-SecureMail function sends an email message to the specified recipient using the .NET System.Net.Mail functionality. It allows specifying the sender, recipient, subject, body, and the SMTP server to use for sending the email. The function is designed for non-SSL SMTP connections by default.

.PARAMETER To
The email address of the recipient.

.PARAMETER From
The email address of the sender.

.PARAMETER Subject
The subject line of the email message.

.PARAMETER Body
The body content of the email message.

.PARAMETER SmtpServer
The hostname or IP address of the SMTP server used to send the email.

.EXAMPLE
Send-SecureMail -To 'recipient@example.com' -From 'sender@example.com' -Subject 'Test Email' -Body 'This is a test email.' -SmtpServer 'smtp.example.com'

This example sends a simple email from 'sender@example.com' to 'recipient@example.com' with the subject 'Test Email' and a body of 'This is a test email.' using 'smtp.example.com' as the SMTP server.

.NOTES
Ensure that the SMTP server specified is accessible and allows non-SSL connections on port 25. Adjust the SMTP client configuration as necessary for your environment.
#>
function Send-SecureMail {
    param (
        [string]$To,
        [string]$From,
        [string]$Subject,
        [string]$Body,
        [string]$SmtpServer
    )

    $mailMessage = New-Object System.Net.Mail.MailMessage
    $mailMessage.From = $From
    $mailMessage.To.Add($To)
    $mailMessage.Subject = $Subject
    $mailMessage.Body = $Body

    $smtpClient = New-Object Net.Mail.SmtpClient($SmtpServer, 25)  # Assuming port 25 for non-SSL
    $smtpClient.EnableSsl = $false  # Disable SSL for open SMTP relay

    try {
        $smtpClient.Send($mailMessage)
    } catch {
        Write-Host "Failed to send email: $_" -ForegroundColor Red
    } finally {
        $mailMessage.Dispose()
        $smtpClient.Dispose()
    }
}

<#
.SYNOPSIS
Send-SecureMail-ToFile function saves an email message to a specified folder in EML format.

.DESCRIPTION
This PowerShell function enables users to securely store or archive email messages by saving them to a specified folder in EML format.

.PARAMETER To
Specifies the recipient's email address.

.PARAMETER From
Specifies the sender's email address.

.PARAMETER Subject
Specifies the subject of the email.

.PARAMETER Body
Specifies the body content of the email.

.EXAMPLE
Send-SecureMail-ToFile -To "recipient@example.com" -From "sender@example.com" -Subject "Test Email" -Body "This is a test email message."

This example saves a test email message to a file in the specified folder.

.NOTES
- Ensure that the `$Global:ExportPath` variable is set to the desired folder path before invoking this function.
- This function is designed for saving emails to files only. It does not handle sending emails via SMTP.
#>
function Send-SecureMail-ToFile {
    param (
        [string]$To,
        [string]$From,
        [string]$Subject,
        [string]$Body
    )

    # Hardcoded folder path to save the email contents
    $SaveFolder = $Global:ExportPath

    # Include Content-Type header to indicate HTML content
    $emailContent = @"
From: $From
To: $To
Subject: $Subject
Content-Type: text/html; charset=UTF-8

$Body
"@

    try {
        # Use the $To parameter to create a unique filename for each recipient
        $fileName = $To -replace '[\\\/:\*\?"<>\|]', '_'  # Remove illegal characters for filenames
        $filePath = Join-Path $SaveFolder "$fileName.eml"

        # Save the email contents to a file
        $emailContent | Out-File -FilePath $filePath -Encoding UTF8

        Write-Host "Email saved to $filePath" -ForegroundColor Green
    } catch {
        Write-Host "Failed to save email: $_" -ForegroundColor Red
    }
}
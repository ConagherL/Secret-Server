# Configuration Variables
$Global:YourServerURL = "https://XXXX.DOMAIN.COM"  # Replace with your actual Secret Server URL
$Global:ReportID = "148"                                     # Replace with your actual Report ID
$Global:ExportPath = "C:\temp\Export"                        # Replace with your desired export path
$Global:SmtpServer = "smtp.XXXXXXX.com"              # Replace with your SMTP server
$Global:FromAddress = "ITAdmins@XXXX.com"                     # Replace with your from email address

<#
.SYNOPSIS
This script manages secret deactivation and owner notification in Delinea Secret Server.

.DESCRIPTION
The script establishes a session with Thycotic Secret Server, invokes a specified report, deactivates secrets based on the report data, and sends notifications to the secret owners. It uses predefined global variables for configuration.

.EXAMPLE
# Run the script
.\Report_And_Deactivate_Secrets_with_Notification_For_Owners.ps1

This will invoke the specified report, deactivate the secrets, and notify the owners as per the configurations set in the global variables.

.NOTES
Ensure the Thycotic.SecretServer PowerShell module is installed and accessible before running this script.
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
Aggregates secret ownership information and prepares a notification summary for each owner.

.DESCRIPTION
The Test-Notify-SecretOwners function fetches report data, aggregates secrets by owner, and prepares a CSV file with detailed secret information for each owner. It ensures each owner is notified once with a summary of all their secrets, improving the efficiency of communication.

.PARAMETER Global:ExportPath
Specifies the path where the notification summary CSV will be exported.

.PARAMETER Global:reportData
Contains the report data used to prepare notifications. This data should include secret names and owner email addresses.

.EXAMPLE
Test-Notify-SecretOwners

This example runs the function using the report data stored in $Global:reportData and exports the notification summary to the path specified in $Global:ExportPath.

.NOTES
Ensure the report data is available in $Global:reportData before running this function. The function requires the Thycotic.SecretServer PowerShell module to interact with the Secret Server for report data fetching.
#>
function Test-Notify-SecretOwners {
    $outputPath = Join-Path -Path $Global:ExportPath -ChildPath "SecretOwnersNotifications.csv"
    $notifications = @()
    $emailCount = @{}

    Write-Host "Fetching new report data for test..." -ForegroundColor Cyan
    $Global:reportData = Invoke-Report

    Write-Host "Report data retrieved successfully. Preparing notifications for CSV export..." -ForegroundColor Green
    foreach ($secret in $Global:reportData) {
        $emailAddresses = $secret.EmailAddresses -split ','  
        $secretName = $secret.'Secret Name'
        
        if (-not $secretName) {
            Write-Host "Secret Name is missing for Secret ID: $($secret.secretid)" -ForegroundColor Yellow
            continue
        }

        foreach ($emailAddress in $emailAddresses) {
            $emailAddress = $emailAddress.Trim()
            if ($emailAddress -and -not $emailCount.ContainsKey($emailAddress)) {
                # Initialize aggregation for the owner if it doesn't exist
                $emailCount[$emailAddress] = @()
            }
            if ($emailAddress) {
                # Add secret to the owner's aggregation
                $emailCount[$emailAddress] += $secretName

                Write-Host "Aggregated Secret: $secretName for owner at $emailAddress" -ForegroundColor Magenta
            } else {
                Write-Host "Invalid email address found for Secret: $secretName" -ForegroundColor Yellow
            }
        }
    }

    # Prepare notifications with aggregated information for each owner
    foreach ($emailAddress in $emailCount.Keys) {
        foreach ($secretName in $emailCount[$emailAddress]) {
            $notification = [PSCustomObject]@{
                SecretName  = $secretName
                OwnerEmail  = $emailAddress
            }
            $notifications += $notification
        }
    }

    # Export the notification details to CSV
    $notifications | Export-Csv -Path $outputPath -NoTypeInformation

    # Append a summary with the actual count of unique secrets per owner to the end of the CSV
    Add-Content -Path $outputPath -Value "`nEmail Notification Summary:"
    foreach ($email in $emailCount.Keys) {
        # The count of unique secrets per owner is the length of the array in each hashtable entry
        $uniqueSecretsCount = $emailCount[$email].Count
        Add-Content -Path $outputPath -Value "$email, $uniqueSecretsCount"
    }

    Write-Host "All notifications and summary exported to $outputPath" -ForegroundColor Green
}

<#
.SYNOPSIS
Notifies the owners of secrets about the pending deactivation.

.DESCRIPTION
This function sends notification emails to the owners of secrets listed in the specified report, indicating the deactivation of their secrets. If a users email is listed multiple times, then we only email once

.EXAMPLE
Send-EmailtoSecretOwners

This example sends notifications to secret owners based on the report specified by $Global:ReportID, using the SMTP settings defined in the global variables.

.NOTES
Relies on $Global:session, $Global:ReportID, $Global:SmtpServer, and $Global:FromAddress being set prior to invocation.
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
        $emailAddresses = $secret.EmailAddresses -split ','  
        $secretInfo = "Secret Name: $($secret.'Secret Name') | ID: $($secret.ID) | Folder Path: $($secret.'Folder Path') | Secret Template: $($secret.'Secret Template') | Days Since Last Accessed: $($secret.'Day Since last Accessed')"

        foreach ($emailAddress in $emailAddresses) {
            $emailAddress = $emailAddress.Trim()
            if ($emailAddress) {
                if (-not $ownersEmailData.ContainsKey($emailAddress)) {
                    $ownersEmailData[$emailAddress] = @()
                }
                $ownersEmailData[$emailAddress] += $secretInfo
            } else {
                Write-Host "Invalid email address found for Secret: $($secret.'Secret Name')" -ForegroundColor Yellow
            }
        }
    }

    foreach ($emailAddress in $ownersEmailData.Keys) {
        $emailBody = @"
Dear Secret Owner,

Please review the following details for the secrets scheduled for deactivation:

Secret Name | ID | Folder Path | Secret Template | Days Since Last Accessed
"@

        foreach ($info in $ownersEmailData[$emailAddress]) {
            $emailBody += "$info`r`n"
        }

        $emailBody += @"

Best regards,
Your IT Team
"@

        try {
            Write-Host "Notifying owner at $emailAddress" -ForegroundColor Magenta
            Send-SecureMail -To $emailAddress -From $Global:FromAddress -Subject "Secret Deactivation Notification" -Body $emailBody -SmtpServer $Global:SmtpServer
            Write-Host "Email sent to $emailAddress" -ForegroundColor Green
        } catch {
            Write-Host "Failed to send email to $emailAddress" -ForegroundColor Red
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
        Write-Host "Email sent to $To" -ForegroundColor Green
    } catch {
        Write-Host "Failed to send email: $_" -ForegroundColor Red
    } finally {
        $mailMessage.Dispose()
        $smtpClient.Dispose()
    }
}

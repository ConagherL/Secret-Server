# Configuration Variables
$Global:YourServerURL = "https://blt.secretservercloud.com"  # Replace with your actual Secret Server URL
$Global:ReportID = "148"                                     # Replace with your actual Report ID
$Global:ExportPath = "C:\temp\Export"                        # Replace with your desired export path
$Global:SmtpServer = "smtp.freesmtpservers.com"              # Replace with your SMTP server
$Global:FromAddress = "ITAdmins@blt.com"                     # Replace with your from email address

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
Notifies the owners of secrets about the pending deactivation.

.DESCRIPTION
This function sends notification emails to the owners of secrets listed in the specified report, indicating the deactivation of their secrets. If a users email is listed multiple times, then we only email once

.EXAMPLE
Test-Notify-SecretOwners

This example sends notifications to secret owners based on the report specified by $Global:ReportID, using the SMTP settings defined in the global variables.

.NOTES
Relies on $Global:session, $Global:ReportID, $Global:SmtpServer, and $Global:FromAddress being set prior to invocation.
#>
function Test-Notify-SecretOwners {
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
    foreach ($secret in $Global:reportData) {
        $emailAddresses = $secret.EmailAddresses -split ','  
        $secretName = $secret.'Secret Name'
        $emailsSentCount = 0
        $uniqueEmails = @{}

        if (-not $secretName) {
            Write-Host "Secret Name is missing for Secret ID: $($secret.secretid)" -ForegroundColor Yellow
            continue
        }

        foreach ($emailAddress in $emailAddresses) {
            $emailAddress = $emailAddress.Trim()
            if ($emailAddress -and -not $uniqueEmails.ContainsKey($emailAddress)) {
                $uniqueEmails[$emailAddress] = $true

                Write-Host "Notifying owner of Secret: $secretName at $emailAddress" -ForegroundColor Magenta

                $emailBody = @"
Dear Secret Owner,

This is a notification that the secret '$secretName' is scheduled for deactivation.

Best regards,
Your IT Team
"@

                try {
                    Send-SecureMail -To $emailAddress -From $Global:FromAddress -Subject "Secret Deactivation Notification" -Body $emailBody -SmtpServer $Global:SmtpServer
                    $emailsSentCount++
                } catch {
                    Write-Host "Failed to send email to $emailAddress for Secret: $secretName" -ForegroundColor Red
                }
            } elseif (-not $emailAddress) {
                Write-Host "Invalid email address found for Secret: $secretName" -ForegroundColor Yellow
            }
        }

        Write-Host "Total unique emails sent for Secret '$secretName': $emailsSentCount" -ForegroundColor Green
    }
}

<#
.SYNOPSIS
Sends an email using specified SMTP settings.

.DESCRIPTION
This function sends an email to a specified recipient using the SMTP server settings defined in the global variables.

.EXAMPLE
Send-SecureMail -To "recipient@example.com" -From $Global:FromAddress -Subject "Test Email" -Body "This is a test email." -SmtpServer $Global:SmtpServer

This example sends a test email to "recipient@example.com" using the SMTP server and from address specified in the global variables.

.NOTES
Relies on $Global:SmtpServer and $Global:FromAddress being set prior to invocation.
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

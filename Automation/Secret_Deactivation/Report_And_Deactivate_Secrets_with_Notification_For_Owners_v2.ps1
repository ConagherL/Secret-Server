# Configuration Variables
$Global:YourServerURL = "https://XXXX.DOMAIN.COM"  # Replace with your actual Secret Server URL
$Global:ReportID = "148"                           # Replace with your actual Report ID
$Global:ExportPath = "C:\temp\Export"              # Replace with your desired export path
$Global:SmtpServer = "smtp.XXXXXXX.com"            # Replace with your SMTP server
$Global:FromAddress = "ITAdmins@XXXX.com"          # Replace with your from email address

# Ensure the Thycotic Secret Server module is loaded
if (-not (Get-Module -ListAvailable -Name Thycotic.SecretServer)) {
    Write-Error "Thycotic.SecretServer module is not installed. Please install it to proceed."
    return                        
}
Import-Module Thycotic.SecretServer

# Prompt for credentials and establish a new session with the Secret Server
function New-Session {
    try {
        $Global:session = New-TssSession -SecretServer $Global:YourServerURL -Credential (Get-Credential)
        if (-not $Global:session) {
            Write-Error "Failed to establish a session with the Secret Server."
            return $false
        }
        return $true
    } catch {
        Write-Error "An error occurred while trying to establish a session: $_"
        return $false
    }
}

# Function to renew the session if it's expired
function Renew-SessionIfNeeded {
    if (-not $Global:session -or $Global:session.Expired) {
        Write-Host "Session is not valid or has expired. Renewing session..." -ForegroundColor Yellow
        return New-Session
    }
    return $true
}

if (-not (New-Session)) {
    return
}

# Output the session object to verify
Write-Output $Global:session

function Invoke-Report {
    Write-Host "Checking session validity..." -ForegroundColor Cyan
    if (-not (Renew-SessionIfNeeded)) {
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

function Invoke-Deactivate-Secrets {
    $results = @()

    Write-Host "Checking session validity..." -ForegroundColor Cyan
    if (-not (Renew-SessionIfNeeded)) {
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
        $retryCount = 0
        $maxRetries = 3
        $success = $false

        while (-not $success -and $retryCount -lt $maxRetries) {
            try {
                if (-not (Renew-SessionIfNeeded)) {
                    return
                }

                Remove-TssSecret -TssSession $Global:session -Id $secret.SecretId -Confirm:$false

                $result = [PSCustomObject]@{
                    ID     = $secret.SecretId
                    Name   = $secret.'Secret Name'
                    Action = "Deactivated"
                }
                $results += $result

                Write-Host "Secret $($secret.SecretId) deactivated successfully." -ForegroundColor Green
                $success = $true
            } catch {
                Write-Host "Failed to deactivate secret $($secret.SecretId): $_" -ForegroundColor Red
                $retryCount++
                if ($retryCount -ge $maxRetries) {
                    $result = [PSCustomObject]@{
                        ID     = $secret.SecretId
                        Name   = $secret.'Secret Name'
                        Action = "Failed to Deactivate"
                    }
                    $results += $result
                }
            }
        }
    }

    $csvPath = Join-Path -Path $Global:ExportPath -ChildPath "DeactivationResults.csv"
    $results | Export-Csv -Path $csvPath -NoTypeInformation

    Write-Host "Results exported to $csvPath" -ForegroundColor Green
}

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

        Add-Content -Path $outputPath -Value "`nEmail Notification Summary:"
        Add-Content -Path $outputPath -Value "Owner Email, Total Secret"
        foreach ($email in $ownersEmailData.Keys) {
            $uniqueSecretsCount = $ownersEmailData[$email].Count
            Add-Content -Path $outputPath -Value "$email, $uniqueSecretsCount"
        }

        Write-Host "All notifications and summary exported to $outputPath" -ForegroundColor Green
    }
}

function Send-EmailtoSecretOwners {
    Write-Host "Checking session validity..." -ForegroundColor Cyan
    if (-not (Renew-SessionIfNeeded)) {
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
    $mailMessage.IsBodyHtml = $true  # This line enables HTML content in the email body

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

function Send-SecureMail-ToFile {
    param (
        [string]$To,
        [string]$From,
        [string]$Subject,
        [string]$Body
    )

    # Hardcoded folder path to save the email contents
    $SaveFolder = $Global:ExportPath

    $emailContent = @"
From: $From
To: $To
Subject: $Subject
Content-Type: text/html; charset=UTF-8

$Body
"@

    try {
        $fileName = $To -replace '[\\\/:\*\?"<>\|]', '_'  # Remove illegal characters for filenames
        $filePath = Join-Path $SaveFolder "$fileName.eml"

        $emailContent | Out-File -FilePath $filePath -Encoding UTF8

        Write-Host "Email saved to $filePath" -ForegroundColor Green
    } catch {
        Write-Host "Failed to save email: $_" -ForegroundColor Red
    }
}

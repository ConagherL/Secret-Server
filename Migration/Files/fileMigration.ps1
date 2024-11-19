#region User Configuration
$tempFilePath = "C:\Migration\Files\"
$logfileName = "ss-FileMigration.log"

$src = @{
    url  = "https://labss01.jaggerlab.local/SecretServer/"
    cred = (Get-Credential -Message "Please enter credentials for source server") 
}

$dest = @{
    url  = "https://labss02.jaggerlab.local/SecretServer/"
    cred = (Get-Credential  -Message "Please enter credentials for destination server") 
}
#endregion

#region Script Functions
function write-log ($dataitem) {(get-date).ToString("[yyyy-MM-dd hh:mm:ss.ffff zzz]`t"), $dataitem -join "" | Add-Content -Path($tempFilePath, $logfileName -join "\")}
#endregion

#Valudating folder for logs and temp files exists
if (!(test-path $tempFilePath)) { throw "File Path $tempFilePath does not exist" }

write-log "------------ Starting run ------------"
write-log ("Source " + $src.url)
write-log ("Destination " + $dest.url)

#get auth Tokens
$SourceSession = New-TssSession -SecretServer $src.url -Credential $src.cred
$DestinationSession = New-TssSession -SecretServer $dest.url -Credential $dest.cred

#check to see if SQL report is present on source, then run report to get file list
$AttachmentReportID = (Search-TssReport -TssSession $SourceSession -SearchText "Secrets Containing Files" ).id
if ($null -eq $AttachmentReportID) { throw 'Cannot Find Required SQL report "Secrets Containing Files"' }

$report = Invoke-TssReport -TssSession $SourceSession -reportid $AttachmentReportID

$total = $report.Count
write-log "Report run $total entries found"
$loop = 1
#iterate through report items
foreach ($item in $report) { 
    $targ = $null
    write-log ($item | ConvertTo-Json -Compress)
    Write-host "-----------------------------------------------------"
    write-host "[" $loop.tostring("0000") "/" $total.tostring("0000") "] Processing Source Secret" $item.SecretIDNumber 
    Write-host "-----------------------------------------------------"
    write-host "Path`t`t:" ($item.'folder path', $item.secretname -join "\")
    write-host "FileName`t:" $item.FileName
    Write-host "-----------------------------------------------------"
    write-host ""

    #try to find target secret using exact path (should avoid duplcate confusion)
    if ($item.'Folder Path' -eq 'No folder assigned') {
        $targ = Get-TssSecret -TssSession $DestinationSession -id (Find-TssSecret -TssSession $DestinationSession -secretname $item.SecretName -ExactMatch).secretid 
    }
    else {
        $targ = Get-TssSecret -TssSession $DestinationSession -Path ($item.'folder path', $item.secretname -join "\")
    }
    if ($null -eq $targ) {

        #if target secret cant be located, ask user for target secret id

        Write-Error ("Cannot find Secret " + ($item.'folder path', $item.secretname -join "\") + " - source secret ID " + $item.SecretIDNumber) 
        $ManualTargetID = read-host "Please enter target secret ID (-1 to skip)"
        write-log ("Manual target ID entered " + $ManualTargetID)
        if ($ManualTargetID -eq -1) { $targ = $null }else { $targ = Get-TssSecret -TssSession $DestinationSession -id $ManualTargetID }
    }
    #if target is found, start the fun
    if ($null -ne $targ) {
        write-log ("Target" + ($targ | select-object Name, Id, FolderId, SecretTemplateName | convertto-json -Compress) + ($targ.Items | select-object slug, filename | convertto-json -Compress))

        #grab source secret
        $srce = Get-TssSecret -TssSession $SourceSession -Id $item.SecretIDNumber
        write-log ("Source" + ($srce | select-object Name, Id, FolderId, SecretTemplateName | convertto-json -Compress) + ($srce.Items | select-object slug, filename | convertto-json -Compress))

        #validate that all templates match
        if ($targ.SecretTemplateName -eq $item.secrettypename -and $targ.SecretTemplateName -eq $srce.SecretTemplateName) {
            
            #get "slug" value for template feild containing file
            $SrceSlug = ($srce.Items | Where-Object -property Filename -eq $item.fileName).slug
            $OutputPath =  ($tempFilePath + $srce.Secretid + $SrceSlug)
            $FileName = $item.FileName
            
            #File download
            try {
                write-host "Downloading $filename to $outputpath"
                Invoke-WebRequest -Uri ($src.url + "/api/v1/secrets/" + $srce.id + "/fields/" + $SrceSlug + "?args.includeInactive=true") -Headers @{authorization = "bearer " + $SourceSession.AccessToken } -OutFile $OutputPath
                write-log ("File > $filename < downloaded: " + $OutputPath)
            }
            catch {
                Write-log "Error downloading attachment : $_"
                Write-Error "Error downloading attachment : $_" 
            }
            #package download to be sent to target system
            $sendSecretFieldParams = @{
                fileName       = $FileName
                fileAttachment = ([IO.File]::ReadAllBytes($OutputPath))
            }
            $body = ConvertTo-Json $sendSecretFieldParams

            #upload data to secret field
            try {
                write-host "Uploading file"
                $ProgressPreference = "SilentlyContinue"
                Invoke-WebRequest -Uri ($dest.url + "/api/v1/secrets/" + $targ.id + "/fields/" + $SrceSlug) -Headers @{authorization = "bearer " + $DestinationSession.AccessToken } -Body $Body -Method put -ContentType 'application/json' | Out-Null
                write-log ("Uploaded $outputpath to SecretID: " + $targ.id + " - Slug: $SrceSlug - Filename: $filename")
            }
            catch {
                Write-Log "Error Uploading attachment : $_" 
                Write-Error "Error Uploading attachment : $_" 
            }
            write-host "Removing downloaded file $outputPath"
            Remove-Item $OutputPath
            if (Test-Path $OutputPath) {
                write-log "error removing $outputpath" 
                write-error "error removing $outputpath" 
            }
            else {
                write-log "cleanup sucessful"  
                write-host "cleanup sucessful" 
            }
        }
        else {
            write-error "template mismatch" 
            write-log "template mismatch" 
        }
    }
    write-host "" 
    $loop++

    #added to keep SSC WAF happy
    Start-Sleep -Milliseconds 250
}
write-log "------------ Run Completed ------------"

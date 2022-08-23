
Function Get-Token
{
[cmdletbinding()]
Param(
[Parameter(Mandatory=$True,Position=0)]
$WebProxy,
[Parameter(Mandatory=$False)]
$Domain,
[Parameter(Mandatory=$False)]
$OrgCode,
[Parameter(Mandatory=$False)]
$MFAToken

)
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    #Enter HardCoded Credentials, or use Get-Credential Method to input username and password.

    $AuthToken = Get-Credential
    $username = $AuthToken.UserName
    $password = $AuthToken.GetNetworkCredential().Password
            
    # Define the user credentials 
    # $username = "" 
    # $password = ""
    if(!$OrgCode)
    {
        $OrgCode = ""
    }
    if(!$Domain)
    {
        $Domain = "local"
    }
    if(!$MFAToken)
    {
        $tokenResult = $WebProxy.Authenticate($username, $password, $OrgCode, $domain)
        if($tokenResult.Errors.Count -gt 0)
        {
            Write-Output "Authentication Error: " $tokenResult.Errors[0]
            Return
        }
    }
    else
    {
        $tokenResult = $WebProxy.Authenticate($username, $password, $OrgCode, $domain,$MFAToken)
        if($tokenResult.Errors.Count -gt 0)
        {
            Write-Output "Authentication Error: " $tokenResult.Errors[0]
            Return
        }
    }
    $token = $tokenResult.Token

    return $token

}


    
Function Invoke-FileMigration
{
<#

   .Synopsis

    This is a Powershell script to migrate Secret Server files from one instance, to a replicated / migrated destination instance. 

   .Description

    This script needs to have a mirrored folder / secret structure between the source and destination instance to work properly. Each File Field on the the template will need to have a unique name.

   .Example
    Invoke-FileMigration -SourceFQDN https://SourceUrl/secretserver -DestinationFQDN https://DestinationUrl/secretserver

    .Example
    Invoke-FileMigration -SourceFQDN https://SourceUrl/secretserver -DestinationFQDN https://DestinationUrl/secretserver -domain testdomain.com -IncludePersonalFolders $false
   

   .Parameter SourceFQDN

    The path to the source instance of Secret Server. This should match your source instance of Secret Server's Base URL and should not contain a trailing "/": Exmaple https://SourceSecretServerURL.com/SecretServer, if you Secret Server is installed at the IIS Root, your url will be: https://SourceSecretServerURL.com

   .Parameter DestinationFQDN

    The path to the destination instance of Secret Server. This should match your destination instance of Secret Server's Base URL and should not contain a trailing "/": Exmaple https://DestinationSecretServerURL.com/SecretServer, if you Secret Server is installed at the IIS Root, your url will be: https://DestinationSecretServerURL.com

    .Parameter OrgCode

    If you are connecting to a legacy instance of Secret Server Online (SSO), you will need to provide an OrgCode as a parameter to authenticate.

    .Parameter Domain

    If you are using a Domain User to authenticate and migrate the files, please enter the Domain value that is used to log in. Example: example.com

    .Parameter MFAToken

    If two-factor authentication is enabled, our API's support any authentication that can provide a code before the initial access challenge. 

    .Parameter ConcurrentJobs

    Default is 8, this will control the number of jobs that the script will create at one time, this can be throttled for performance.

    .Parameter IncludePersonalFolders

    Default is $true, this will include the personal folders in the migration path, if you do not wish to include personal folders, set this value to false.

    .Parameter Log

    Text file that will contain all outputs from this script, all successful and failed migration items will be logged here. By default C:\SSMigrationLog.txt

   .Inputs

    [System.String]

   .Notes

    NAME:  Invoke-FileMigration

    AUTHOR: Andy Crandall

    LASTEDIT: 10/09/2018 14:21:22

   .Link

    https://thycotic.github.com

 #Requires -Version 3.0

 #>
[cmdletbinding()]
Param(
[Parameter(Mandatory=$False)]
[string]$SourceFQDN,
[Parameter(Mandatory=$False)]
[string]$DestinationFQDN,
[Parameter(Mandatory=$False)]
[string]$OrgCode = "",
[Parameter(Mandatory=$False)]
[string]$Domain = 'local',
[Parameter(Mandatory=$False)]
[string]$MFAToken,
[Parameter(Mandatory=$False)]
[int]$ConcurrentJobs = '7', # Set this value to be equal to the number of cores on the machine running it. 
[Parameter(Mandatory=$False)]
[bool]$IncludePersonalFolders = $true,
[parameter(Mandatory=$False)]
[string]$Log = "C:\Migration\SSFileMigrationLog.txt"
)
    # Initialize Variables, and Create Hash Tables for comparison, as well as for verifying ParentFolderID.
#------------------------------------
Write-Host "Beginning Script, initializing variables and creating reference tables."
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$stopwatch =  [system.diagnostics.stopwatch]::StartNew()
$elapsed = $Stopwatch.Start()
$MigratedSuccessfully = @()
$NoMatches = @()
$UnMatchedFields = @()

if(!$SourceFQDN)
{
    $SourceFQDN = Read-Host "Please Enter the Source Instance URL, for example: https://SourceSecretServerURL.com/SecretServer"
}
if(!$DestinationFQDN)
{
    $DestinationFQDN = Read-Host "Please Enter the Source Instance URL, for example: https://destination.secretservercloud.com"
}

$SourceUrl = "$SourceFQDN/webservices/SSWebservice.asmx?wsdl"
$DestinationUrl = "$DestinationFQDN/webservices/SSWebservice.asmx?wsdl"

$SourceFolderReference = @{}
$DestinationFolderReference = @{}
$FolderMap = @{}

$SourceProxy = New-WebServiceProxy -uri $SourceUrl -UseDefaultCredential -Namespace "ss"
$DestinationProxy = New-WebServiceProxy -uri $DestinationUrl -UseDefaultCredential -Namespace "ss"

Write-Host "Generating Source Access Token"
$SourceToken = Get-Token -WebProxy $SourceProxy -Domain $Domain -OrgCode $OrgCode -MFAToken $MFAToken
if($SourceToken -like "Authentication Error:*")
{
    throw "Source Login Error: $SourceToken" 
}
Write-Host "Generating Destination Access Token"
$DestinationToken = Get-Token -WebProxy $DestinationProxy -Domain $Domain -MFAToken $MFAToken
if($DestinationToken -like "Authentication Error:*")
{
    throw "Destination Login Error: $DestinationToken" 
}

$SourceFolders = $SourceProxy.SearchFolders($SourceToken,"")
if($SourceFolders.Errors.Count -gt 0)
{
    throw "Source Folder Retrieval Error: " + $SourceFolders.errors
}
$DestinationFolders = $DestinationProxy.SearchFolders($DestinationToken,"")
if($DestinationFolders.Errors.Count -gt 0)
{
    throw "Destination Folder Retrieval Error: " + $DestinationFolders.errors
}

#Build Hash Tabled References for organization.
foreach($folder in $SourceFolders.Folders)
{ 
    $FolderName = $folder.Name
    $FolderID = $folder.ID
    $ParentFolderID = $folder.ParentFolderID
    $SourceFolderReference[$FolderID]=($FolderName,$ParentFolderID)
}

foreach($folder in $DestinationFolders.Folders)
{ 
    $FolderName = $folder.Name
    $FolderID = $folder.ID
    $ParentFolderID = $folder.ParentFolderID
    $DestinationFolderReference[$FolderID]=($FolderName,$ParentFolderID)
}
$personalfolderID = 0
foreach($key in $SourceFolderReference.keys)
{
    if($SourceFolderReference[$key].item(0) -eq "Personal Folders")
    {
        $personalfolderID = $key
    }
}

#------------------------------

#Run through and build a list of corresponding Folder ID's between the two environments,
# using the reference hash tables above, to ensure each folder returned has the same Parent Folder.
# Duplicate Folder Names are not allowed at the same level.
$elapsed = $Stopwatch.Elapsed     
Write-Host "Building folder mappings between instances. Elapsed Time: $elapsed"
    foreach($folder in $SourceFolders.Folders)
    {
        $DestinationFolderID = $null
        $SourceFolderID = $folder.Id
        $SourceFolderName = $folder.name
        $SourceParentFolderId = $SourceFolderReference[$SourceFolderID].item(1)

        if($IncludePersonalFolders -eq $False)
        {
            if($SourceParentFolderId -ne $personalfolderID)
            {
                #if the source parent folder, is not a top level folder, create the reference of parent folders. 
                if($SourceParentFolderId -ne "-1")
                {
                   # $SourceParentFolderName = $SourceFolderReference[$SourceParentFolderId].item(0)
                    $SourceParentReference= @()
                    $ReferenceFolderID = $SourceParentFolderId
                    #build the source folder path once, to reduce script iterations.
                    while($ReferenceFolderID -ne "-1")
                    {
                
                        $SourceParentReference += $SourceFolderReference[$ReferenceFolderID].item(0)
                        $ReferenceFolderID = $SourceFolderReference[$ReferenceFolderID].item(1) 
                
                    }
                    [array]::Reverse($SourceParentReference)
                    $SourceFolderPath = $SourceParentReference  -join '/'
                }
                #Folders can be duplicated as long as they are not on the same Level, so we check to verify that the Parent Folder ID is the same.
                foreach($key in $DestinationFolderReference.Keys)
                {

                    $DestinationFolderName = $DestinationFolderReference[$key].item(0)
                    $DestinationParentFolderID = $DestinationFolderReference[$key].item(1)

                    #If the folder is a top level folder, and the names match, add this to our Mapping Array.
                    if($SourceParentFolderId -eq "-1" -and $DestinationParentFolderID -eq "-1" -and $SourceFolderName -eq $DestinationFolderName)
                    {
                        $DestinationFolderID = $key
                        $FolderMap.Add($SourceFolderID,$DestinationFolderID)
                        Break
                    }
                    #If the Folder is not top level, compare to see if the parent folders are the same, if they are and the name matches then its the corresponding folder.
                    elseif($SourceParentFolderID -ne "-1" -and $DestinationParentFolderID -ne "-1")
                    {

                        #Creating an array of all the parent folders into an array so we can compare the actual folder-path.

                        $DestinationParentReference= @()
                        $ReferenceFolderID = $DestinationParentFolderID
                        while($ReferenceFolderID -ne "-1")
                        {
                            $DestinationParentReference += $DestinationFolderReference[$ReferenceFolderID].item(0)
                            $ReferenceFolderID = $DestinationFolderReference[$ReferenceFolderID].item(1) 
                        } 
                        [array]::Reverse($DestinationParentReference)
                        $DestinationFolderPath = $DestinationParentReference -join '/'

                        $compare = $SourceFolderPath -eq $DestinationFolderPath
              
                        if($compare -eq $true -and $SourceFolderName -eq $DestinationFolderName)
                        {
                            $DestinationFolderID = $key
                            $FolderMap.Add($SourceFolderID,$DestinationFolderID)
                            Break
                        }
                    }
                }
            }
        }
        else
        {
            #if the source parent folder, is not a top level folder, create the reference of parent folders. 
            if($SourceParentFolderId -ne "-1")
            {
               # $SourceParentFolderName = $SourceFolderReference[$SourceParentFolderId].item(0)
                $SourceParentReference= @()
                $ReferenceFolderID = $SourceParentFolderId
                while($ReferenceFolderID -ne "-1")
                {
                
                    $SourceParentReference += $SourceFolderReference[$ReferenceFolderID].item(0)
                    $ReferenceFolderID = $SourceFolderReference[$ReferenceFolderID].item(1) 
                
                }
                [array]::Reverse($SourceParentReference)
                $SourceFolderPath = $SourceParentReference  -join '/'
            }
            #Folders can be duplicated as long as they are not on the same Level, so we check to verify that the Parent Folder ID is the same.
            foreach($key in $DestinationFolderReference.Keys)
            {

                $DestinationFolderName = $DestinationFolderReference[$key].item(0)
                $DestinationParentFolderID = $DestinationFolderReference[$key].item(1)

                #If the folder is a top level folder, and the names match, add this to our Mapping Array.
                if($SourceParentFolderId -eq "-1" -and $DestinationParentFolderID -eq "-1" -and $SourceFolderName -eq $DestinationFolderName)
                {
                    $DestinationFolderID = $key
                    $FolderMap.Add($SourceFolderID,$DestinationFolderID)
                    Break
                }
                #If the Folder is not top level, compare to see if the parent folders are the same, if they are and the name matches then its the corresponding folder.
                elseif($SourceParentFolderID -ne "-1" -and $DestinationParentFolderID -ne "-1")
                {

                    #Creating an array of all the parent folders into an array so we can compare the actual folder-path.

                    $DestinationParentReference= @()
                    $ReferenceFolderID = $DestinationParentFolderID
                    while($ReferenceFolderID -ne "-1")
                    {
                        $DestinationParentReference += $DestinationFolderReference[$ReferenceFolderID].item(0)
                        $ReferenceFolderID = $DestinationFolderReference[$ReferenceFolderID].item(1) 
                    } 
                    [array]::Reverse($DestinationParentReference)
                    $DestinationFolderPath = $DestinationParentReference -join '/'
                    $compare = $SourceFolderPath -eq $DestinationFolderPath
              
                    if($compare -eq $true -and $SourceFolderName -eq $DestinationFolderName)
                    {
                        $DestinationFolderID = $key
                        $FolderMap.Add($SourceFolderID,$DestinationFolderID)
                        Break
                    }
                }
            }
        } 
    }

    $elapsed = $Stopwatch.Elapsed
    Write-Host "Finished building FolderMappings. Elapsed time: $elapsed"

#Threading Section -------------------------------------------------------------------
    Write-Host "Creating Threads to Migrate Files between Folders"

    #Specify Code to be run for each Job. 
    $CodeContainer = {
                Param(
                $SourceUrl,
                $DestinationUrl,
                $SourceToken,
                $DestinationToken,
                $SourceFolderID,
                $DestinationFolderID,
                $Log,
                $SourceFolderName
                     )
                [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
                #Initialize variables
                $SourceProxy = New-WebServiceProxy -uri $SourceUrl -UseDefaultCredential -Namespace "ss"
                $DestinationProxy = New-WebServiceProxy -uri $DestinationUrl -UseDefaultCredential -Namespace "ss"

                #Debug Loop to hang Code for debugging------------
                #$Debug = $false
                #while($Debug -eq $false) {$i+=1}
                #-----------------------------------------------------
                
                #Get the secrets from the matching folders, and Migrate Files. 
                $DuplicateTracker = @{}
                $LogMsg = "Running Job for folder: $SourceFolderName"
                $LogMsg | Out-File -FilePath $Log -Append
                $SourceSecrets = $SourceProxy.SearchSecretsByFolder($SourceToken,"",$SourceFolderID,$false,$false,$true)
                if($SourceSecrets.errors.count -gt 0)
                            {
                                $LogMsg = "Error getting Source Secret Batch."
                                $LogMsg | Out-File -FilePath $Log -Append
                                $SourceSecret.Errors | Out-File -FilePath $log -Append
                                continue
                            }
                $DestinationSecrets = $DestinationProxy.SearchSecretsByFolder($DestinationToken,"",$DestinationFolderID,$false,$false,$true)
                if($DestinationSecrets.errors.count -gt 0)
                            {
                                $LogMsg = "Error getting Source Secret Batch."
                                $LogMsg | Out-File -FilePath $Log -Append
                                $DestinationSecrets.Errors | Out-File -FilePath $log -Append
                                continue
                            }
                $LogMsg = "Pulled Secrets for $SourceFolderName, there are "+ $SourceSecrets.SecretSummaries.count + " Secrets in the source, and " + $DestinationSecrets.SecretSummaries.count  +" In the Destination"
                $LogMsg | Out-File -FilePath $Log -Append        

                $codeResponseProp = @{
                    ErrorCode = "COMMENT"
                    Comment = "API File Migration"
                }
                $coderesponse = new-object psobject -Property $codeResponseProp 

                foreach($SourceSecret in $SourceSecrets.SecretSummaries)
                {
                    [bool]$Transfer = $false
                    foreach($DestinationSecret in $DestinationSecrets.SecretSummaries)
                    {
                    #check to see if the secret is a duplicate by checking for the "---###" at the end. If it is a duplicate, then strip the duplicate name off for comparison.
                        $file = $null
                        #----------------------------------------------------
                        $DestinationSecretName = $DestinationSecret.SecretName
                        if($DestinationSecretName -like "*(*)")
                        {
                            $index = $DestinationSecretName.LastIndexOf("(")
                            $substring = $DestinationSecretName.Substring(0,$index)
                            $duplicateID = $DestinationSecretName.Substring($index+1)
                            if($duplicateID -match "^\d+\)$")
                            {
                                $DestinationSecretName = $substring
                            } 
                        }
                        #check to see if secret name and template match.
                        if($DestinationSecretName.trim() -eq $SourceSecret.SecretName.trim() -and $DestinationSecret.SecretTypeName -eq $SourceSecret.SecretTypeName)
                        {     
                            [int] $SourceSecretID = $SourceSecret.Secretid
                            [int] $DestinationSecretID = $DestinationSecret.SecretId
                            $LogMsg = "Matched Source Secret $SourceSecretID, $SourceSecretName  With $DestinationSecretId, $DestinationSecretName"  
                            $LogMsg | Out-File -FilePath $Log -Append   
                            #in order to ensure that files are not overwritten, if the secret has already been migrated to, skip it.
                            if($DuplicateTracker.ContainsValue($DestinationSecretID))
                            {
                                $LogMsg = "Secret $DestinationSecretId, $DestinationSecretName Has already been migrated, Skipping."  
                                $LogMsg | Out-File -FilePath $Log -Append  
                                continue
                            }
                            $SourceSecretDetail = $SourceProxy.GetSecret($SourceToken,$SourceSecretID,$True,$coderesponse)
                            if($SourceSecretDetail.errors.count -gt 0)
                            {
                                $LogMsg = "Error getting Source Secret $SourceSecretName"
                                $LogMsg | Out-File -FilePath $Log -Append
                                $SourceSecretDetail.Errors | Out-File -FilePath $log -Append
                                continue
                            }
                            #iterate through each field on the source, and check to see if its a file.
                            foreach($SourceField in $SourceSecretDetail.secret.items)
                            {
                               # $LogMsg = "Checking Field is file = " + $Sourcefield.isfile + " On " + $SourceSecretName
                               #  $LogMsg | Out-File -FilePath $Log -Append   
                                if($SourceField.isfile -eq $true)
                                {
                                    $file = $SourceProxy.DownloadFileAttachmentByItemId($SourceToken, $SourceSecretDetail.Secret.Id, $SourceField.Id)
                                    #if the file on the source is empty, skip it.
                                    if(!$file.fileattachment)
                                    {
                                        continue
                                    }
                                    $DestinationSecretDetail = $DestinationProxy.GetSecret($DestinationToken,$DestinationSecretID,$True,$coderesponse)
                                    if($DestinationSecretDetail.errors.count -gt 0)
                                    {
                                        $LogMsg = "Error getting Destination Secret $DestinationSecretName"
                                        $LogMsg | Out-File -FilePath $Log -Append
                                        $DestinationSecretDetail.Errors | Out-File -FilePath $log -Append
                                        continue
                                    }
                                    foreach($TargetField in $DestinationSecretDetail.secret.items)
                                    {
                                        if($SourceField.FieldName -eq $TargetField.FieldName)
                                        {
                                                $LogMsg = $("Checking Fieldname" + $SourceField.fieldname + "on " + $SourceSecretName)
                                                $LogMsg | Out-File -FilePath $Log -Append
                                                # Build Variables for Logging
                                                $SourceSecretName = $SourceSecret.SecretName
                                                $SourceFileName = $file.FileName
                                                # Upload to Destination
                                                try{
                                                    $uploadResult = $DestinationProxy.UploadFileAttachmentByItemId($DestinationToken, $DestinationSecretDetail.Secret.id, $TargetField.Id, $file.FileAttachment, $file.FileName)
                                                }
                                                catch
                                                {
                                                   $_.exception | Out-File -FilePath $log -Append
                                                }                                                
                                                # Write to log
                                                $LogMsg = "Currently migrating file: $SourceFileName on secret: $SourceSecretName in folder: $SourceFolderName to Secret: $DestinationSecretName"
                                                $LogMsg | Out-File -FilePath $Log -Append
                                                #Set Transfer to true to exit loop to prevent overwriting of files.
                                                $DuplicateTracker.add($SourceSecretID,$DestinationSecretID) 
                                                $Transfer = $true
                                                
                                                # Failed upload
                                                if($uploadResult.Errors.Count -gt 0) {
                                                    $ErrorInfo = "FAIL: file: $SourceFileName on secret: $SourceSecretName in folder: $SourceFolderName to Secret: $DestinationSecretName"
                                                    $ErrorInfo | Out-File -FilePath $Log -Append
                                                    $uploadResult | Out-File -FilePath $Log -Append
                                                }
                                                # Successful upload
                                                else {
                                                    $SuccessInfo = "SUCCESS: file: $SourceFileName on secret: $SourceSecretName in folder: $SourceFolderName to Secret: $DestinationSecretName"
                                                    $SuccessInfo | Out-File -FilePath $Log -Append
                                                }  
                                        }                                        
                                    }
                                }
                            }    
                        }
                        if($Transfer -eq $true)
                        {
                            Break
                        }
                    }
                }
                if(!$DuplicateTracker)
                {
                    $LogMsg = "Job Completed, NO FILES MIGRATED for Folder $SourceFolderName"  
                    $LogMsg | Out-File -FilePath $Log -Append  
                }          
        }
       
        #Build Job Related Variables
        $MaxThreads = $ConcurrentJobs
       # $MaxWaitTime = 600
        $SleepTime = 500
        $Threads = @()
        $i = 0
        Foreach($Key in $FolderMap.Keys)
        {
            $Parameter = @($SourceURL,$DestinationURL,$SourceToken,$DestinationToken,$Key,$FolderMap[$Key],$Log,$SourceFolderReference[$key].item(0))
            While((Get-Job -State Running).count -gt $MaxThreads) 
            {
                Write-Progress -Id 1 -Activity 'Waiting for existing jobs to complete' -Status "$($(Get-job -State Running).count) jobs running" -PercentComplete ($i / $FolderMap.Count * 100)
                Start-Sleep -Milliseconds $SleepTime
            }

            # Start new jobs 
            $i++
            $Threads += Start-Job -ScriptBlock $CodeContainer -Name $key  -ArgumentList $Parameter[0],$Parameter[1],$Parameter[2],$Parameter[3],$Parameter[4],$Parameter[5],$Parameter[6],$Parameter[7]
            Write-Progress -Id 1 -Activity 'Starting jobs' -Status "$($(Get-job -State Running).count) jobs running" -PercentComplete ($i / $FolderMap.Count * 100)
        }

         # All jobs have now been started


        # Wait for jobs to finish
        While((Get-Job -State Running).count -gt 0) 
        {
            $JobsStillRunning = ''
            foreach($RunningJob in (Get-Job -State Running)) {
            $JobsStillRunning += $RunningJob.Name
                }

                Write-Progress -Id 1 -Activity 'Waiting for jobs to finish' -Status "$JobsStillRunning"  -PercentComplete (($FolderMap.Count - (Get-Job -State Running).Count) / $FolderMap.Count * 100)
                Start-Sleep -Seconds '1'
            }

            # Output
            Write-Host "Jobs Completed, printing output:"
            
            $ThreadErrors = @()
            $FailedJobs = @()
           $Jobs =  Get-job
           foreach($j in $jobs)
           {
                [int] $ID = $j.name
                $ThreadError = $null
                $Name = $SourceFolderReference[$ID].item(0)
                write-host  $Name "job has completed."
                   

                   if($j.childjobs[0].error)
                   {
                        Write-Host "Thread Errored"
                        $ThreadError = $j.childjobs[0].error
                        $FailedJobs += $j.name
                   }
                   else
                   {
                    $threadResults = Receive-Job -Job $j -ErrorVariable $ThreadError
                   }
                    if($threadResults)
                    {
                        $MigratedSuccessfully += $threadResults[0]
                        $NoMatches += $threadResults[1]
                        $UnMatchedFields += $threadResults[2]
                    }
                    if($ThreadError)
                    {
                        $ThreadErrors += $ThreadError
                    }
           }
            # Cleanup 
            Write-Host "Cleaning Up jobs"
            Get-job | Remove-Job

        # If any of the jobs encountered an error, just run that job again.
        if($failedjobs.count -gt 0)
        {
            Write-Host "Running any jobs that encountered errors again:"

            $Threads = @()
            $i = 0
            Foreach($Item in $FailedJobs)
            {
                $Parameter = @($SourceURL,$DestinationURL,$SourceToken,$DestinationToken,$Item,$FolderMap[[int]$Item],$Log,$SourceFolderReference[[int]$item].item(0))
                While((Get-Job -State Running).count -gt $MaxThreads) 
                {
                    Write-Progress -Id 1 -Activity 'Waiting for existing jobs to complete' -Status "$($(Get-job -State Running).count) jobs running" -PercentComplete ($i / $FailedJobs.count * 100)
                    Start-Sleep -Milliseconds $SleepTime
                }

                # Start new jobs 
                $i++
                $Threads += Start-Job -ScriptBlock $CodeContainer -Name $item  -ArgumentList $Parameter[0],$Parameter[1],$Parameter[2],$Parameter[3],$Parameter[4],$Parameter[5],$Parameter[6],$Parameter[7]
                Write-Progress -Id 1 -Activity 'Starting jobs' -Status "$($(Get-job -State Running).count) jobs running" -PercentComplete ($i / $FailedJobs.count * 100)
                Start-Sleep -Milliseconds $SleepTime

            }
            # All jobs have now been started

            # Wait for jobs to finish
            While((Get-Job -State Running).count -gt 0) 
            {
                $JobsStillRunning = ''
                foreach($RunningJob in (Get-Job -State Running)) {
                $JobsStillRunning += $RunningJob.Name
                    }

                    Write-Progress -Id 1 -Activity 'Waiting for jobs to finish' -Status "$JobsStillRunning"  -PercentComplete (($FailedJobs.count - (Get-Job -State Running).Count) / $FailedJobs.count * 100)
                    Start-Sleep -Seconds '1'
                }

                # Output
                Write-Host "Jobs Completed, printing output:"
            
                $ThreadErrors = @()
                $FailedJobs = @()
               $Jobs =  Get-job
               foreach($j in $jobs)
               {
                    [int] $ID = $j.name
                    $ThreadError = $null
                    $Name = $SourceFolderReference[$ID].item(0)
                    write-host  $Name "job has completed."
                   

                       if($j.childjobs[0].error)
                       {
                            Write-Host "Thread Errored"
                            $ThreadError = $j.childjobs[0].error
                            $FailedJobs += $j.name
                       }
                       else
                       {
                        $threadResults = Receive-Job -Job $j -ErrorVariable $ThreadError
                       }
                        if($threadResults)
                        {
                            $MigratedSuccessfully += $threadResults[0]
                            $NoMatches += $threadResults[1]
                            $UnMatchedFields += $threadResults[2]
                        }
                        if($ThreadError)
                        {
                            $ThreadErrors += $ThreadError
                        }
               }
                # Cleanup 
                Write-Host "Cleaning Up jobs"
                Get-job | Remove-Job
                Write-Host "Errors after second run:"
                $ThreadErrors

        }
               
    $elapsed = $Stopwatch.Elapsed
    Write-Host "Script Finished. Elapsed time: $elapsed"
}

Invoke-FileMigration -SourceFQDN "https://" -DestinationFQDN "https://"





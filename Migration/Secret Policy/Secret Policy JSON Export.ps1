<#
    .SYNOPSIS
    Exports all Secret Policies in source Secret Server insance into json files 

    .DESCRIPTION
    This script will use the REST API to export all Secret Policies in source Secret Server insance into json files.  These files can than be
    used to import int another Secret Server instance.  There is a corresponding scriot "Secre Policy JSON import.ps1" that will accomplish that task 
    The script is dependant on the Secrer Policy name. If a change is made to the name of a Source policy, a new policy will be created in teh target instance
    
    .RREQUIREMENTS
    The credentials being used must have the Administer Secret Policy Rolepermissionand basic user permissions
    The base usrl for source and target inctances

    .PARAMETERS
    site  Base url of the source secret server instance
        Example: https:\\mysecretserver.mydoman.com\secretserver
    
    $jsonExportFolder This is the folder that the script will export all json files to
        Not the Base Secrit Policyjson will be exported witha .txt extension.  All filenames will be derived from teh Secret Policy name  

    .NOTES
    
    .REVISION HISTORY
    Wrtittem By: Rick Roca
    Original Date: 6/13/2022
    Last update: 6/30/2022
    Rev 2.1

#>


#Set Parameters
$site = "https://iamaas-ispw-sitest.extnet.ocean.ibm.com/SecretServer"  #Must be set to the base url of secret server in  your environment with no trailing slash

$api = "$site/api/v2" # Do Not Change

$jsonExportFolder = "c:\temp\export\"
$apiTake = 250

#Delete File if exist
$target =  $jsonExportFolder ,"*.*" -join ""
If (Test-Path $target) {

Remove-Item $target  
}
#get Source token

try
    {
        $AuthToken = Get-Credential -Message "Enter credentials for Source instance"
        $creds = @{
        username = $AuthToken.UserName
        password = $AuthToken.GetNetworkCredential().Password
        grant_type = "password" }
    
    $token = ""
    $response = Invoke-RestMethod -Uri "$site/oauth2/token" -Method Post -Body $creds
    $token = $response.access_token;

   
    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("Authorization", "Bearer $token")
  
    }
      
catch
    {
    $message =  $Error[1]

    Write-Error "Source Authentication failed    $message"
    exit 1
    }

    


Function get_policies
{
 
    try
    {
 
        
        #get all policies from source
       $uri = "$site/api/v1/secret-policy/search?filter.active=$true&take=$apiTake"
        $policies = Invoke-RestMethod  -Uri $uri -Headers $headers
        #Loop through all policies
        foreach($policy in $policies.records)
        {
            $policyId = $policy.secretPolicyId
            $uri = "$api/secret-policy/$policyId"
            $sourcePolicy = invoke-restmethod -Uri $uri -Headers $headers
            update_policies -policy $sourcePolicy   
        } 
        
        
    }
    catch
    {
        $message = $Error[1]
        Write-Warning "Failed to get policy    $message"
        exit 1
    }


}
function create_policies{
    param(
    $policy
    )
    try{
    #create JSON
    $policyBase = @{
                secretPolicyName = $policy.secretPolicyName
                secretPolicyDescription = $policy.secretPolicyDescription
                Active = $policy.active
                }
    $payload = @{ data = $policyBase }
    $body = $payload | ConvertTo-Json -Depth 5
    Invoke-RestMethod -uri "$api/secret-policy" -Method Post -Headers $headers -Body $body -ContentType "application/json"
    }
    catch
    {
        $message = $Error[1]
        Write-Warning "Failed to create policy    $message"
        exit 1    
    }
}
function update_policies{
    param(
    $policy
    )
    try {
    #Check if Policy Exists
    $policyName = $policy.secretPolicyName
    #$uri = "$tsite/api/v1/secret-policy/search?filter.secretPolicyName=$policyName"
    $uri = "$site/api/v1/secret-policy/search"
    #$result = Invoke-RestMethod -Uri $uri -Headers $theaders 
    $results = Invoke-RestMethod -Uri $uri -Headers $headers 
    $found = $false
    foreach ($tPolicy in $results.records)
    {
     if ($policyName -eq $tPolicy.secretPolicyName)
     {
        $found = $true

        break
     }
    } 
   
   
 
 # general Items
  $item = $Policy.generalItems
    
        $siteId = $null
        $jumpboxRouteId = $null

      
        
        $siteId = @{
            dirty = $true
            value = @{ policyApplyType = $item.siteId.policyApplyType
          value = $item.siteId.value }
         }
        
       
         $jumpboxRouteId = @{
            dirty = $true
            value = @{ policyApplyType = $item.jumpboxRouteId.policyApplyType
          value = $item.jumpboxRouteId.value }

        }
        $generalitems = @{
        siteId = $siteId 
        jumpboxRouteId = $null
        }
        
        $generalitems = @{
        siteId = $siteId 
        jumpboxRouteId = $null
        }

      # Security Itema

      $item = $Policy.securityItems
        
        #Set all Values to null
        $allowOwnersUnrestrictedSshCommands = $null
        $approvalGroups = $null
        $approvalWorkflow = $null
        $checkOutChangePassword = $null
        $checkOutEnabled = $null
        $checkOutIntervalMinutes = $null
        $enableSshCommandRestrictions = $null
        $eventPipelinePolicy = $null
        $hideLauncherPassword = $null
        $isProxyEnabled= $null
        $isSessionRecordingEnabled = $null
        $requireApprovalForAccess = $null
        $requireApprovalForAccessForEditors = $null
        $requireApprovalForAccessForOwnersAndApprovers = $null
        $requireViewComment = $null
        $runLauncherUsingSSHKeySecretId = $null
        $sshCommandBlocklistEditors = $null
        $sshCommandBlocklistOwners = $null
        $sshCommandBlocklistViewers = $null
        $sshCommandMenuGroups = $null
        $sshCommandRestrictionType = $null

        
       
            $checkOutChangePassword = @{
            dirty = $true
            value = @{ policyApplyType = $item.checkOutChangePassword.policyApplyType
          value = $item.checkOutChangePassword.value }
          }
        
       
        
            $checkOutEnabled = @{
            dirty = $true
            value = @{ policyApplyType = $item.checkOutEnabled.policyApplyType
          value = $item.checkOutEnabled.value }
          }
        
       
            $checkOutIntervalMinutes = @{
            dirty = $true
            value = @{ policyApplyType = $item.checkOutIntervalMinutes.policyApplyType
          value = $item.checkOutIntervalMinutes.value }
          }
        
        # hide Launcher Password

     
            $hideLauncherPassword = @{
            dirty = $true
            value = @{ policyApplyType = $item.hideLauncherPassword.policyApplyType
          value = $item.hideLauncherPassword.value }
          }        
        # is Proxy Enabled

       
            $isProxyEnabled = @{
            dirty = $true
            value = @{ policyApplyType = $item.isProxyEnabled.policyApplyType
          value = $item.isProxyEnabled.value }
          }
        

        # is Session Recording Enabled

    
            $isSessionRecordingEnabled = @{
            dirty = $true
            value = @{ policyApplyType = $item.isSessionRecordingEnabled.policyApplyType
          value = $item.isSessionRecordingEnabled.value }
          }
               
        # require View Comment

       
            $requireViewComment = @{
            dirty = $true
            value = @{ policyApplyType = $item.requireViewComment.policyApplyType
          value = $item.requireViewComment.value }
          }
        $securityItems = @{
        checkOutChangePassword = $checkOutChangePassword
        checkOutEnabled = $checkOutEnabled
        checkOutIntervalMinutes = $checkOutIntervalMinutes
        hideLauncherPassword=$hideLauncherPassword
        isProxyEnabled = $isProxyEnabled
        isSessionRecordingEnabled = $isSessionRecordingEnabled
        requireViewComment = $requireViewComment
        }

        # RPC Items
        $item = $Policy.rpcItems
        
        $associatedSecretId1 = $null
        $associatedSecretId2 = $null
        $autoChangeOnExpiration = $null
        $autoChangeSchedule = $null
        $heartBeatEnabled = $null
        $passwordTypeWebScriptId = $null
        $privilegedSecretId = $null


        # auto Change On Expiration

     
            $autoChangeOnExpiration = @{
            dirty = $true
            value = @{ policyApplyType = $item.autoChangeOnExpiration.policyApplyType
          value = $item.autoChangeOnExpiration.value }
          }
        
         
        # heartBeat Enabled

            $heartBeatEnabled = @{
            dirty = $true
            value = @{ policyApplyType = $item.heartBeatEnabled.policyApplyType
          value = $item.heartBeatEnabled.value }
          }
                        
              
          #auto change schedule
          $value = $policy.rpcItems.autoChangeSchedule.value
          $ivalue = @{
                    changeType = $value.changeType
                    days=$value.days
                    friday =$value.friday
                    monday=$value.monday
                    monthlyDay=$value.monthlyDay
                    monthlyDayOfMonth = $value.monthlyDayOfMonth
                    changeOnlyWhenExpired = $value.changeOnlyWhenExpired
                    monthlyDayOrder = $value.monthlyDayOrder
                    monthlyDayOrderRecurrence = $value.monthlyDayOrderRecurrence
                    monthlyDayRecurrence = $value.monthlyDayRecurrence
                    monthlyScheduleType = $value.monthlyScheduleType
                    saturday = $value.saturday
                    startingOn = $value.startingOn
                    sunday =$value.sunday
                    thursday = $value.thursday
                    tuesday = $value.tuesday
                    wednesday = $value.wednesday
                    weeks = $value.weeks}  

                    $autoChangeSchedule= @{
                        dirty = $true
                        value = @{ policyApplyType =  $item.autochangeSchedule.policyapplytype
                            value = $ivalue }
                        }
                    $rpcitems=@{
                    autoChangeSchedule = $autoChangeSchedule
                    autoChangeOnExpiration = $autoChangeOnExpiration
                    heartBeatEnabled = $heartBeatEnabled
                    }

                    
                    
                    
                    
   
        

       
        #Create Policy Base Info Json
        $policyBase = @{
            secretPolicyName = $policy.secretPolicyName
            secretPolicyDescription = $policy.secretPolicyDescription
            Active = $policy.active
            }
        $payload = @{ data = $policyBase }
        $body = $payload | ConvertTo-Json -Depth 5
        $fileName=$policy.secretPolicyName
        $ext=".txt"
        $fileName = "$jsonExportFolder$fileName$ext"
        $body | Out-File $fileName
        
        #Create Policy update Json
        $data = @{ rpcItems = $rpcitems
           generalitems = $generalitems 
           securityItems =$securityItems
          }
        $payload = @{ data = $data }
        $body = $payload | ConvertTo-Json -Depth 5
        $fileName=$policy.secretPolicyName
        $json=".json"
        $fileName = "$jsonExportFolder$fileName$json"
        #$result = Invoke-RestMethod -Uri $uri -Method Patch -Headers $theaders -Body $body -ContentType "application/json" -InformationAction Ignore
        $body | Out-File $fileName
    }
    catch
    {
        $message = $Error[1]
        Write-Warning "Failed to update policy JSON    $message"
        exit 1    
    }
}       
get_policies 
Write-Host "Migration Complete"

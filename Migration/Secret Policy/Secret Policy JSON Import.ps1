<#
    .SYNOPSIS
     Imports all Secret Policies to a target Secret Server insance from json files 

    .DESCRIPTION
    This script will use the REST API to import Secret Policies from properly formated JSON files. These files can be create be an companion script "Secret Policy json Export.ps1"
    the export scrip will create the json files from a source instance and this script will inport those json file into a target instance and update or cretae the corresponding policies 
    The script is dependant on the Secrer Policy name. If a change is made to the name of a policy a new policy will be created in teh target instance
    
    .RREQUIREMENTS
    The credentials being used must have the Administer Secret Policy Rolepermissionand basic user permissions
    The base usrl for source and target inctances

    .PARAMETERS
    site  Base url of the source secret server instance
        Example: https:\\mysecretserver.mydoman.com\secretserver
    tsite  Base url of the target secret server instance
        Example: https:\\myOthersecretserver.mydoman.com\secretserver
    
    $jsonExportFolder This is the folder that the script will import all json files from
        Note the Base Secrit Policyjson will have a  .txt extension.  All filenames will be derived from teh Secret Policy name  
    
    $apiTake The maximum number of policies that the scrip will migrate.
        Value range 0-1000 
    
    .NOTES
    
    .REVISION HISTORY
    Wrtittem By: Rick Roca
    Original Date: 6/13/2022
    Modified:9/28/2022 
    Rev 2.1

#>

#Set Parameters

$tsite = "https://ps19.thycotic.blue/secretserver" #Must be set to the base url of secret server in  your environment with no trailing slash
$tapi = "$tsite/api/v2" # Do Not Change

$jsonExportFolder = "c:\temp\ps01\"
$apiTake = 300


#get target token target

try
    {
        $AuthToken = Get-Credential -Message "Enter credentials for Target instance"
        $creds =@{
        username = $AuthToken.UserName
        password = $AuthToken.GetNetworkCredential().Password
        grant_type = "password" }
    
    $token = ""
    $response = Invoke-RestMethod -Uri "$tsite/oauth2/token" -Method Post -Body $creds
    $token = $response.access_token;

   
    $theaders = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $theaders.Add("Authorization", "Bearer $token")
  
    }
      
catch
    {
        $message = $Error[0]
        Write-Error "Target Authentication failed    $message"
        exit 1
    }
    


Function get_policies
{
 
    try
    {
 
        
        #get all policies from source
       $policies =  Get-ChildItem $jsonExportFolder -Name "*.json"
        foreach($policy in $policies)
        {
            $policyName = $policy
            $policyName = $policyName -replace ".json",""
          
            update_policies -policy $policyName 
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
    $bodyfile = $policy , ".txt" -join ""
    $bodyfile= $jsonExportFolder, $bodyfile -join "" 
    $body = Get-Content -Path $bodyfile
    
    $result = Invoke-RestMethod -uri "$tapi/secret-policy" -Method Post -Headers $theaders -Body $body -ContentType "application/json"
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
    $policyName = $policy
    $uri = "$tsite/api/v1/secret-policy/search"
    $results = Invoke-RestMethod -Uri $uri -Headers $theaders 
      
    $found = $false
    foreach ($tPolicy in $results.records)
    {
    
     if ($policyName -eq $tPolicy.secretPolicyName)
     {
        $found = $true

        break
     }
    } 
   
    if ($found -eq $false){
      
        create_policies -policy $policy 
    }
    $uri = "$tsite/api/v1/secret-policy/search?filter.active=$true&take=$apiTake"
    $result = Invoke-RestMethod -Uri $uri -Headers $theaders 
    foreach ($Policy in $result.records)
    {
     if ($policyName -eq $Policy.secretPolicyName)
     {
        

        break
     }
    } 
    $targetPolicyId = $policy.secretPolicyId
    $uri = "$tapi/secret-policy/$targetPolicyId"
    $bodyfile = $policyName , ".json" -join ""
    $bodyfile= $jsonExportFolder, $bodyfile -join "" 
 
    $body = Get-Content -Path  $bodyfile 
    $result = Invoke-RestMethod -Uri $uri -Method Patch -Headers $theaders -Body $body -ContentType "application/json" -InformationAction Ignore
       
    }
    catch
    {
        $message = $Error[1]
        Write-Warning "Failed to update policy    $message"
        exit 1    
    }
}       
get_policies 
Write-Host "Secret Policy Import Complete"


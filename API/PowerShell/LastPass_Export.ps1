# USE THIS SCRIPT TO IMPORT DATA FROM LASTPASS TO SECRET SERVER

# The LastPass browser extension must be installed in the user's browser
# Open the extension and click on the users name -> Advanced -> Export -> LastPass CSV File
# Save this script in the same directory as the LastPass csv file
# LastPass csv columns are mapped to the new Secret fields in this script as follows:
#     name -> Secret Name
#     url -> Domain
#     username -> Username
#     password -> Password

Import-CSV <File path to LastPass .csv export> | Foreach-Object {

try{
   $site = "<secretserverURL>"
   $api = "$site/api/v1"
   $creds = @{
       username = "<username>"
       password = "<password>"
       grant_type = "password"
   }

    $token = ""

    $response = Invoke-RestMethod "$site/oauth2/token" -Method Post -Body $creds
    $token = $response.access_token;

    Write-Host $token

    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("Authorization", "Bearer $token")

    # Specify template ID (use 6001 for basic active directory accounts)
    $templateId = 6001 
    
    # CHANGE TO WINDOWS ACCOUNT TEMPLATE FOR SERVER LOGINS
    # DIFFERENTIATE BETWEEN SERVER LOGINS AND AD ACCOUNTS THEN CALL REST API FOR EACH TO CREATE THEM SEPARATELY WITH THE CORRECT TEMPLATE
#    foreach ($item in $data) {
 #   if ($item.extra -match 'Hostname') {
  #      $hostname = $item.extra
   #     Write-Host $hostname
    #}
#}

    ### INSERT CODE TO EXCLUDE DATABASE LOGINS

    #Send request to RESTful web service
    $secret = Invoke-RestMethod $api"/secrets/stub?filter.secrettemplateid=$templateId" -Headers $headers

  # Uncomment if $templateId variable set
    $secret.secretTemplateId = $templateId

  # Map Secret fields to import variables or static values
    $secret.name = $_.name
    $secret.SiteId = 1

  # Sepcify folder ID of folder for secrets to be created in - leave commented out to create secrets at root (no folder assignment)
  # FolderId can be found in folder's Secret Server URL
    $secret.folderId = 2

  # Set to $true or $false as needed- applies to all secrets in csv import
  # $secret.requiresComment = $true
  # $secret.AutoChangeEnabled = $true
  # $secret.IsDoubleLock = $true

   foreach($item in $secret.items)
    {
      if($item.fieldName -eq "Domain")
      {
        $item.itemValue = "$($_.url)"
      }
      if($item.fieldName -eq "Username")
      {
        $item.itemValue = "$($_.username)"
      }
      if($item.fieldName -eq "Password")
      {
        $item.itemValue = "$($_.password)"
      }
      if($item.fieldName -eq "Machine")
      {
        $item.itemValue = "$($serverName)"
      }
  # The following statement inserts "Imported from Lastpass" into the notes field but can be changed to whatever you want
      if($item.fieldName -eq "Notes")
      {
        $item.itemValue = "Imported from LastPass"
      }
    }

    $secretArgs = $secret | ConvertTo-Json

    #create
    Write-Host ""
    Write-Host "-----Create secret -----"

    $secret = Invoke-RestMethod $api"/secrets/" -Method Post -Body $secretArgs -Headers $headers -ContentType "application/json"
   
    $secret1 = $secret | ConvertTo-Json
    Write-Host $secret1
    Write-Host $secret.id
    }

catch [System.Net.WebException] {
    Write-Host "----- Exception -----"
    Write-Host  $_.Exception
    Write-Host  $_.Exception.Response.StatusCode
    Write-Host  $_.Exception.Response.StatusDescription
    $result = $_.Exception.Response.GetResponseStream()
    $reader = New-Object System.IO.StreamReader($result)
    $reader.BaseStream.Position = 0
    $reader.DiscardBufferedData()
    $responseBody = $reader.ReadToEnd()

    Write-Host $responseBody
    }
}

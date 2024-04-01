[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
# This script allows you to generate an OAUTH token (for use in additional REST API queries).
# It uses either the local TSS CLI application, or the `oauth/token` generator endpoint on the SS REST API.
# Choose a function below in order to use one of the functions in this script, or pull the functions out and use them elsehwere.
# Global Variables
$LogPath = "C:\tasks\script.log"
$ssurl = "https://sspm.thylab.local/SecretServer"
$api = "$site/api/v1"
$jsonfilepath = "C:\tasks\oauth2_grant.json"
$token = ""
    function Write-Log {
        param (
            [Parameter(Mandatory=$True,ValueFromPipeline =$True)] $logItem
        )
        [string]$TimeStamp = Get-Date 
        "[$TimeStamp]: " + $logitem | Out-File -FilePath $LogPath -Append
    }
    function Get-TokenTSS { 
        try
        {
            $cmdPath = 'C:\tss\tss.exe' 
            $cmdArgList = @( 
            "-cd","C:\tss"
            "token"
            ) 
            return & $cmdPath $cmdArgList 
        }
        catch
        {     
            Write-Log $("Error retrieving token via TSS | Error Details: " + $_)
        }   
} 
  function Get-TokenCreds { 
    try
    {
        $creds = @{
            username = "<ssusername>"
            password = "<sspassword>"
            grant_type = "password"
        }
        $response = Invoke-RestMethod "$ssurl/oauth2/token" -Method Post -Body $creds
        $bearertoken = $response.access_token;
        Write-Log $("Retrieved token via Direct Credentials")
        return $bearertoken
    }
    catch
    {
        Write-Log $("Error retrieving token via credentials | Error Details: " + $_)
    }
}
# Functional calls - dependent on method - choose one
#$token = Get-TokenTSS
$token = Get-TokenCreds
# Copy the token contents to a local JSON file
if($token)
    {
    $token | Out-File -FilePath $jsonfilepath -Force
    Write-Log $("Token successfully retrieved and written to $jsonfilepath")
    }
else
    {
    Write-Log $("Error writing token | Error Details: " + $_)
    }

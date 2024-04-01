#Ensure that you have the necessary permissions and access rights within the CyberArk environment to interact with the REST API.
#Open an elevated PowerShell session.
#Define the following variables at the beginning of your script or session:
$CyberArkURL = "https://your-cyberark-instance.com"  # Replace with your CyberArk instance URL
$Username = "your-username"                         # Replace with your username
$Password = "your-password"                         # Replace with your password
$SafeName = "your-safe-name"                         # Replace with the name of the safe from which you want to export passwords
$OutputFilePath = "C:\Path\to\Output\File.csv"       # Replace with the desired file path where you want to save the exported passwords (ensure the file has a .csv extension)
#Define a function to authenticate and obtain an access token for the CyberArk REST API:
function Get-CyberArkAccessToken {
    $RequestBody = @{
        username = $Username
        password = $Password
    }
    $AuthURI = "$CyberArkURL/PasswordVault/API/auth/ldap"
    $AuthResponse = Invoke-RestMethod -Uri $AuthURI -Method Post -Body ($RequestBody | ConvertTo-Json) -ContentType "application/json"
    return $AuthResponse.CyberArkToken
}
#Define a function to retrieve the passwords from the specified safe:
function Export-CyberArkSafePasswords {
    $Token = Get-CyberArkAccessToken
    $Headers = @{
        "Authorization" = "Bearer $Token"
        "Content-Type" = "application/json"
    }
    $SafesURI = "$CyberArkURL/PasswordVault/WebServices/PIMServices.svc/Safes"
    $SafeURI = "$SafesURI('$SafeName')/Accounts"
    $SafeResponse = Invoke-RestMethod -Uri $SafeURI -Headers $Headers
    $Passwords = $SafeResponse.Accounts | Select-Object -Property UserName, Address, PasswordChangeInProcess, Disabled, LastPasswordUpdate
    $Passwords | Export-Csv -Path $OutputFilePath -NoTypeInformation
}
#Call the Export-CyberArkSafePasswords function to export the passwords:
Export-CyberArkSafePasswords
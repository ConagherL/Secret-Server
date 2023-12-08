# Script parameters
$sourceServerUrl = 'https://blt.secretservercloud.com/'
$targetServerUrl = 'https://ss.blt.com/SecretServerDR'

# Import the Thycotic Secret Server module
Import-Module Thycotic.SecretServer

try {
    # Authentication for the source Secret Server
    $sourceCred = Get-Credential -Message "Enter credentials for the source Secret Server"
    $sourceSession = New-TssSession -SecretServer $sourceServerUrl -Credential $sourceCred

    # Authentication for the target Secret Server
    $targetCred = Get-Credential -Message "Enter credentials for the target Secret Server"
    $targetSession = New-TssSession -SecretServer $targetServerUrl -Credential $targetCred

    # Retrieve all users from the source server
    $sourceUsers = Find-TssUser -TssSession $sourceSession

    # Array to hold updated user records
    $updatedUsers = @()

    # Loop through each user from the source server
    foreach ($sourceUser in $sourceUsers.records) {
        try {
            $sourceUserDetails = Get-TssUser -TssSession $sourceSession -UserId $sourceUser.id

            # Find the matching user on the target server by username
            $targetUserSearch = Find-TssUser -TssSession $targetSession -FindText $sourceUserDetails.UserName

            # Check if the user exists on the target server
            if ($targetUserSearch.records) {
                $targetUserDetails = Get-TssUser -TssSession $targetSession -UserId $targetUserSearch.records[0].id

                # Update the RADIUS username on the target server
                $targetUserDetails.RadiusUsername = $sourceUserDetails.RadiusUsername
                Update-TssUser -TssSession $targetSession -Id $targetUserDetails.Id -User $targetUserDetails

                # Add the updated user to the array
                $updatedUsers += $targetUserDetails
            }
        } catch {
            Write-Host "Error processing user $($sourceUser.id): $_"
        }
    }

    # Output the records that were updated
    $updatedUsers | Format-Table -Property Id, UserName, RadiusUsername

} catch {
    Write-Host "Error in script: $_"
}
} finally {
    # Optional: Expire the session tokens after processing
    $sourceSession.SessionExpire()
    $targetSession.SessionExpire()
}

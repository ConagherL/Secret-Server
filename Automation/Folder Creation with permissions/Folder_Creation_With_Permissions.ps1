#   Authentication  #
$SecretServerURL = "YOUR SS URL"
$cred = Get-Credential

#   Folder and Group Arguments  #
$PFoldername = Read-Host -Prompt 'Enter the name of the parent folder' 
$FolderName = Read-Host -Prompt 'Enter the name of the new folder' 
$FolderOwnerGroups =  @("SEC_SS_Users","SEC_SS_Admins")  # each group should be wrapped in "" and seperated by a , : Names must match Secret Server group name

#   Policy Information  #
$ParentPolicyID = 1
$SubPolicyID = 1


#   Obtain a token  #
try {
    $Session = New-TssSession -SecretServer $SecretServerURL -Credential $cred
} catch {
    Write-Error "Failed to create TSS session: $_"
    break
}

#   Check for exsiting parent folder and create if missing. Also apply the secret policy to the folder  #
$existingFolder = Search-TssFolder -TssSession $Session -SearchText $PFolderName
    if ($null -eq $existingFolder) {
        $PnewFolder = New-TssFolder -TssSession $Session -FolderName $PFolderName -SecretPolicyId $ParentPolicyID -InheritPermissions:$false -InheritSecretPolicy:$false
    }
        else
            { Write-Error ("Folder Exists:" + $existingFolder.FolderId) }
            #   Set the owners on the folder/secret #
                foreach ($GroupName in $FolderOwnerGroups)
                    {Add-TssFolderPermission -TssSession $Session -FolderId $PnewFolder.id -Group $GroupName -FolderRole "owner" -SecretRole "owner" | Out-Null }
            #   Collect the parent ID to use in the sub folder creation process #
            $PFolderBaseID = Search-TssFolder -TssSession $Session -SearchText $PFoldername


#   Check for exsiting sub folder  #
$existingSubFolder = Search-TssFolder -TssSession $Session -ParentFolderId $PFolderBaseID.Id -SearchText $FolderName
    if ($null -eq $existingSubFolder) {
        $newFolder = New-TssFolder -TssSession $Session -FolderName $FolderName -SecretPolicyId $SubPolicyID -ParentFolderId $PFolderBaseID.Id -InheritPermissions:$false -InheritSecretPolicy:$false
    }
        else
            { Write-Error ("Folder Exists:" + $existingSubFolder.FolderId) }
                #   Set the owners on the folder/secret #
                    foreach ($GroupName in $FolderOwnerGroups)
                        {Add-TssFolderPermission -TssSession $Session -FolderId $newFolder.id -Group $GroupName -FolderRole "owner" -SecretRole "owner" | Out-Null }

####
# Name: Create-ITAdminFolders
#
# Created by: Chad Sigler
# Last updated: 20220720
#
# Description: Automates the onboarding/offboarding of users.
#   Get parent folder
#   Get all users in the required group
#   Get id of user
#   Create folder named "Username of User"
#   User should be Add secret/Edit
#   Owner group will own the folder
#   Remove user that created folder
#   Move all folders that do not have a matching username to a discard folder
# 
# 
# Usage: 
# General Usage
# #Create-UserFolders uri configpath apiUserId parentFolderId userGroupId ownerGroupId discardFolderId logPath
#
# Create-UserFolders https://secretserver.example.com' 'C:\TSS-SDK\Config' 8 233 25 12 8 'C:\TSS-SDK\Logs'
#
####

Import-Module Thycotic.SecretServer

function Create-UserFolders { 
    param($uri, $configpath, $apiUserId, $parentFolderId, $userGroupId,$ownerGroupId,$discardFolderId, $logPath)

    $d = Get-Date -Format "yyyyMMdd_HH-mm-ss"
    $logFilePath = $logPath + $d.ToString() + ".log"    
    Start-TssLog -LogFilePath $logFilePath -LogFormat log

    $session = New-TssSession -SecretServer $uri -UseSdkClient -ConfigPath $configpath

    # Get the group object userGroupId
    $message = "--------- Get the group object group ID: " + $userGroupId
    Write-TssLog -LogFilePath $logFilePath -LogFormat 'log' -MessageType INFO -Message $message  
    
    $group = Get-TssGroup -TssSession $session -Id $userGroupId
    $message = "Group Details: " + $group.GroupId.ToString() + " - " + $group.GroupName
    Write-TssLog -LogFilePath $logFilePath -LogFormat 'log' -MessageType INFO -Message $message  

    # Get the group members of userGroupId
    $message = "--------- Get the group members of Group ID:" + $userGroupId
    Write-TssLog -LogFilePath $logFilePath -LogFormat 'log' -MessageType INFO -Message $message  
    $groupMembers = Get-TssGroupMember -TssSession $session -Id $userGroupId
    foreach ($gm in $groupMembers) {       
        $message =  "Group Member: " + $gm.UserId + " - " + $gm.Username + " - " + $gm.DisplayName
        Write-TssLog -LogFilePath $logFilePath -LogFormat 'log' -MessageType INFO -Message $message  
    }
 

    # Get all existing folders in parentFolderId
    $message = "--------- Get all existing child folders in Parent Folder: " + $parentFolderId
    Write-TssLog -LogFilePath $logFilePath -LogFormat 'log' -MessageType INFO -Message $message  
    
    $parentFolderChildren = Get-TssFolder -TssSession $session -FolderId $parentFolderId -GetChildren
    foreach ($f in $parentFolderChildren.ChildFolders) {
        $message = "Child Folder: " + $f.FolderId.ToString() + " - " + $f.FolderName.ToString()  
        Write-TssLog -LogFilePath $logFilePath -LogFormat 'log' -MessageType INFO -Message $message     
    }
   

    # Get Folders that need to be moved
    $message = "--------- Get list of folders that need to be moved"
    Write-TssLog -LogFilePath $logFilePath -LogFormat 'log' -MessageType INFO -Message $message
    $needToMoveFolders = $parentFolderChildren.ChildFolders | Where-Object { $_.FolderName -notin $groupMembers.Username}
    
    # Move Folder that need to be moved
    $message = "--------- Move folders that need to be moved"
    Write-TssLog -LogFilePath $logFilePath -LogFormat 'log' -MessageType INFO -Message $message  
    foreach($needToMoveFolder in $needToMoveFolders) {
        $message = "Move Folder: " + $needToMoveFolder.FolderName +" - " + $needToMoveFolder.FolderId
        Write-TssLog -LogFilePath $logFilePath -LogFormat 'log' -MessageType INFO -Message $message  
        $outputMessage = Move-TssFolder -TssSession $session -Id $needToMoveFolder.FolderId -ParentFolderId $discardFolderId         
    }

    # Get list of folders that need to be created
    $neededFolders = $groupMembers.Username | Where-Object { $_ -notin $parentFolderChildren.ChildFolders.FolderName}
    foreach($neededFolder in $neededFolders) {
        
        # Create Folder
        $createdFolder = New-TssFolder -TssSession $session -FolderName $neededFolder -ParentFolderId $parentFolderId -InheritPermissions:$false
        $message = "Created: " + $createdFolder.FolderId + "     " + $createdFolder.FolderName 
        Write-TssLog -LogFilePath $logFilePath -LogFormat 'log' -MessageType INFO -Message $message
        
        # Grant user to folder rights       
        $theseUsers = Search-TssUser -TssSession $session  -Field Username -SearchText $neededFolder    
        $thisUser = $theseUsers[0]    
        
        $ownerUserPermission = New-TssFolderPermission -TssSession $session -FolderId $createdFolder.FolderId -UserId $thisUser.Id -FolderAccessRoleName 'Add Secret' -SecretAccessRoleName Edit -Force
        $message = "Grant User ID: " + $thisUser.Id + " - " + $thisUser.Username + " - Add secret/Edit Rights"
        Write-TssLog -LogFilePath $logFilePath -LogFormat 'log' -MessageType INFO -Message $message

        # Grant Owner to owner group
        $adminGroupPermission = New-TssFolderPermission -TssSession $session -FolderId $createdFolder.FolderId -GroupId $ownerGroupId -FolderAccessRoleName Owner -SecretAccessRoleName Owner -Force
        $message = "Grant Group ID: " + $ownerGroupId +" - Add Owner/Owner Rigts"
        Write-TssLog -LogFilePath $logFilePath -LogFormat 'log' -MessageType INFO -Message $message
        
        # Remove API User Access
        $apiUserIdPermission = Search-TssFolderPermission -TssSession $session -FolderId $createdFolder.FolderId -UserId $apiUserId    
        $removePermissionResult = Remove-TssFolderPermission -TssSession $session -Id $apiUserIdPermission.Id
        $message = "Removed User rights from ID: " + $apiUserId
        Write-TssLog -LogFilePath $logFilePath -LogFormat 'log' -MessageType INFO -Message $message
    }

}
#Create-UserFolders uri configpath apiUserId parentFolderId userGroupId ownerGroupId discardFolderId logPath
Create-UserFolders 'https://app.ben.local' 'C:\Temp\api1-a' 3 11 8 9 18 'C:\Temp\logs\' 

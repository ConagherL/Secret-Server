This PowerShell script creates a new subfolder in Secret Server, sets its owners, and applies a secret policy to it. The script prompts the user to enter the name of the parent folder, the name of the new folder, and the groups that should be set as owners.

Authentication
The first section of the code includes the Secret Server URL and the credentials required for authentication. The user is prompted to enter the credentials using the Get-Credential command.

Folder and Group Arguments
The user is then prompted to enter the name of the parent folder and the name of the new subfolder. The script also includes a list of group names that should be set as owners for the new subfolder.

Policy Information
The script includes two variables for policy information: $ParentPolicyID and $SubPolicyID. These variables hold the policy IDs for the parent folder and the subfolder, respectively.

Obtain a Token
The script attempts to create a new session with the Secret Server using the New-TssSession command. If the session is not created successfully, the script displays an error message.

Check for Existing Parent Folder and Create if Missing
The script checks if the parent folder exists by using the Search-TssFolder command with the name of the parent folder. If the parent folder does not exist, the script creates a new folder using the New-TssFolder command and applies the parent policy to it. If the parent folder exists, the script displays an error message.

The script sets the owners of the parent folder using the Add-TssFolderPermission command and the list of group names. The $PFolderBaseID variable holds the ID of the parent folder to be used in the creation of the subfolder.

Check for Existing Subfolder and Create if Missing
The script checks if the subfolder already exists by using the Search-TssFolder command with the name of the subfolder and the ID of the parent folder. If the subfolder does not exist, the script creates a new folder using the New-TssFolder command and applies the subfolder policy to it. If the subfolder exists, the script displays an error message.

The script sets the owners of the subfolder using the Add-TssFolderPermission command and the list of group names.

Usage
To use this script, the user should replace the $SecretServerURL, $ParentPolicyID, and $SubPolicyID variables with the appropriate values for their Secret Server environment. The user should also enter the name of the parent folder, the name of the new subfolder, and the list of group names when prompted. The script can be executed using a PowerShell console or ISE.
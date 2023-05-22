# Set the download URL, destination folder, and destination file path
$DownloadUrl = "https://vdc-download.vmware.com/vmwb-repository/dcr-public/db25b92c-4abe-42dc-9745-06c6aec452f1/d15f15e7-4395-4b4c-abcf-e673d047fd29/VMware-PowerCLI-11.4.0-14413515.zip"
$DestinationFolder = "C:\Program Files\VMware\VMware-PowerCLI-11.4.0-14413515\"
$DestinationFilePath = Join-Path $DestinationFolder "VMware-PowerCLI-11.4.0-14413515.zip"

# Create the destination folder if it doesn't exist
if (-not (Test-Path $DestinationFolder)) {
    New-Item -ItemType Directory -Path $DestinationFolder | Out-Null
}

# Download the ZIP file
Invoke-WebRequest -Uri $DownloadUrl -OutFile $DestinationFilePath

# Extract the ZIP file
Expand-Archive -Path $DestinationFilePath -DestinationPath $DestinationFolder

# Add the new path to the system environment variable
$NewPath = "C:\Program Files\VMware\VMware-PowerCLI-11.4.0-14413515\VMware.Vim\net45"
$CurrentPath = [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::Machine)
if (-not ($CurrentPath -split ";" -contains $NewPath)) {
    $NewPathValue = $CurrentPath + ";" + $NewPath
    [Environment]::SetEnvironmentVariable("Path", $NewPathValue, [EnvironmentVariableTarget]::Machine)
}

# Unblock the DLL
$DLLPath = "C:\Program Files\VMware\VMware-PowerCLI-11.4.0-14413515\VMware.Vim\net45\VMware.vim.dll"
if (Test-Path $DLLPath) {
    Unblock-File -Path $DLLPath
}

# Prompt the user to reboot the system
$Message = "The script has completed its tasks. Do you want to reboot the system now? (Select 'No' to reboot later)"
$Yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", "Reboot the system now."
$No = New-Object System.Management.Automation.Host.ChoiceDescription "&No", "Reboot the system later."
$Options = [System.Management.Automation.Host.ChoiceDescription[]]($Yes, $No)
$Result = $host.ui.PromptForChoice("Reboot System", $Message, $Options, 0)

switch ($Result) {
    0 { Restart-Computer }
    1 { Write-Host "You chose to reboot the system later." -ForegroundColor Yellow }
}

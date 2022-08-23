# Introduction

This document provides the details for creating a custom Launcher for Putty that uses XMING.exe and X11 Forwarding with RDS

## Template

The built-in template that is named "Unix Account (SSH)" can be leveraged for this launcher. We recommend copying this template and then renaming it appropriately to something like "Unix Account (SSH) - X11 Xming"


## Script 

A copy of the powershell script leveraged as part of this launcher can be found below and (attached). This script is stored in `C:\tools` folder from the system that is leveraging the launcher.



<details>
  <summary>Click to View Powershell Script </summary>

```
param( $machine, $username, $password )

echo "
 _____ _                     _   _
|_   _| |__  _   _  ___ ___ | |_(_) ___
  | | | '_ \| | | |/ __/ _ \| __| |/ __|
  | | | | | | |_| | (_| (_) | |_| | (__
  |_| |_| |_|\__, |\___\___/ \__|_|\___|
             |___/
"

echo "Calculating next screen available for XMing"

$first_port = 6000
$list = netstat -an |Select-String 'TCP(.*)0\.0\.0\.0\:60[0-9]{2}(.*)LISTENING' |ConvertFrom-String |select p3
if($list.count -eq 0){
    $next_screen = 0
}
else{

    $list = $list | ForEach {($_.p3 -split(':'))[1]-$first_port}

    $next_screen = -1
    for ($i=0; $i -lt $list.count; $i++){
        if($i -lt $list[$i]){
            $next_screen = $i
            break
        }
    }
    if($next_screen -eq -1){
        $next_screen = $list.count
    }
}

echo "Next Screen: $next_screen"
    
$env:DISPLAY = ":$next_screen"

echo "Launching XMing"
& 'C:\Program Files (x86)\Xming\Xming.exe' :$next_screen -multiwindow -clipboard

echo "Launching Putty"
& 'C:\tools\putty.exe' -X -ssh $machine -l $username -pw $password
```
</details>

# Create Launcher

1. Navigate to **Admin | Secret Templates**
1. Click **Configure Launchers** button
1. Click **New**
1. Enter a **Launcher Name** ex: `XMING X11 Fwd SSH Non-Proxied`
1. Enter the **Process Name**: `powershell.exe`
1. Enter the **Process Arguments**: `-file C:\tools\launch_xming.ps1 $MACHINE $USERNAME $PASSWORD`
1. Checkmark **Wrap custom parameters with quotation marks** option
1. For **Record Additional Processes** enter `xming.exe`
1. Click **Save**


# Configure Template Launcher

1. Navigate to **Admin | Secret Templates**
1. Select your template
1. Click **Edit**
1. Click **Configure Launcher**. If there is an existing launcher associated to the template, remove it
1. Click **Add New Launcher**
1. Select XMING X11 Fwd SSH Non-Proxied for **Launcher Type to use**
1. Set **Machine** to `Machine`
1. Set **Password** to `Password`
1. Set **Username** to `Username`
1. Click **Save**

Create a secret and test/verify the launcher functions properly.

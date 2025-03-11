################################################################################
# Selenium Example for the pfSensse Web UI to change the password for the user #
################################################################################
# Version: 0.1 | Willem Essenstam | Initial version for deployment             #
################################################################################

#############################
# Parameters Area of script #
# from Secret Server RPC    #
#############################
$Method=$args[0] # Do we need to perform a HeartBeat(HB) or RPC(RPC)?
$url=$args[1]
$username=$args[2]
$current_pwd=$args[3]
$new_pwd=$args[4]

$tempfile="$env:TEMP\pfSense_RPC.txt"
$today=Get-Date

# Get some timestamps and info into the file
Add-Content -Path $tempfile -Value "----------------------------------------"
Add-Content -Path $tempfile -Value "$Method Run $Today"

###########################
# Function Area of script #
###########################

Function Get_ChromeWebDriver{
    Try {
        # Set the Output location of the chromedriver.exe
        $ChromeDriverOutputPath="$Selenium_path\assemblies\"
        # Get the current version of the installed Chrome browser
        $ChromeVersion=(Get-Item (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\chrome.exe' -ErrorAction Stop).'(Default)').VersionInfo.FileVersion
        $ChromeVersion = $ChromeVersion.Substring(0, $ChromeVersion.LastIndexOf("."))
        # Grab the list of chromedrivers.exe based on the version of Chrome
        $ChromeDriverVersion = Invoke-WebRequest "https://googlechromelabs.github.io/chrome-for-testing/LATEST_RELEASE_$ChromeVersion" -ContentType 'text/plain' |   Select-Object -ExpandProperty Content
        $ChromeDriverVersion = [System.Text.Encoding]::UTF8.GetString($ChromeDriverVersion)
        $Today=Get-Date
        Add-Content -Path $tempfile -Value "Latest matching version of Chrome Driver is $ChromeDriverVersion on $Today"

        $DownloadUrl = Invoke-WebRequest 'https://googlechromelabs.github.io/chrome-for-testing/known-good-versions-with-downloads.json' `
                | Select-Object -ExpandProperty Content `
                | ConvertFrom-Json `
                | Select-Object -ExpandProperty versions `
                | Where-Object { $_.version -eq $ChromeDriverVersion } `
                | Select-Object -ExpandProperty downloads `
                | Select-Object -ExpandProperty chromedriver `
                | Where-Object { $_.platform -eq "win64" } `
                | Select-Object -ExpandProperty url

        $TempFilePath = [System.IO.Path]::GetTempFileName()
        $TempZipFilePath = $TempFilePath.Replace(".tmp", ".zip")
        Rename-Item -Path $TempFilePath -NewName $TempZipFilePath
        $TempFileUnzipPath = $TempFilePath.Replace(".tmp", "")

        Invoke-WebRequest $DownloadUrl -OutFile $TempZipFilePath

        # Extract the downloaded ZIP file for Windows 64 O/S and save it in the Selenium Module Assemblies directory
        Expand-Archive $TempZipFilePath -DestinationPath $TempFileUnzipPath
        Get-Childitem $TempFileUnzipPath  -Recurse -File -Filter 'chromedriver*' | Move-Item -Destination $ChromeDriverOutputPath -Force

        # Clean up temp files
        Remove-Item $TempZipFilePath
        Remove-Item $TempFileUnzipPath -Recurse
    }
    catch{
        # If an error occured during the download, extraction or moving the chromedriver.eze file, report back
        Throw "Error on downloading the Chrome driver. Please manually download and save the Chrome webdriver from $DownloadUrl"
    }

}


# Import Selenium Module if it has been installed. If not, stop the script
try{
    # Is the Selenium Module imported?
    Import-Module Selenium -ErrorAction Stop
}
catch{   
    # As we haven't found the Module for Selenium, we gonna have to stop the script. This is a prerequisite!
    Throw "The Selenium PowerShell Module has not been installed. Stopping the script"
}


# Check the Chromewebdriver is installed in the correct location
try{
    # Get the Module Path from PowerShell and see if there is a version of Chromedriver.exe available
    $Selenium_path=(Get-Module Selenium).path.substring(0,((get-module Selenium).Path).LastIndexOf("\")+1)
    Get-ChildItem "$Selenium_path\assemblies\chromedriver.exe" -ErrorAction Stop | Out-Null
    
    # Get the write date of the file to see how old the file is
    $ChromeDriver_Date=(((get-item 'C:\Program Files\WindowsPowerShell\Modules\Selenium\3.0.1\assemblies\chromedriver.exe').LastWriteTime.Date) -replace('\s',';') -split(';'))[0] -replace('/','-')
    $Delta_time=New-Timespan -Start $ChromeDriver_Date -End (Get-Date)
    
    # If the file last write is plder then 180 days (6 months) pull a new version that is corresponding to the version of Chrome
    if ($Delta_time.Days -gt 180){ 
        Add-Content -Path $tempfile -Value "The current Chrome driver is old. Replacing with current version..."
        Rename-Item -Path "$Selenium_path\assemblies\chromedriver.exe" -NewName "$Selenium_path\assemblies\chromedriver.exe.$ChromeDriver_Date"-ErrorAction Stop -Force | Out-Null
        Get_ChromeWebDriver
    }
} Catch {
    # As we couldn;t find the Chromedriver.exe, we need to download it anyway!
    Add-Content -Path $tempfile -Value "The Chromedriver has not been found... Solving.."
    Get_ChromeWebDriver
       
}

# Start Chrome browser
$Driver = Start-SeChrome -Arguments @("--remote-allow-origin","--silent",'Incognito',"--ignore-certificate-errors","--headless")

# Navigate to a specific URL
$Driver.Navigate().GoToUrl($url)

# Enter login
$Driver.FindElementById('usernamefld').SendKeys($username)

# Enter password
$Driver.FindElementById('passwordfld').SendKeys($current_pwd)

# Click the login button
$Driver.FindElementByXPath('//*[@id="iform"]/button').Click()

# Was the login correct?
Try{
 $Driver.FindElementByXPath('//*[@id="inputerrors"]') | Out-Null
 Add-Content -Path $tempfile -Value "Failed to log in"
 # Fully close the Selenium session
 $Driver.Quit()
 Exit(1)

}catch{
    # Successfull login
    Add-Content -Path $tempfile -Value "Logged in Successfull"

    if ($Method -eq "HB"){
     # For the HeartBeat script, only the below is needed:
     $Driver.Quit()
    }
    else{ # We need to run RPC
        
        # Click the Password Manager
        $Driver.FindElementByXPath('//*[@id="Lobby"]/a[3]').Click()

        # Fill Old password
        $Driver.FindElementByXPath('//*[@id="passwordfld0"]').SendKeys($current_pwd)

        # Fill New password
        $Driver.FindElementByXPath('//*[@id="passwordfld1"]').SendKeys($new_pwd)
        $Driver.FindElementByXPath('//*[@id="passwordfld2"]').SendKeys($new_pwd)

        # Click the Save button to have the new password
        $Driver.FindElementByXPath('//*[@id="iform"]/div/table/tbody/tr[6]/td[2]/input').Click()

        # Click the logout button
        $Driver.FindElementByXPath('//*[@id="Lobby"]/a[4]').Click()

        # Fully close the Selenium session
        $Driver.Quit()
        Add-Content -Path $tempfile -Value "Password Updated"
    }
 }
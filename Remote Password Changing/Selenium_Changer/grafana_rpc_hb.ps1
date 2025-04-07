# Script usage
# use powershell script for both hearthbeat and password changing.
# parameters to provide in each case are:
# Heartbeat: hb $url $username $password
# Password Change: rpc $url $username $password $newpassword

# Script uses PowerShell Selenium module v 4.0
# This module can be found on: https://github.com/adamdriscoll/selenium-powershell
# Full path to current version is: https://github.com/adamdriscoll/selenium-powershell/tree/master/Output/Selenium

$action = "hb"
$thy_url = "https://YOURURL"
$thy_username = "USERNAME"
$thy_password = "RANDOM VALUE"
$thy_newpassword = "RANDOM VALUE"

# param(
#     [parameter(Mandatory = $true, Position=0)]
#     [ValidateSet("hb", "rpc")]
#     [ValidateNotNull()]
#     [string]$action,
#     [parameter(Mandatory = $true, Position=1)]
#     [string]$thy_url,
#     [parameter(Mandatory = $true, Position=2)]
#     [string]$thy_username,
#     [parameter(Mandatory = $true, Position=3)]
#     [string]$thy_password,
#     [parameter(Mandatory = $false, Position=4)]
#     [string]$thy_newpassword
# )

function Invoke-BrowserStart {
    Write-Output 'Starting Browser for automated login'
    # Start browser in headless mode for RPC and HB
    $Options = New-SeDriverOptions -Browser Chrome -StartURL $thy_url
    # Disable headless mode while developing
    # $Options.AddArgument('headless')
    $Options.AcceptInsecureCertificates = $True
    $options.AddUserProfilePreference('credentials_enable_service', $false)
    $options.AddUserProfilePreference('profile.password_manager_enabled', $false)
    $script:driver = Start-SeDriver -Options $Options
}

function Invoke-Login {
    Write-Output 'Performing login process'
    # Automate login process by searching for right elements and entering username / password fields.
    # This is to be adjusted depending the website
    #Login process
    Wait-SeElement -By XPath -Value '//*[@id="pageContent"]/div[3]/div/div/div/div[2]/div/div/form/button/span' -Condition ElementToBeClickable | Out-Null 
    $element = Get-SeElement -By XPath -Value '//*[@id=":r0:"]' -Timeout 30
    Invoke-SeKeys -Element $Element -Keys $thy_username
    $element = Get-SeElement -By XPath -Value '//*[@id=":r1:"]' -timeout 30
    Invoke-SeKeys -Element $Element -Keys $thy_password
    $Element = Get-SeElement -By XPath -Value '//*[@id="pageContent"]/div[3]/div/div/div/div[2]/div/div/form/button/span' -Timeout 30
    Invoke-SeClick -Element $Element
}

function Invoke-CleanUp {
    Write-Output 'Cleaning up browser instances'
    #Close Selenium Driver
    Stop-SeDriver $Driver
}

function Invoke-HB {
    Write-Output 'Starting HB'
    # Check website login flow to determine a succesful login. In the code below there is being looked for a negative ok. 
    $LoginCheck = Get-SeElement -by CssSelector -Value '[data-testid="data-testid Alert error"]' -Timeout 10 -ErrorAction SilentlyContinue
    # Checking for Login failed message on web page indicating a failed login.
    if ($logincheck.Displayed -eq $true) {
        Write-Output 'HB Failed'
        Invoke-CleanUp
        throw 'HB Failed. Check credentials.'
    }
    else {
        Write-Output 'HB success'
    }
}

function Invoke-RPC {
    Write-Output 'Starting RPC'
    # Check website password change flow to determine exact process. In the code below a check is done that we are logged in.
    # Next we browse to the password change page and go through the password change process.
    # Adjust all checks and steps depending the website.
    # Check for succesful login
    $LoginCheck = Get-SeElement -by CssSelector -Value '#mega-menu-toggle' -Timeout 60 -ErrorAction SilentlyContinue
    if ($logincheck.Displayed -eq $true) {
        Write-Output 'login succesful performing rpc'
        # Navigate to password change URL
        set-seurl "$thy_url/profile/password"
        Wait-SeDriver -Condition TitleContains -Value 'Change password' -Timeout 30 | Out-Null 
        $PasswordChangeCheck = Get-SeElement -By XPath -Value '//*[@id="pageContent"]/div[3]/div/div/div[1]/div/div[1]/div/h1' -Timeout 30
        if ($PasswordChangeCheck.Displayed -eq $true) {
            $element = Get-SeElement -By XPath -Value '//*[@id="current-password"]' -Timeout 30
            Invoke-SeKeys -Element $Element -Keys $thy_password
            $element = Get-SeElement -By XPath -Value '//*[@id="new-password"]' -Timeout 30
            Invoke-SeKeys -Element $Element -Keys $thy_newpassword
            $element = Get-SeElement -By XPath -Value '//*[@id="confirm-new-password"]' -Timeout 30
            Invoke-SeKeys -Element $Element -Keys $thy_newpassword
            $element = Get-SeElement -By XPath -Value '//*[@id="pageContent"]/div[3]/div/div/div[2]/form/div[5]/button/span' -Timeout 30
            Invoke-SeClick -Element $Element
            }
        else {
            Write-Output 'Password change failed.'
            Invoke-CleanUp
            throw 'Page not loaded with password change fields. Check Website.'
        }
        # $check = Wait-SeElement -by CssSelector -value '[data-testid="data-testid Alert Success"]' -Timeout 30 -Condition ElementExists | Out-Null
        # start-sleep -s 10
#        $PasswordChangeSucceedCheck = Get-SeElement -by CssSelector -value '[data-testid="data-testid Alert Success"]' -Timeout 30
        $PasswordChangeSucceedCheck = Wait-SeElement -By CssSelector -Value '[data-testid="data-testid Alert success"]' -Timeout 30 -Condition ElementExists

        if ($PasswordChangeSucceedCheck -eq $true) {
        Write-Output 'Password Change Succeeded'
        }
        else {
            Write-Output 'Password change failed. Check Website.'
            Invoke-CleanUp
            throw 'Password change failed. Check website.'
        }
    }
    else {
        Write-Output 'Incorrect credentials causing RPC to fail.'
        Invoke-CleanUp
        throw 'Incorrect credentials causing RPC to fail. Check credentials.'
    }
}

if ($action -eq 'hb') {
    Invoke-BrowserStart
    Invoke-Login
    Invoke-HB
    Invoke-CleanUp
    Write-Output 'HB Completed'
}
elseif ($action -eq 'rpc') {
    Invoke-BrowserStart
    Invoke-Login
    Invoke-RPC
    Invoke-CleanUp
    Write-Output 'RPC Completed'
}
else {
    Write-Output 'No Action defined. Please define action as per documented parameters'
}
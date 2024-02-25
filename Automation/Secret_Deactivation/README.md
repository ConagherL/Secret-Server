# Automate secret cleanup by the usage of the secrets

This code allows an organization to output a list of secrets not accessed over 90 days (configurable) and include the user's (group or user directly assigned) email address. From there, the code has multiple functions. 

One function is to call the report. The following function will call the report, deactivate the secrets, and export the results to a flat file. The final function allows an organization to email the "owners" of the secrets to alert them of the deactivation process.

This code is not meant to be automated but used on an ad-hoc basis to address dead/inactive secrets.

## Table of Contents

- [Introduction](#introduction)
- [Features](#features)
- [Installation](#installation)
- [Usage](#usage)

## Introduction

Automate inactive Secret cleanup within a customer environment

## Features

List the key features of your project.

- Multiple functions in the code to allow different actions
- Updated Help sections to understand the code breakout

## Installation

- This code is dependent on the Thycotic Secret Server PowerShell Module. Please review any additional requirements [HERE](https://thycotic-ps.github.io/thycotic.secretserver/getting_started/install.html)

- Requires "Administer Reports" permissions in SS
- API account used must have access to all secrets within scope (Owner Rights)

```bash
$ git clone https://github.com/yourusername/yourproject.git
$ cd yourproject
$ npm install

Prerequisites
Thycotic.SecretServer PowerShell module installed.
PowerShell 5.1 or higher.
Usage
Load the Thycotic Secret Server Module

Ensure the Thycotic Secret Server module is loaded. If not, the script will terminate with an error message.

Establish a Session

The script will prompt for credentials to establish a new session with the Secret Server.

Invoke the Report

Use the Invoke-Report function to invoke a specified report from the Secret Server.

powershell
Copy code
Invoke-Report
Deactivate Secrets

The InvokeAndDeactivateSecrets function deactivates secrets listed in the report and exports the results.

powershell
Copy code
InvokeAndDeactivateSecrets
Notify Secret Owners

Test-Notify-SecretOwners sends notification emails to the owners of the secrets being deactivated.

powershell
Copy code
Test-Notify-SecretOwners
Send Secure Mail

The Send-SecureMail function is used internally by the script to send emails. It can also be used standalone for testing email functionality.

powershell
Copy code
Send-SecureMail -To "recipient@example.com" -From $Global:FromAddress -Subject "Test Email" -Body "This is a test email." -SmtpServer $Global:SmtpServer
Notes
Ensure all global variables are set correctly before running the script.
The script relies on the Thycotic.SecretServer PowerShell module; ensure it's installed and accessible.
Test the script in a controlled environment before using it in production.
Contributing
Contributions to this script are welcome. Please fork the repository and submit a pull request with your changes.

License
This script is provided "as is", without warranty of any kind. Use it at your own risk.

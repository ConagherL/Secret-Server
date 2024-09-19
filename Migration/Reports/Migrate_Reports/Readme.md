# Secret Server Report Migration Script

## Overview

This PowerShell script automates the migration of reports from a source Secret Server tenant to a destination tenant. It handles the migration of report categories and reports, ensuring that no duplicates are created in the destination tenant. The script includes robust logging and error handling to facilitate a smooth migration process.

## Features

- **Authentication**: Securely authenticates with both the source and destination tenants using OAuth2.
- **Category Migration**: Migrates report categories, creating any that do not exist in the destination tenant.
- **Report Migration**: Migrates reports, mapping them to the appropriate categories in the destination tenant.
- **Selective Processing**: Allows the user to select specific categories and reports to migrate or choose to migrate all.
- **Logging**: Logs all actions and errors to a log file for easy troubleshooting.
- **Error Handling**: Captures and logs errors, including API responses, to assist with debugging.

## Prerequisites

- **PowerShell**: Ensure you are running PowerShell 5.1 or later.
- **Network Access**: The script must be able to reach the source and destination Secret Server tenants over the network.
- **Credentials**: User accounts with appropriate permissions to read reports from the source tenant and create reports in the destination tenant.

# Introduction

This script will migrate any and all dependencies and dependency groups between two instances of Secret Server. The script supports accessing secrets with Check-out and Comment enabled.

# Pre-Requisites

It will create NOT create:

1. Custom Dependency Changers
1. Migrate the scripts automatically
1. SS version 10.9.33 or above is required on the source to automatically map the sites (this endpoint doesn't exist before this version)

> The above items must either be done manually or by leveraging the SS Migration Tool.

# Usage

Update the Source and Target URL's to specify the appropraite URL.

```powershell
Invoke-DependencyMigration -SourceUrl "https://secretserver.company.com/secretserver" -TargetUrl "https://company.secretservercloud.com" -Log "C:\Migration\SSDependencyMigrationLog.txt"
```

From there the script will prompt for authentication to the source and target. once folders are mapped the Jobs will start running. All logs are exported to the log location.

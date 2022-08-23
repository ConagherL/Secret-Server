# Introduction

The Physical Path Credentials (may also be referenced as Connect As) allow Websites, Virtual Directories, and Applications in IIS to use alternatives credentials to connect to drives and folders.

## Prerequisites

- PowerShell remoting enabled on these machines
- WebAdministration PowerShell Module installed on the remote machines

## Installation

1. Apply Discover ConnectAs script: **ADMIN** > **Scripts**
2. Configure Scan Template: **ADMIN** > **Discovery** > **Extensible Discovery** > **Configure Scan Templates** > **Dependencies** > **Create New Scan Template**

3. Configure Discovery Scanner:

    - **ADMIN** > **Discovery** > **Extensible Discovery** > **Configure Discovery Scanners** >
    - **Dependencies** > **Create New Scanner**
    - **Input Template**: Windows Computer
    - **Output Template**: Select scan template from step 2
    - **Script**: Select  script from step 1
    - **Arguments**: `$target`

4. Adding the Scanner

    - **ADMIN** > **Discovery** > **Edit Discovery Sources** and select your source
    - Click on **Scanner Settings** Tab
    - Scroll down to **Find Dependencies** > **Add New Dependency Scanner**
    - Select **ConnectAs** from the scanner list

5. Run Discovery

    - The new scanner will find the Dependencies
    - You will not be able to import without a [IIS Physical Path Dependency Changer](../../remote-password-changers/iis-physical-path-dependency/index.md)
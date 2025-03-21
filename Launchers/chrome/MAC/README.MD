# Secret Server Chrome Launcher

This repository contains a script to launch Google Chrome with a SOCKS5 proxy and specific configurations.

## Script: `launch_chrome.sh`

### Description

The `launch_chrome.sh` script launches Google Chrome with a specified SOCKS5 proxy, in incognito mode, and with a custom user profile directory. It also logs the launch process.

### Usage

```bash
./launch_chrome.sh <URL> <REMOTE_PORT>
```

- `<URL>`: The target URL to open in Chrome (e.g., `https://docs.delinea.com`).
- `<REMOTE_PORT>`: The remote port to use (e.g., `443`).

### Example

```bash
./launch_chrome.sh https://docs.delinea.com 443
```

### Configuration

- **SOCKS_PROXY**: The hostname of the SOCKS5 proxy.
- **CHROME_PROFILE**: The directory for the Chrome user profile.
- **LOG_FILE**: The file where logs are stored.

### Logging

The script logs messages to a log file specified by `LOG_FILE`. It logs the start time, the target URL, and whether the Chrome launch was successful or not.

### Dependencies

- PowerShell (`pwsh`): The script uses PowerShell to launch Chrome.
- OpenSSH: Ensure that the OpenSSH proxy is installed on your system.

### Requirements

- Install PowerShell: Follow the instructions at [PowerShell Installation](https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell).
- Install OpenSSH: Follow the instructions at [OpenSSH Installation](https://docs.microsoft.com/en-us/windows-server/administration/openssh/openssh_install_firstuse).

### Notes

- Ensure that the Chrome executable path in the script matches the location of Google Chrome on your system.
- The script is designed for macOS. Adjust the Chrome executable path if you are using a different operating system.

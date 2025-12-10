# vCenter ESXi Local Account Management Scripts

This folder contains Delinea Secret Server scripts for managing ESXi local accounts through vCenter.

## Overview

These scripts enable automated password management for ESXi local accounts using vCenter as a proxy. All operations are performed through vCenter using VMware PowerCLI, eliminating the need for direct ESXi host access for RPC operations. Heartbeats however can only work when calling the host directly. Lockdown mode may/may not be a issue and needs to be taken into consideration with the code.

---

## Scripts

### 1. Heartbeat Script: `vCenter_HB_v1.ps1`

**Purpose**: Validates that ESXi local account credentials are still valid.

**How it works**:

1. Connects to vCenter using a privileged service account
2. Locates the target ESXi host in vCenter
3. Temporarily disables Lockdown Mode on the ESXi host
4. Attempts a direct login to the ESXi host using the stored credentials
5. Re-enables Lockdown Mode
6. Reports success or failure

**Secret Server Arguments**:

```powershell
$HOST $USERNAME $PASSWORD $VCENTER $[1]DOMAIN $[1]USERNAME $[1]PASSWORD
```

**Required Arguments** (in order):

| Position | Parameter | Description | Example |
|----------|-----------|-------------|---------|
| 0 | `$MACHINE` | ESXi hostname or IP address | `esxi01.domain.com` |
| 1 | `$USERNAME` | ESXi local account username | `root` |
| 2 | `$PASSWORD` | Current ESXi account password | `CurrentP@ssw0rd` |
| 3 | `$VCENTER` | vCenter server hostname or IP | `vcenter.domain.com` |
| 4 | `$PRIV_DOMAIN` | Domain for vCenter service account (optional) | `DOMAIN` |
| 5 | `$PRIV_USERNAME` | vCenter service account username | `svc_vcenter` |
| 6 | `$PRIV_PASSWORD` | vCenter service account password | `VcenterP@ss` |

**Logging**:

- Hardcoded enabled in script (`LOG_ENABLED = 'true'`)
- Default log path: `C:\Logs\vcenter_{hostname}hb.log`
- Logs all operations with timestamps

**Prerequisites**:

- VMware PowerCLI module installed
- vCenter service account with permissions to:
  - Locate ESXi hosts
  - Enable/disable Lockdown Mode
- Network connectivity to vCenter
- TLS 1.2 enabled

**Exit Behavior**:

- Exits with code 0 on success
- Throws exception on failure
- Always attempts to re-enable Lockdown Mode before exiting

---

### 2. Remote Password Change Script: `vCenter_RPC_v2_esxicli.ps1`

**Purpose**: Changes ESXi local account passwords remotely via vCenter using ESXCLI.

**How it works**:

1. Connects to vCenter using a privileged service account
2. Locates the target ESXi host in vCenter
3. Initializes ESXCLI context via vCenter (no direct ESXi access required)
4. Validates the target account exists on the ESXi host
5. Updates the account password using `esxcli.system.account.set`
6. Logs all operations

**Secret Server Arguments**:

```powershell
$HOST $USERNAME $NEWPASSWORD $VCENTER $[1]DOMAIN $[1]USERNAME $[1]PASSWORD
```

**Required Arguments** (in order):

| Position | Parameter | Description | Example |
|----------|-----------|-------------|---------|
| 0 | `$MACHINE` | ESXi hostname or IP address (FQDN preferred) | `esxi01.domain.com` |
| 1 | `$USERNAME` | ESXi local account username | `root` |
| 2 | `$NEWPASSWORD` | New password for the ESXi account | `NewP@ssw0rd123` |
| 3 | `$VCENTER` | vCenter server hostname or IP | `vcenter.domain.com` |
| 4 | `$PRIV_DOMAIN` | Domain for vCenter service account | `DOMAIN` |
| 5 | `$PRIV_USERNAME` | vCenter service account username | `svc_vcenter` |
| 6 | `$PRIV_PASSWORD` | vCenter service account password | `VcenterP@ss` |

**Logging**:

- Hardcoded enabled in script (`LOG_ENABLED = 'true'`)
- Default log path: `C:\Logs\vcenter_{hostname}_rpc.log`
- Comprehensive logging of all operations and errors

**Prerequisites**:

- VMware PowerCLI module installed
- vCenter service account with permissions to:
  - Access ESXi hosts via Get-EsxCli
  - Manage local accounts on target ESXi hosts
- Network connectivity to vCenter
- TLS 1.2 enabled

**Key Features**:

- Uses ESXCLI v2 API for password changes
- No direct ESXi host access required
- Works with ESXi hosts in Lockdown Mode
- Validates account existence before attempting password change
- Preserves existing account description during password update
- Comprehensive error logging with full exception details

**Exit Behavior**:

- Exits with code 0 on success
- Throws exception on failure
- Always disconnects from vCenter before exiting

---

## Configuration in Delinea Secret Server

### Secret Template Setup

**IMPORTANT**: The out-of-the-box ESXi template requires a custom field to be added.

1. Navigate to **Admin** > **Secret Templates**
2. Edit the ESXi template (or create a new one based on it)
3. Add a new text field with the name: **vCenter Address** The SLUG field must be 'VCENTER'
4. This field is **required** and must contain the vCenter server hostname or IP address
5. Priv Account used must be a associated secret

### Heartbeat Configuration

1. Navigate to **Admin** > **Remote Password Changing** > **Configure Password Changers**
2. Select or create a Password Changer for vCenter ESXi accounts
3. Set the **Heartbeat** script to `vCenter_HB_v1.ps1`
4. Map the parameters in order:
   - Machine: `$MACHINE`
   - Username: `$USERNAME`
   - Password: `$PASSWORD`
   - vCenter Address: `$VCENTER` (from custom field)
   - Additional parameters from privileged account or custom fields

### Password Changer Configuration

1. Navigate to **Admin** > **Remote Password Changing** > **Configure Password Changers**
2. Select or create a Password Changer for vCenter ESXi accounts
3. Set the **Password Change** script to `vCenter_RPC_v2_esxicli.ps1`
4. Map the parameters in order:
   - Machine: `$MACHINE`
   - Username: `$USERNAME`
   - New Password: `$NEWPASSWORD`
   - vCenter Address: `$VCENTER` (from custom field)
   - Additional parameters from privileged account or custom fields

### Privileged Account Setup

**ASSUMPTION**: These scripts are designed to use an **Active Directory (AD) based service account** for vCenter authentication.

Create a Secret in Secret Server containing:

- **Domain**: Active Directory domain for the vCenter service account
- **Domain**: Active Directory domain for the vCenter service account
- **Username**: AD service account username (without domain prefix)
- **Password**: AD service account password

This privileged account will be used by both HB and RPC scripts to authenticate to vCenter.

---

## Security Considerations

### Permissions Required

The vCenter service account must have the following permissions on target ESXi hosts:

**For Heartbeat**:

- `Host.Config.Settings` (to manage Lockdown Mode)
- Read access to host objects

**For RPC**:

- `Host.Config.Settings` (to access ESXCLI)
- `Host.Local.ManageUserGroups` (to modify local accounts)

### Best Practices

1. **Least Privilege**: Grant vCenter service account only the minimum required permissions
2. **Dedicated Account**: Use a dedicated service account for Secret Server RPC operations
3. **Secure Storage**: Store vCenter service account credentials in Secret Server
4. **Audit Logging**: Enable logging on both scripts to track all password operations
5. **Network Security**: Ensure encrypted communication between Secret Server and vCenter
6. **Lockdown Mode**: Heartbeat script properly manages Lockdown Mode state

---

## Troubleshooting

**Issue**: "Failed to connect to vCenter"

- Verify vCenter hostname/IP is correct
- Check network connectivity from Secret Server to vCenter
- Ensure TLS 1.2 is enabled

**Issue**: "Host not found in vCenter"

- Verify ESXi hostname matches exactly as shown in vCenter
- Ensure ESXi host is managed by the specified vCenter

**Issue**: "Failed to disable Lockdown Mode" (Heartbeat)

- Verify service account has `Host.Config.Settings` permission
- Review vCenter events for additional details

**Issue**: "Failed to initialize ESXCLI" (RPC)

- Verify service account has `Host.Config.Settings` permission
- Check vCenter service status

**Issue**: "Local account does not exist" (RPC)

- Verify the username is correct (case-sensitive)
- Check for typos in the username

**Issue**: "Password update did not complete successfully" (RPC)

- Verify password meets ESXi password complexity requirements
**Issue**: "Local account does not exist" (RPC)
- Verify the username is correct (case-sensitive)
- Ensure the account exists on the ESXi host
- Check for typos in the username
Both scripts create detailed logs at:

- Heartbeat: `C:\Logs\vcenter_{hostname}hb.log`
- RPC: `C:\Logs\vcenter_{hostname}_rpc.log`
Log entries include:

- Timestamps for all operations
- Connection attempts and results

### Log File Analysis

Both scripts create detailed logs at:

- Heartbeat: `C:\Logs\vcenter_{hostname}hb.log`
- RPC: `C:\Logs\vcenter_{hostname}_rpc.log`

---

## Version History

### vCenter_HB.ps1

- Initial release
- Lockdown Mode management
- Direct ESXi login validation
For issues or questions:

1. Review log files for detailed error messages
2. Verify all prerequisites are met

- No direct ESXi access required
- Improved error handling and logging
- Account existence validation
- Preserves account description

---

## Support

For issues or questions:

1. Review log files for detailed error messages
2. Verify all prerequisites are met
3. Check vCenter events for additional context
4. Ensure service account permissions are correct

---

## Related Documentation

- [VMware PowerCLI Documentation](https://developer.vmware.com/powercli)
- [Delinea Secret Server RPC Documentation](https://docs.delinea.com/online-help/secret-server/remote-password-changing/index.htm)
- [ESXi ESXCLI Reference](https://developer.vmware.com/docs/11743/)

# 📂 Red Hat Directory Server (RHDS) PowerShell Scripts

This repository contains three PowerShell scripts to assist with managing Red Hat Directory Server (RHDS):

1. **🩺 RHDS_Heartbeat_Validation.ps1**: Validates the responsiveness and authentication capabilities of the RHDS server.
2. **🔑 ChangeRHDSUserPassword.ps1**: Changes a user's password without prompting for a password change on the next login.
3. **🔍 HB-Red Hat_CheckIfUserIsPresent.s1.ps1**: Checks if a specified user account exists and attempts to authenticate the user.

## 📋 Prerequisites

- **💻 PowerShell**: Ensure you have PowerShell installed on your system.
- **🛠️ .NET Framework**: The scripts require the `System.DirectoryServices.Protocols` assembly, which is included in the .NET Framework.

## 🩺 1. RHDS_Heartbeat_Validation.ps1

**Purpose**: This script attempts to authenticate a user against the RHDS to ensure the server is responsive and the credentials are valid.

### ⚙️ Usage

```powershell
./RHDS_Heartbeat_Validation.ps1 "<LDAP Host>" "<User DN>" "<User Password>"
```

**Example**:

```powershell
./RHDS_Heartbeat_Validation.ps1 "ldap.example.com" "uid=user1,ou=people,dc=example,dc=com" "UserPassword123!"
```

### 🔧 Configuration Variables

- `$ldapport`: Set to 636 by default for LDAPS. Change if necessary (e.g., 389 for LDAP).
- `$useSSL`: Set to `$true` by default for a secure connection. Change to `$false` if not using SSL.

## 🔑 2. ChangeRHDSUserPassword.ps1

**Purpose**: This script changes the password of an LDAP user account in RHDS without prompting for a password change on the next login.

### ⚙️ Usage

```powershell
./ChangeRHDSUserPassword.ps1 "<LDAP Host>" "<Admin DN>" "<Admin Password>" "<User DN>" "<New Password>"
```

**Example**:

```powershell
./ChangeRHDSUserPassword.ps1 "ldap.example.com" "cn=Directory Manager" "admin123" "uid=user1,ou=people,dc=example,dc=com" "NewPassword123!"
```

### 🔧 Configuration Variables

- `$ldapport`: Set to 636 by default for LDAPS. Change if necessary.
- `$useSSL`: Set to `$true` by default for a secure connection. Change to `$false` if not using SSL.

## 🔍 3. HB-Red Hat_CheckIfUserIsPresent.s1.ps1

**Purpose**: This script connects to the RHDS LDAP server, checks if a specified user account exists, and if it does, attempts to authenticate the user to ensure the server is responsive and the credentials are valid.

### ⚙️ Usage

```powershell
./HB-RedHat.ps1 "<LDAP Host>" "<Admin DN>" "<Admin Password>" "<User DN>" "<User Password>"
```

**Example**:

```powershell
./HB-RedHat.ps1 "ldap.example.com" "cn=Directory Manager" "admin123" "uid=user1,ou=people,dc=example,dc=com" "UserPassword123!"
```

### 🔧 Configuration Variables

- `$ldapport`: Set to 636 by default for LDAPS. Change if necessary (e.g., 389 for LDAP).
- `$useSSL`: Set to `$true` by default for a secure connection. Change to `$false` if not using SSL.

## 📝 Notes

- Both scripts load the `System.DirectoryServices.Protocols` assembly. Ensure that the .NET Framework is installed on your system.
- Modify the configuration variables at the top of each script as needed to match your environment.
- Ensure that the user credentials and distinguished names (DNs) provided are accurate to avoid authentication errors.
- Secret template must contain a field called "AccountDN" which has a full DN value of the user account.

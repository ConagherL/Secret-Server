# 🌟 PowerShell SDK for Secret Server


## 📌 Important Notes

1. **Account Initialization**: Always use the same account used to initialize the SDK when running commands or scripts.
2. **Account Consistency**: Do not initialize multiple SDK accounts in the same directory, as it invalidates existing configurations.

---

## 🚀 Getting Started

### ✅ Recommended Folder Structure

```plaintext
E:\SDK\
│
├── SDK (SDK executable, e.g., tss.exe)
│
└── SDK_Profiles\
    ├── ACCOUNTNAME\
    │   ├── Config\
    │   │   └── tss-sdk.json
    │   ├── Keys\
    │   └── Logs\
    │       └── sdk.log
    │
    └── AnotherAccount\
        ├── Config\
        │   └── tss-sdk.json
        ├── Keys\
        └── Logs\
            └── sdk.log
```

---

### ⚙️ SDK Initialization

Each SDK initialization should have its own distinct directory for configuration and keys:

```bash
tss.exe init --url "https://YOURURL.secretservercloud.com" \
             --rule-name "SS_SDK" \
             --onboarding-key "KEYVALUEFROMSS" \
             --config-directory "E:\SDK\SDK_Profiles\ACCOUNTNAME\Config" \
             --key-directory "E:\SDK\SDK_Profiles\ACCOUNTNAME\Keys"
```

- `--url`: URL of your Secret Server instance.
- `--rule-name`: Permissions rule associated with the SDK.
- `--onboarding-key`: Provided by Secret Server for initial setup.
- `--config-directory`: Path to store SDK configurations.
- `--key-directory`: Path to securely store the encryption key.

---

## 📁 Configuration File vs. 🔑 Encryption Key

### 📄 Configuration File
- **Purpose**: Stores connection details and SDK configurations.
- **Contains**: URL, SDK Rule Name, SDK settings.
- **Frequency**: Regularly accessed.

### 🔒 Encryption Key
- **Purpose**: Encrypts sensitive data (tokens, cached credentials).
- **Usage**: During initialization or migration.
- **Security**: Store securely, separate from config.

---

## 💻 Example SDK Usage (PowerShell)

```powershell
$configPath = 'E:\SDK\SDK_Profiles\ACCOUNTNAME\Config'
$logPath = 'E:\SDK\SDK_Profiles\ACCOUNTNAME\Logs\sdk.log'

# Retrieve SDK token
$token = (tss token -cd $configPath).Trim()

# Validate token retrieval
if ([string]::IsNullOrEmpty($token)) {
    Add-Content -Path $logPath -Value "$(Get-Date): Failed to retrieve SDK token."
    throw "SDK token retrieval failed."
} else {
    Add-Content -Path $logPath -Value "$(Get-Date): SDK token retrieved successfully."
}

# Execute SDK command
& tss secret --id 12345 --config "$configPath\tss-sdk.json"
```

---

## 📌 When to Reuse the Key
- Initial SDK setup
- SDK configuration reinitialization or migration

---

## 🚨 Best Practices
- Organize configurations clearly by account.
- Securely store encryption keys separately from config files.
- Validate and log critical SDK interactions.
- Avoid unnecessary exposure of encryption keys.

Following these best practices ensures secure, efficient, and manageable use of the PowerShell SDK for Secret Server.

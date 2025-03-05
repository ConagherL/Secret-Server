# 🌟 PowerShell SDK for Secret Server

Welcome to the **PowerShell SDK for Secret Server**. This SDK allows you to interact with Secret Server using PowerShell scripts.

## 📌 Important Notes

1. **Account Initialization**: You must open Command Prompt, PowerShell, or any other terminal using the same account that was used to initialize the SDK. This is very important.
2. **Account Consistency**: You cannot initialize different accounts in the same directory. Doing so will nullify the existing connection.

## 🚀 Getting Started

### SDK Initialization

It's important that each initialization has its own directory for config and key.

```sh
tss.exe init --url "https://YOURURL.secretservercloud.com" --rule-name "RSG_SDK" --onboarding-key "KEYVALUEFROMSS" --config-directory "E:\SDK\SDK_Profiles\ACCOUNTNAME\Config" --key-directory "E:\SDK\SDK_Profiles\ACCOUNTNAME\Keys"
```

## 📖 Usage

// ...existing code...

## 🤝 Contributing

// ...existing code...

## 📜 License

// ...existing code...

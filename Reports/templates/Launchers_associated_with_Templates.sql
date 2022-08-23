SELECT SecretTypeName AS TemplateName,
       tbLauncherType.Name AS LauncherName,
       tbLauncherType.Application AS LauncherApplication
FROM tbSecretType
LEFT JOIN tbSecretTypeLauncher ON tbSecretType.SecretTypeID = tbSecretTypeLauncher.SecretTypeId
LEFT JOIN tbLauncherType ON tbSecretTypeLauncher.LauncherTypeId = tbLauncherType.LauncherTypeId
       AND tbLauncherType.Active = 1

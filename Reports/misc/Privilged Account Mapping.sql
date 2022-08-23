SELECT [s].[SecretID]
	  ,[SecretName]
	  ,[folderpath]
	  ,[SecretTypeName]
      ,[TakeOverAccountSecretId] AS [Priviliged Account ID]
	  ,(SELECT [secretname] FROM tbsecret WHERE secretid = [TakeOverAccountSecretId]) AS [Priviliged Account Name]
	  ,(SELECT totype.secrettypename FROM [tbsecret] tosecret JOIN [tbsecrettype] totype ON toSecret.SecretTypeID = totype.SecretTypeID WHERE secretid = [takeoveraccountsecretid]) AS [Priviliged Account Type]
	  ,(SELECT tofolder.folderpath FROM [tbsecret] tosecret JOIN [tbfolder] tofolder ON toSecret.folderid = tofolder.Folderid WHERE secretid = [takeoveraccountsecretid]) AS [Priviliged Account path]
      ,[Order]
	  ,[AssociatedSecretType]
  FROM [tbSecretTakeOverAccountSecretMap]  acctmap
  JOIN tbSecret  s ON s.secretid = acctmap.secretid
  JOIN tbSecretType st ON st.secrettypeid = s.secrettypeid
  JOIN [tbSecretTakeOverAccountSettings] Settings ON  s.secretid = settings.SecretId
  JOIN tbfolder f ON s.folderid = f.folderid
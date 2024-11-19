SELECT f.FolderPath,s.SecretName,s.SecretID,[Enabled] as "OTP Enabled"
  FROM [tbSecretOneTimePasswordSettings] as otp
  join tbSecret as s on otp.secretid = s.SecretID
  join tbFolder as f on s.folderid = f.folderid
  where s.Active = 1
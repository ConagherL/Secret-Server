SELECT F.FolderPath, S.SecretName, SI.ItemValue AS UserName 
FROM tbSecret S
INNER JOIN tbFolder F
ON F.FolderID = S.FolderId
INNER JOIN tbSecretItem SI
ON SI.SecretID = S.SecretID
WHERE SI.IsEncrypted = 'False'
Order By FolderPath, SecretName, UserName
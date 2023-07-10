SELECT
  s.SecretName AS [Secret Name],
  s.SecretID,
  COUNT(DISTINCT sd.SecretDependencyId) AS [Dependency Count],
  ISNULL(fp.FolderPath, 'No folder assigned') AS [Folder Path]
FROM
  tbSecret s
  LEFT JOIN tbSecretDependency sd ON sd.SecretId = s.SecretId
  INNER JOIN tbSecretDependency ss ON ss.SecretID = s.SecretID
  LEFT JOIN vFolderPath fp WITH (NOLOCK) ON s.FolderId = fp.FolderId
  LEFT JOIN tbFolder f WITH (NOLOCK) ON s.FolderId = f.FolderId
WHERE
  ss.Active = 1
GROUP BY
  s.SecretName,
  s.SecretID,
  fp.FolderPath

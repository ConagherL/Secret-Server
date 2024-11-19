SELECT DISTINCT
s.SecretName AS 'Secret Name'
,u.UserName AS 'Member Name'
,st.SecretTypeName AS 'Secret Type'
,CAST(ls.[SessionGuid] AS VARCHAR(40)) as SessionGuid
,ss.MachineName AS 'Machine Name'
,ls.[StartDate]
,ls.[Duration] AS 'Duration (Seconds)'
,ISNULL(fp.FolderPath,'_No folder_') AS 'Folder Path'

FROM tbLauncherSession ls
INNER JOIN tbSecretSession ss ON ls.SessionGuid = ss.LauncherSessionGuid
INNER JOIN tbSecret s on ss.SecretId = s.SecretID
INNER JOIN tbAuditSecret a ON s.SecretID = a.SecretId
JOIN tbUser u WITH (NOLOCK) ON ss.UserId = u.UserID
INNER JOIN tbSecretType st on s.SecretTypeID = st.SecretTypeID
LEFT JOIN tbFolder f on s.FolderID = f.FolderID
LEFT JOIN vFolderPath fp ON f.FolderId = fp.FolderId
WHERE
ls.StartDate >= DATEADD(day, -7, GETUTCDATE())
AND
a.Action = 'Launch'
AND
ss.LaunchedSuccessfully = 1
AND
ls.[Duration] <> 0
ORDER BY ls.[StartDate] DESC
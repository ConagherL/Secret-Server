SELECT a.DateRecorded, a.Action, a.Notes, f.FolderName, s.SecretName, a.SecretId, u.UserName
FROM tbAuditSecret a WITH (NOLOCK)
INNER JOIN tbuser u WITH (NOLOCK)
ON u.UserId = a.UserId
INNER JOIN tbSecret s WITH (NOLOCK)
ON s.SecretID = a.SecretId
INNER JOIN tbFolder f WITH (NOLOCK)
ON f.FolderID = s.FolderId
WHERE Action Like '%Checked%'
ORDER BY a.DateRecorded ASC

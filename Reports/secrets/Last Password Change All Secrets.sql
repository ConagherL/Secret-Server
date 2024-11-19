SELECT  MAX(a.DateRecorded) AS 'Last Password Change Date'
, a.Action as 'Action'
,a.SecretId,
s.SecretName AS 'Secret Name'
,u.UserName AS 'UName'
,f.FolderPath AS 'Folder Path'

FROM tbAuditSecret a
JOIN tbSecret s ON s.SecretID = a.SecretId
JOIN tbFolder f ON f.FolderID = s.FolderId
JOIN tbUser u ON u.UserId = a.UserId

WHERE a.Action = 'CHANGE PASSWORD'
GROUP BY a.DateRecorded,a.SecretId, a.Action, s.SecretName, u.UserName, f.FolderPath, a.Notes
ORDER by a.DateRecorded DESC
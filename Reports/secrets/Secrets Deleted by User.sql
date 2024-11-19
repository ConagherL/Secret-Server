 
SELECT f.FolderPath,S.SecretName, u.Username,S.Created, a.Action
from tbSecret s
INNER JOIN tbAuditSecret a
on a.SecretId = s.SecretID
inner JOIN tbUser u
on u.UserId = a.UserId
INNER JOIN tbFolder f
ON f.FolderID = s.FolderId
WHERE a.Action LIKE '%DELETE%'
ORDER BY f.FolderPath,s.SecretName,u.UserName, s.Created ASC

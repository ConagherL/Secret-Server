SELECT F.FolderPath,S.SecretName, S.Created
from tbSecret S
INNER JOIN tbFolder F
ON F.FolderID = S.FolderId
ORDER BY F.FolderPath, S.Created DESC


SELECT f.FolderName, DATEPART(week, s.Created) AS 'Week', DATEPART(year, s.Created) AS 'Year', COUNT (s.SecretName) AS 'Total Secrets'
from tbSecret s
INNER JOIN tbFolder f
ON f.FolderID = s.FolderId
GROUP BY f.FolderName,  DATEPART(week, s.Created),  DATEPART(year, s.Created)
Order by FolderName, DATEPART(week, s.Created),  DATEPART(year, s.Created) ASC
